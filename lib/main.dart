/*
Before running the app, make sure to adjust the YOUR_OPENAI_API_KEY and YOUR_GOOGLE_MAPS_API_KEY
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';


Future<String> sendImageToGPT4({
  required String visualQuery,  // The text prompt/question to send along with the image
  File? image,                 // Local image file to be processed
  String? imageUrl,            // URL of an image if not using local file
}) async {
  // API key configuration for OpenAI
  // UNCOMMENT ONCE DEBUGGED 
  // final String apiKey = dotenv.env['OPENAI_API_KEY']!; 
  // DELETE LINE BELOW ONCE DEBUGGED
  const String apiKey = 'YOUR_OPENAI_API_KEY'; // Use your actual API key
  final Dio dio = Dio();      // Initialize Dio for HTTP requests

  try {
    String content;           // Will store either base64 image data or image URL

    if (image != null) {
      // If local image file is provided, compress it to reduce size
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        quality: 90,          // Compress to 90% quality to maintain good balance
      );

      if (compressedImage == null) {
        return 'Error: Failed to compress image';
      }

      // Convert the compressed image to base64 format for API transmission
      final String base64Image = base64Encode(compressedImage);
      content = "data:image/jpeg;base64,$base64Image";  // Prepare base64 image with proper data URI format
    } else if (imageUrl != null) {
      content = imageUrl;     // Use provided image URL directly
    } else {
      return 'Error: No image provided';  // Neither image file nor URL provided
    }

    // Prepare the request body for GPT-4 Vision API
    final Map<String, dynamic> payload = {
      "model": "gpt-4-turbo",  // Specify the GPT-4 vision model
      "messages": [
        {
          "role": "user",      // Message role is user for the request
          "content": [
            {"type": "text", "text": visualQuery},              // Include the text prompt
            {"type": "image_url", "image_url": {"url": content}} // Include the image data
          ]
        }
      ],
      "max_tokens": 1000,      // Limit response length to 1000 tokens
    };

    // Make the API request with retry mechanism
    return await handleRequestWithExponentialBackoff(() async {
      final response = await dio.post(
        "https://api.openai.com/v1/chat/completions",  // OpenAI chat completions endpoint
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',          // Add API key to headers
            'Content-Type': 'application/json',         // Specify JSON content type
          },
          validateStatus: (status) {
            return status! < 500; // Accept any status code below 500 to handle API errors
          },
        ),
        data: jsonEncode(payload),  // Convert payload to JSON string
      );

      // Process the API response
      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString();  // Extract the GPT response text
      } else {
        return 'Error: ${response.data}';  // Return error message if request failed
      }
    });
  } on DioError catch (error) {
    // Handle Dio-specific errors (network issues, timeouts, etc.)
    return 'DioError: ${error.response?.data ?? error.message}';
  }
}

// Handles API requests with exponential backoff retry mechanism for rate limiting
Future<String> handleRequestWithExponentialBackoff(Function requestFunction) async {
  int retryCount = 0;        // Tracks number of retry attempts
  int maxRetries = 5;        // Maximum number of retries before giving up
  int waitTime = 2;          // Initial wait time in seconds between retries

  while (retryCount < maxRetries) {
    try {
      final result = await requestFunction();
      return result;         // Return immediately if request succeeds
    } on DioError catch (e) {
      if (e.response?.statusCode == 429) {  // 429 indicates "Too Many Requests"
        retryCount++;
        await Future.delayed(Duration(seconds: waitTime));  // Wait before retrying
        waitTime *= 2;       // Exponential backoff: double the wait time for next attempt
      } else {
        rethrow;            // For any other error type, propagate it up
      }
    }
  }
  throw Exception('Max retries reached');  // If all retries fail, throw final exception
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Function to open URLs
  Future<void> _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back, Jane!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logo.png', // Change to your logo path
                                  height: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text("AIDENTIFY"),
                                const Text("Shop local", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CameraScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, color: Colors.white), // Camera icon
                          SizedBox(width: 8), // Space between icon and text
                          Text('Scan item', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Favourite Stores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => _openUrl('https://www.digitec.ch'),  // Link to Digitec
                    child: Column(
                      children: [
                        Image.asset('assets/digitec.png', height: 80),  // Replace with store logo path
                        const SizedBox(height: 8),
                        const Text("Digitec", style: TextStyle(fontSize: 14)),
                        const Text("Digital", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.migros.ch'),  // Link to Migros
                    child: Column(
                      children: [
                        Image.asset('assets/migros.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Migros", style: TextStyle(fontSize: 14)),
                        const Text("Retail", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.tutti.ch'),  // Link to Tutti
                    child: Column(
                      children: [
                        Image.asset('assets/tutti.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Tutti", style: TextStyle(fontSize: 14)),
                        const Text("Re-sell", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.deindeal.ch'),  // Link to DeinDeal
                    child: Column(
                      children: [
                        Image.asset('assets/deindeal.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("DeinDeal", style: TextStyle(fontSize: 14)),
                        const Text("Shopping", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Saved Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => _openUrl('https://www.example.com/lens_liquid'),  // Example link
                    child: Column(
                      children: [
                        Image.asset('assets/lens_liquid.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Lens Liquid", style: TextStyle(fontSize: 14)),
                        const Text("AO SEPT", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.example.com/sun_cream'),  // Example link
                    child: Column(
                      children: [
                        Image.asset('assets/sun_cream.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Sun Cream", style: TextStyle(fontSize: 14)),
                        const Text("Avène", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.example.com/polaroid_film'),  // Example link
                    child: Column(
                      children: [
                        Image.asset('assets/polaroid_film.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Polaroid Film", style: TextStyle(fontSize: 14)),
                        const Text("Fujifilm", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUrl('https://www.example.com/eyeliner'),  // Example link
                    child: Column(
                      children: [
                        Image.asset('assets/eyeliner.png', height: 80),
                        const SizedBox(height: 8),
                        const Text("Eyeliner", style: TextStyle(fontSize: 14)),
                        const Text("Dior", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        children: [
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
              BottomNavigationBarItem(icon: Icon(null), label: ''), // Empty item for center space
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stores'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
            ],
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            selectedFontSize: 12, // Set the same font size
            unselectedFontSize: 12, // Set the same font size
            type: BottomNavigationBarType.fixed, // Prevents shifting
            onTap: (index) {
              // Handle navigation based on index
              // Add any navigation logic if needed
            },
          ),
          Positioned(
            bottom: 40, // Adjust to center the button on the navigation bar
            child: FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                );
              },
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

// Screen widget that provides three options for image input: camera, gallery, or URL
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();  // Utility for handling image selection

  // Handles capturing a new photo using the device camera
  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            imagePath: pickedFile.path),
        ),
      );
    }
  }

  // Handles selecting an existing image from the device gallery
  Future<void> _chooseFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            imagePath: pickedFile.path),
        ),
      );
    }
  }

  // Displays a dialog for entering an image URL and handles the URL input
  Future<void> _enterImageUrl() async {
    String? imageUrl = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController urlController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Image URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'Enter URL here'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(urlController.text);
              },
            ),
          ],
        );
      },
    );

    // Navigate to results page if a valid URL was entered
    if (imageUrl != null && imageUrl.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(imageUrl: imageUrl),
        ),
      );
    }
  }

  // Builds the UI with three buttons for different image input methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera or Gallery or URL'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _takePicture,
              child: const Text('Take Picture'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _chooseFromGallery,
              child: const Text('Choose from Gallery'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enterImageUrl,
              child: const Text('Enter Image URL'),
            ),
          ],
        ),
      ),
    );
  }
}

// Page that displays search results on a Google Map based on an image input (either from path or URL)
class SearchResultsPage extends StatefulWidget {
  final String? imagePath;    // Path to local image file
  final String? imageUrl;     // URL of remote image

  const SearchResultsPage({Key? key, this.imagePath, this.imageUrl}) : super(key: key);

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  Completer<GoogleMapController> _controller = Completer();
  
  // Test coordinates for different global locations
  //Asian Setting - Shanghai - Scarf: 31.235860, 121.485350 -> a lot of H&M
  //DONE - Asian Setting - Beijin - Scarf: 39.945244, 116.476588
  //DONE - Europe Setting - Zurich - Sneakers: 47.3770105, 8.5394363
  //DONE - Aftica Setting - Zimbabwe - -17.839588, 31.043146
  //DONE - LATAM - Argentina - -45.593818, -69.066501
  //DONE - MiddleEast - Riyadh - 24.730672, 46.663398
  //Study Lab Location - Study Lab - 47.427850, 9.377355
  
  // Initial map center position
  static const LatLng _initialPosition = LatLng(47.4331217, 9.3748385); // Study lab example location
  
  // Collection of map markers for store locations
  List<Marker> _markers = [];
  
  // Google Maps API configuration
  final String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";
  
  // State variables for error handling and item details
  String? _errorMessage;
  String? _itemDetails;
  Future<String?>? _itemDetailsFuture;

  // Initialize the page state and start the search process
  @override
  void initState() {
    super.initState();
    // Add initial blue marker at starting position
    _markers.add(
      Marker(
        markerId: const MarkerId('initial_position'),
        position: _initialPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Initial Position'),
      ),
    );
    _itemDetailsFuture = _initiateSearch();
  }

  // Main search function that coordinates the item analysis and store location search
  Future<String?> _initiateSearch() async {
  try {
    final storeType = await _fetchItemDetails();
    if (storeType != null) {
      await _fetchNearbyStores(storeType);
    } else {
      setState(() {
        _errorMessage = "Error: Unable to determine store type from item details.";
      });
    }
    // Return the item details
    return _itemDetails;
  } catch (e) {
    setState(() {
      _errorMessage = "An unexpected error occurred: $e";
    });
    return null;
  }
}

  Future<String?> _fetchItemDetails() async {
    try {
      _itemDetails = await sendImageToGPT4(
        visualQuery: '''
Identify the object category from the provided image.
Additionally, determine where this object could most likely be bought from the following list of places:
- Automobil: car_dealer, car_rental, car_repair, car_wash, electric_vehicle_charging_station, gas_station, parking, rest_stop
- Unternehmen: farm
- Kultur: art_gallery, museum, performing_arts_theater
- Bildung: library, preschool, primary_school, school, secondary_school, university
- Unterhaltung und Freizeit: amusement_center, amusement_park, aquarium, banquet_hall, bowling_alley, casino, community_center, convention_center, cultural_center, dog_park, event_venue, hiking_area, historical_landmark, marina, movie_rental, movie_theater, national_park, night_club, park, tourist_attraction, visitor_center, wedding_venue, zoo
- Finanzen: accounting, atm, bank
- Essen und Trinken: american_restaurant, bakery, bar, barbecue_restaurant, brazilian_restaurant, breakfast_restaurant, brunch_restaurant, cafe, chinese_restaurant, coffee_shop, fast_food_restaurant, french_restaurant, greek_restaurant, hamburger_restaurant, ice_cream_shop, indian_restaurant, indonesian_restaurant, italian_restaurant, japanese_restaurant, korean_restaurant, lebanese_restaurant, meal_delivery, meal_takeaway, mediterranean_restaurant, mexican_restaurant, middle_eastern_restaurant, pizza_restaurant, ramen_restaurant, restaurant, sandwich_shop, seafood_restaurant, spanish_restaurant, steak_house, sushi_restaurant, thai_restaurant, turkish_restaurant, vegan_restaurant, vegetarian_restaurant, vietnamese_restaurant
- Regionen: administrative_area_level_1, administrative_area_level_2, country, locality, postal_code, school_district
- Behörden: city_hall, courthouse, embassy, fire_station, local_government_office, police, post_office
- Gesundheit und Wohlbefinden: dental_clinic, dentist, doctor, drugstore, hospital, medical_lab, pharmacy, physiotherapist, spa
- Unterkunft: bed_and_breakfast, campground, camping_cabin, cottage, extended_stay_hotel, farmstay, guest_house, hostel, hotel, lodging, motel, private_guest_room, resort_hotel, rv_park
- Religiöse Orte: church, hindu_temple, mosque, synagogue
- Dienstleister: barber_shop, beauty_salon, cemetery, child_care_agency, consultant, courier_service, electrician, florist, funeral_home, hair_care, hair_salon, insurance_agency, laundry, lawyer, locksmith, moving_company, painter, plumber, real_estate_agency, roofing_contractor, storage, tailor, telecommunications_service_provider, travel_agency, veterinary_care
- Shopping: auto_parts_store, bicycle_store, book_store, cell_phone_store, clothing_store, convenience_store, department_store, discount_store, electronics_store, furniture_store, gift_shop, grocery_store, hardware_store, home_goods_store, home_improvement_store, jewelry_store, liquor_store, market, pet_store, shoe_store, shopping_mall, sporting_goods_store, store, supermarket, wholesaler
- Sporteinrichtungen: athletic_field, fitness_center, golf_course, gym, playground, ski_resort, sports_club, sports_complex, stadium, swimming_pool
- Transportwesen: airport, bus_station, bus_stop, ferry_terminal, heliport, light_rail_station, park_and_ride, subway_station, taxi_stand, train_station, transit_depot, transit_station, truck_stop

Please provide the object category first (only object category, no sentence as answer and then ":") and then list the most likely places from the above categories where this object can be bought (just separated by a semicolon no bulletpoints).
''',
        image: widget.imagePath != null ? File(widget.imagePath!) : null,
        imageUrl: widget.imageUrl,
      );

      return _extractStoreType(_itemDetails!);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to retrieve item details: $e";
      });
      return null;
    }
  }

  String? _extractStoreType(String itemDetails) {
    final parts = itemDetails.split(':');
    return parts.length > 1 ? parts.first.trim() : null;
  }

  Future<void> _fetchNearbyStores(String type) async {
    const String baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    const double radius = 1500;

    final url = Uri.parse('$baseUrl?location=${_initialPosition.latitude},${_initialPosition.longitude}&radius=$radius&keyword=$type&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        // define for open and closed stores
        BitmapDescriptor openMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        BitmapDescriptor closedMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);


        setState(() {
          _markers = _markers.where((marker) => marker.markerId.value == 'initial_position').toList();
          _markers.addAll(results.map((place) {
            final lat = place['geometry']['location']['lat'];
            final lng = place['geometry']['location']['lng'];
            final name = place['name'];
            final address = place['vicinity'] ?? 'No address available';
            final placeId = place['place_id']; // place id to later call opening hours

            // Check if store is currently open
            bool isOpen = place['opening_hours']?['open_now'] ?? false;
            BitmapDescriptor markerIcon = isOpen ? openMarker : closedMarker;

            return Marker(
              markerId: MarkerId(place['place_id']),
              position: LatLng(lat, lng),
              icon: markerIcon,
              infoWindow: InfoWindow(title: name),
              onTap: () async {
              final openingHours = await _fetchPlaceDetails(placeId);

              // bottom sheet with store details when pin is tapped
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return _StorePageDetails(
                    storeName: name,
                    storeAddress: address,
                    openingHours: openingHours,
                    storeLocation: LatLng(lat, lng)
                  );
                },
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              );
            },
          );
        }).toList());
      });
    } else {
      setState(() {
        _errorMessage = "Failed to fetch stores: ${response.statusCode}";
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Error fetching places: $e";
    });
  }
}
//fetch opening hours
Future<List<String>> _fetchPlaceDetails(String placeId) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,opening_hours&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final openingHours = data['result']['opening_hours']['weekday_text'] as List<dynamic>?;
        if (openingHours != null) {
          return List<String>.from(openingHours);
        } else {
          return ['Opening hours not available'];
        }
      } else {
        return ['Failed to fetch details: ${response.statusCode}'];
      }
    } catch (e) {
      return ['Error fetching place details: $e'];
    }
  }

  void _retakePicture() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stores'),
      ),
      body: FutureBuilder<String?>(
        future: _itemDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || _errorMessage != null) {
            return Center(
              child: Text(
                _errorMessage ?? 'Error occurred while analyzing image.',
                style: const TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Column(
              children: [
                // Top bar with image thumbnail, item details, and retake option
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      if (widget.imagePath != null)
                        Image.file(File(widget.imagePath!), width: 50, height: 50)
                      else if (widget.imageUrl != null)
                        Image.network(widget.imageUrl!, width: 50, height: 50),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          snapshot.data!.split(':').first.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _retakePicture,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition,
                      zoom: 14,
                    ),
                    markers: Set<Marker>.of(_markers),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No details available.'));
          }
        },
      ),
    );
  }
}

// Widget that displays detailed store information in a bottom sheet or modal
class _StorePageDetails extends StatelessWidget {
  // Store information properties required for display
  final String storeName;
  final String storeAddress;
  final List<String> openingHours;
  final LatLng storeLocation; 

  const _StorePageDetails({
    required this.storeName,
    required this.storeAddress,
    required this.openingHours,
    required this.storeLocation,
  });

  // Handles navigation to the store location using either Google Maps or Apple Maps
  Future<void> _openMap() async {
    final Uri googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${storeLocation.latitude},${storeLocation.longitude}');
    final Uri appleUrl = Uri.parse('https://maps.apple.com/?daddr=${storeLocation.latitude},${storeLocation.longitude}');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else if (await canLaunchUrl(appleUrl)) {
      await launchUrl(appleUrl);
    } else {
      throw 'Could not launch map';
    }
  }

  // Builds the UI for store details with a card-like appearance
  @override
  Widget build(BuildContext context) {
    final int todayIndex = DateTime.now().weekday - 1;  // Calculate current day for highlighting

    return Container(
      padding: const EdgeInsets.all(16.0),
      // Card styling with rounded corners and shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      // Main content layout
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name section
          Text(
            storeName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Address section
          Text(storeAddress),
          const SizedBox(height: 16),
          // Opening hours section with today's hours highlighted
          Text(
            'Opening Hours:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          // opening hours with today's hours in bold
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(openingHours.length, (index) {
              return Text(
                openingHours[index],
                style: TextStyle(
                  fontWeight: index == todayIndex ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Navigation button
          Center(
            child: ElevatedButton(
              onPressed: _openMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text(
                'Get Directions',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: HomeScreen()));
}