# Aidentify - Smart Shopping Assistant

## Overview
Aidentify is a Flutter application that helps users identify products and find nearby stores where they can purchase similar items. The app uses image recognition (powered by GPT-4 Vision) and location services (Google Maps) to provide a seamless shopping experience.

## Features
- **Image Input Options**:
  - Take a picture using the device camera
  - Choose an image from the gallery
  - Enter an image URL

- **Smart Recognition**:
  - Identifies products using GPT-4 Vision API
  - Categorizes items automatically
  - Provides relevant store recommendations

- **Store Locator**:
  - Shows nearby stores on Google Maps
  - Displays store status (open/closed)
  - Provides store details including:
    - Opening hours
    - Address
    - Navigation options

- **User Interface**:
  - Clean and intuitive home screen
  - Favorite stores quick access
  - Saved items history
  - Bottom navigation for easy access

## Getting Started

### Prerequisites
1. Flutter development environment
2. API Keys:
   - OpenAI API key for GPT-4 Vision
   - Google Maps API key

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/deltani/aidentify.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API keys:
   - Create a `.env` file in the root directory
   - Add your API keys:
     ```
     OPENAI_API_KEY=your_openai_api_key
     GOOGLE_API_KEY=your_google_maps_api_key
     ```
  - Add the Google Maps API key YOUR_GOOGLE_MAPS_API_KEY to the `AppDelegate.swift` file in the `ios/Runner` directory
4. Run the app:
   ```bash
   flutter run
   ```

### Configuration
- Update the initial map position in `SearchResultsPage` class if needed
- Modify the store categories in the visual query prompt as required
- Adjust the search radius (default: 1500 meters) in `_fetchNearbyStores`

## Technical Details

### Dependencies
- `google_maps_flutter`: For maps integration
- `image_picker`: For camera and gallery access
- `dio`: For HTTP requests
- `flutter_image_compress`: For image optimization
- `url_launcher`: For navigation features
- `sliding_up_panel`: For store details panel

### API Integration
- **OpenAI GPT-4 Vision**: Used for image recognition and classification
- **Google Maps Platform**:
  - Places API for store discovery
  - Maps SDK for visualization
  - Directions API for navigation


## Acknowledgments
- OpenAI for GPT-4 Vision API
- Google Maps Platform for location services
- Flutter team for the framework

