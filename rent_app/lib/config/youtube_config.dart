class YouTubeConfig {
  // Your YouTube Data API v3 Key
  static const String apiKey = 'AIzaSyBNfhadhU14IJfzDkcaV_hPvWMmPKx4FSU';
  
  // Base URL for YouTube Data API v3
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Note: This app now uses ONLY playlists from saved_playlists.json
  // No default playlists are used anymore
  
  // Search configurations
  static const int maxSearchResults = 20;
  static const int maxFeaturedResults = 10;
  static const int maxCategoryResults = 15;
  
  // Video duration filters
  static const String preferredDuration = 'medium'; // short, medium, long
}
