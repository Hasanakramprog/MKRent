import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/training_video_model.dart';
import '../models/training_playlist_model.dart';
import '../config/youtube_config.dart';
import '../services/playlist_service.dart';

class TrainingYouTubeService {
  static const String _baseUrl = YouTubeConfig.baseUrl;
  static const String _apiKey = YouTubeConfig.apiKey;

  Future<List<TrainingVideoModel>> fetchFeaturedVideos() async {
    try {
      // Reduce API calls by using smaller maxResults
      final url = '$_baseUrl/search?part=snippet&q=photography+tutorial+beginner+camera&type=video&order=relevance&maxResults=5&videoDuration=${YouTubeConfig.preferredDuration}&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<TrainingVideoModel> videos = [];
        
        for (var item in data['items']) {
          final video = await _parseVideoFromSearch(item, 'Photography', 'Beginner');
          videos.add(video);
        }
        
        return videos;
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
        if (response.body.contains('quotaExceeded')) {
          throw Exception('YouTube API quota exceeded. Please try again later.');
        }
        throw Exception('Failed to load featured videos');
      }
    } catch (e) {
      print('Error fetching featured videos: $e');
      if (e.toString().contains('quota')) {
        return _getFallbackFeaturedVideos();
      }
      return [];
    }
  }

  Future<List<TrainingVideoModel>> fetchVideosByCategory(String category) async {
    try {
      String searchQuery = _getCategorySearchQuery(category);
      // Reduce API calls by using smaller maxResults
      final url = '$_baseUrl/search?part=snippet&q=$searchQuery&type=video&order=relevance&maxResults=3&videoDuration=${YouTubeConfig.preferredDuration}&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<TrainingVideoModel> videos = [];
        
        for (var item in data['items']) {
          final video = await _parseVideoFromSearch(item, category, _getCategoryDifficulty(category));
          videos.add(video);
        }
        
        return videos;
      } else {
        print('YouTube Category API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load $category videos');
      }
    } catch (e) {
      print('Error fetching $category videos: $e');
      if (e.toString().contains('quota')) {
        return _getFallbackCategoryVideos(category);
      }
      return [];
    }
  }

  Future<List<TrainingVideoModel>> fetchVideosFromPlaylist(String playlistName) async {
    try {
      // Only use playlists from saved JSON file
      String? playlistId = await PlaylistService.getPlaylistIdByTitle(playlistName);
      
      if (playlistId == null) {
        throw Exception('Playlist not found in saved playlists: $playlistName');
      }

      final url = '$_baseUrl/playlistItems?part=snippet&playlistId=$playlistId&maxResults=50&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<TrainingVideoModel> videos = [];
        
        for (var item in data['items']) {
          final video = await _parseVideoFromPlaylist(item, playlistName);
          videos.add(video);
        }
        
        return videos;
      } else {
        throw Exception('Failed to load playlist videos');
      }
    } catch (e) {
      print('Error fetching playlist videos: $e');
      return [];
    }
  }

  Future<List<TrainingPlaylist>> fetchAvailablePlaylists() async {
    try {
      final List<TrainingPlaylist> playlists = [];
      
      // Load ONLY playlists from saved JSON file
      final savedPlaylists = await PlaylistService.loadSavedPlaylists();
      for (var savedPlaylist in savedPlaylists) {
        final url = '$_baseUrl/playlists?part=snippet,contentDetails&id=${savedPlaylist.id}&key=$_apiKey';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['items'].isNotEmpty) {
            playlists.add(_parsePlaylistInfo(data['items'][0], savedPlaylist.title));
          }
        } else {
          // If API fails, create a basic playlist object from saved data
          playlists.add(TrainingPlaylist(
            id: savedPlaylist.id,
            title: savedPlaylist.title,
            description: 'Personal saved playlist',
            thumbnailUrl: 'https://via.placeholder.com/480x360',
            videoCount: 0,
            category: 'Personal',
            difficulty: 'All Levels',
            instructor: 'Various',
            rating: 4.5,
            enrollmentCount: 100,
            tags: ['personal', 'saved'],
          ));
        }
      }
      
      return playlists.isNotEmpty ? playlists : [];
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }

  Future<List<TrainingVideoModel>> searchTrainingVideos(String query) async {
    try {
      final searchQuery = '$query+photography+tutorial';
      final url = '$_baseUrl/search?part=snippet&q=$searchQuery&type=video&order=relevance&maxResults=${YouTubeConfig.maxSearchResults}&videoDuration=${YouTubeConfig.preferredDuration}&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<TrainingVideoModel> videos = [];
        
        for (var item in data['items']) {
          final video = await _parseVideoFromSearch(item, 'Photography', 'Beginner');
          videos.add(video);
        }
        
        return videos;
      } else {
        print('YouTube Search API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search videos');
      }
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  // Method to fetch video details (statistics and duration)
  Future<Map<String, dynamic>> fetchVideoDetails(String videoId) async {
    try {
      final url = '$_baseUrl/videos?part=statistics,contentDetails&id=$videoId&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'].isNotEmpty) {
          final item = data['items'][0];
          final statistics = item['statistics'];
          final contentDetails = item['contentDetails'];
          
          return {
            'viewCount': int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
            'duration': _parseDuration(contentDetails['duration'] ?? 'PT0S'),
          };
        }
      }
    } catch (e) {
      print('Error fetching video details: $e');
    }
    
    return {
      'viewCount': 0,
      'duration': 0,
    };
  }

  // Parse YouTube duration format (PT1H2M3S) to seconds
  int _parseDuration(String duration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      
      return hours * 3600 + minutes * 60 + seconds;
    }
    
    return 0;
  }

  Future<TrainingVideoModel> _parseVideoFromSearch(Map<String, dynamic> item, String category, String difficulty) async {
    final snippet = item['snippet'];
    final videoId = item['id']['videoId'] ?? '';
    
    // Get the best available thumbnail
    String thumbnailUrl = '';
    final thumbnails = snippet['thumbnails'];
    if (thumbnails['maxresdefault'] != null) {
      thumbnailUrl = thumbnails['maxresdefault']['url'];
    } else if (thumbnails['high'] != null) {
      thumbnailUrl = thumbnails['high']['url'];
    } else if (thumbnails['medium'] != null) {
      thumbnailUrl = thumbnails['medium']['url'];
    } else if (thumbnails['default'] != null) {
      thumbnailUrl = thumbnails['default']['url'];
    }

    // Fetch video details for duration and view count
    final videoDetails = await fetchVideoDetails(videoId);
    
    return TrainingVideoModel(
      id: videoId,
      title: snippet['title'] ?? '',
      thumbnailUrl: thumbnailUrl,
      channelTitle: snippet['channelTitle'] ?? '',
      description: snippet['description'] ?? '',
      viewCount: videoDetails['viewCount'] ?? 0,
      category: category,
      difficulty: difficulty,
      durationInSeconds: videoDetails['duration'] ?? 0,
      tags: List<String>.from(snippet['tags'] ?? []),
      instructor: snippet['channelTitle'] ?? '',
      rating: 4.0 + (videoId.hashCode % 10) / 10, // Generate realistic rating between 4.0-5.0
      enrollmentCount: 500 + (videoId.hashCode % 5000), // Generate realistic enrollment
    );
  }

  Future<TrainingVideoModel> _parseVideoFromPlaylist(Map<String, dynamic> item, String playlistName) async {
    final snippet = item['snippet'];
    final videoId = snippet['resourceId']['videoId'] ?? '';
    
    // Fetch video details for duration and view count
    final videoDetails = await fetchVideoDetails(videoId);
    
    return TrainingVideoModel(
      id: videoId,
      title: snippet['title'] ?? '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      description: snippet['description'] ?? '',
      viewCount: videoDetails['viewCount'] ?? 0,
      category: _getPlaylistCategory(playlistName),
      difficulty: _getPlaylistDifficulty(playlistName),
      durationInSeconds: videoDetails['duration'] ?? 0,
      tags: [],
      instructor: snippet['channelTitle'] ?? '',
      rating: 4.5,
      enrollmentCount: 1000,
    );
  }

  TrainingPlaylist _parsePlaylistInfo(Map<String, dynamic> item, String playlistName) {
    final snippet = item['snippet'];
    final contentDetails = item['contentDetails'];
    
    return TrainingPlaylist(
      id: item['id'] ?? '',
      title: playlistName,
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
      category: _getPlaylistCategory(playlistName),
      difficulty: _getPlaylistDifficulty(playlistName),
      videoCount: contentDetails['itemCount'] ?? 0,
      instructor: snippet['channelTitle'] ?? '',
      rating: 4.5,
      enrollmentCount: 1000,
      tags: [],
    );
  }

  String _getCategorySearchQuery(String category) {
    switch (category.toLowerCase()) {
      case 'camera basics':
        return 'camera+basics+tutorial+photography+beginner';
      case 'portrait':
        return 'portrait+photography+tutorial+lighting+posing';
      case 'landscape':
        return 'landscape+photography+tutorial+composition';
      case 'drone':
        return 'drone+photography+tutorial+aerial+cinematography';
      case 'editing':
        return 'photo+editing+tutorial+lightroom+photoshop';
      case 'lighting':
        return 'photography+lighting+tutorial+studio+setup';
      case 'wedding':
        return 'wedding+photography+tutorial+tips';
      case 'street':
        return 'street+photography+tutorial+candid';
      default:
        return 'photography+tutorial+' + category.toLowerCase().replaceAll(' ', '+');
    }
  }

  String _getCategoryDifficulty(String category) {
    switch (category.toLowerCase()) {
      case 'camera basics':
        return 'Beginner';
      case 'editing':
      case 'lighting':
        return 'Intermediate';
      case 'drone':
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  String _getPlaylistCategory(String playlistName) {
    if (playlistName.toLowerCase().contains('camera')) return 'Camera';
    if (playlistName.toLowerCase().contains('portrait')) return 'Portrait';
    if (playlistName.toLowerCase().contains('landscape')) return 'Landscape';
    if (playlistName.toLowerCase().contains('drone')) return 'Drone';
    if (playlistName.toLowerCase().contains('editing')) return 'Editing';
    if (playlistName.toLowerCase().contains('lighting')) return 'Lighting';
    return 'Photography';
  }

  String _getPlaylistDifficulty(String playlistName) {
    if (playlistName.toLowerCase().contains('basic')) return 'Beginner';
    if (playlistName.toLowerCase().contains('advanced')) return 'Advanced';
    return 'Intermediate';
  }

  // Fallback methods for when quota is exceeded
  List<TrainingVideoModel> _getFallbackFeaturedVideos() {
    return [
      TrainingVideoModel(
        id: 'dQw4w9WgXcQ',
        title: 'Photography Basics for Beginners',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        channelTitle: 'Photography Channel',
        description: 'Learn the fundamentals of photography in this comprehensive tutorial.',
        viewCount: 1000000,
        category: 'Photography',
        difficulty: 'Beginner',
        durationInSeconds: 900,
        tags: ['photography', 'basics', 'tutorial'],
        instructor: 'Photography Pro',
        rating: 4.5,
        enrollmentCount: 50000,
      ),
      TrainingVideoModel(
        id: 'jNQXAC9IVRw',
        title: 'Camera Settings Explained',
        thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/maxresdefault.jpg',
        channelTitle: 'Camera Academy',
        description: 'Master your camera settings with this detailed guide.',
        viewCount: 750000,
        category: 'Camera',
        difficulty: 'Intermediate',
        durationInSeconds: 720,
        tags: ['camera', 'settings', 'tutorial'],
        instructor: 'Camera Expert',
        rating: 4.7,
        enrollmentCount: 35000,
      ),
    ];
  }

  List<TrainingVideoModel> _getFallbackCategoryVideos(String category) {
    return [
      TrainingVideoModel(
        id: 'fallback_${category.toLowerCase()}',
        title: '$category Photography Tutorial',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        channelTitle: '$category Academy',
        description: 'Learn $category photography techniques and tips.',
        viewCount: 500000,
        category: category,
        difficulty: _getCategoryDifficulty(category),
        durationInSeconds: 600,
        tags: [category.toLowerCase(), 'tutorial', 'tips'],
        instructor: '$category Pro',
        rating: 4.3,
        enrollmentCount: 25000,
      ),
    ];
  }
}
