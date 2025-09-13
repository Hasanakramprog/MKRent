import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/training_video_model.dart';
import '../models/training_history_model.dart';
import '../services/training_youtube_service.dart';
import '../services/training_history_service.dart';
import 'youtube_video_player_screen.dart';
import 'training_history_screen.dart';
import 'training_search_screen.dart';
import 'saved_playlists_screen.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({Key? key}) : super(key: key);

  @override
  _TrainingHomeScreenState createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  final TrainingYouTubeService _youtubeService = TrainingYouTubeService();
  final TrainingHistoryService _historyService = TrainingHistoryService();
  
  Future<List<TrainingVideoModel>>? _featuredVideosFuture;
  Future<List<TrainingVideoModel>>? _cameraBasicsVideosFuture;
  Future<List<TrainingVideoModel>>? _portraitVideosFuture;
  Future<List<TrainingVideoModel>>? _landscapeVideosFuture;
  Future<List<TrainingVideoModel>>? _droneVideosFuture;
  Future<List<TrainingVideoModel>>? _editingVideosFuture;
  Future<List<TrainingVideoModel>>? _lightingVideosFuture;
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTrainingContent();
  }

  Future<void> _loadTrainingContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _featuredVideosFuture = _youtubeService.fetchFeaturedVideos();
      _cameraBasicsVideosFuture = _youtubeService.fetchVideosByCategory('Camera Basics');
      _portraitVideosFuture = _youtubeService.fetchVideosByCategory('Portrait');
      _landscapeVideosFuture = _youtubeService.fetchVideosByCategory('Landscape');
      _droneVideosFuture = _youtubeService.fetchVideosByCategory('Drone');
      _editingVideosFuture = _youtubeService.fetchVideosByCategory('Editing');
      _lightingVideosFuture = _youtubeService.fetchVideosByCategory('Lighting');

      // Wait for at least the featured videos to load
      await _featuredVideosFuture;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF2196F3), size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Photography Training',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPlaylistsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingSearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // Show user profile or sign in
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _hasError
              ? _buildErrorView()
              : _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Photography Courses...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Failed to load training content',
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTrainingContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continue Learning Section
          _buildContinueLearningSection(),
          
          // Featured Courses
          _buildTrainingSection(
            'Featured Courses',
            _featuredVideosFuture!,
            icon: Icons.star,
            color: const Color(0xFFFFD700),
          ),
          
          // Camera Basics
          _buildTrainingSection(
            'Camera Basics',
            _cameraBasicsVideosFuture!,
            icon: Icons.camera_alt,
            color: const Color(0xFF4CAF50),
          ),
          
          // Portrait Photography
          _buildTrainingSection(
            'Portrait Photography',
            _portraitVideosFuture!,
            icon: Icons.person,
            color: const Color(0xFFE91E63),
          ),
          
          // Landscape Photography
          _buildTrainingSection(
            'Landscape Photography',
            _landscapeVideosFuture!,
            icon: Icons.landscape,
            color: const Color(0xFF2196F3),
          ),
          
          // Drone Photography
          _buildTrainingSection(
            'Drone Photography',
            _droneVideosFuture!,
            icon: Icons.airplanemode_active,
            color: const Color(0xFF9C27B0),
          ),
          
          // Photo Editing
          _buildTrainingSection(
            'Photo Editing',
            _editingVideosFuture!,
            icon: Icons.edit,
            color: const Color(0xFFFF9800),
          ),
          
          // Studio Lighting
          _buildTrainingSection(
            'Studio Lighting',
            _lightingVideosFuture!,
            icon: Icons.wb_incandescent,
            color: const Color(0xFFFF5722),
          ),
          
          const SizedBox(height: 100), // Bottom padding for navigation
        ],
      ),
    );
  }

  Widget _buildContinueLearningSection() {
    return FutureBuilder<TrainingHistoryItem?>(
      future: _historyService.getLastWatchedVideo(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildContinueLearningCard(snapshot.data!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContinueLearningCard(TrainingHistoryItem historyItem) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YouTubeVideoPlayerScreen(
                  videoId: historyItem.videoId,
                  title: historyItem.title,
                  category: historyItem.category,
                  difficulty: historyItem.difficulty,
                  instructor: historyItem.instructor,
                  historyService: _historyService,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail with progress overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: historyItem.thumbnailUrl,
                        width: 120,
                        height: 68,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 68,
                          color: Colors.grey[800],
                          child: const Icon(Icons.play_circle_outline, color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 68,
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: LinearProgressIndicator(
                        value: historyItem.watchProgress,
                        backgroundColor: Colors.black.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue Learning',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        historyItem.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            historyItem.difficultyIcon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              historyItem.difficulty,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${(historyItem.watchProgress * 100).toInt()}% complete',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSection(
    String title,
    Future<List<TrainingVideoModel>> videosFuture, {
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<TrainingVideoModel>>(
            future: videosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingShimmer();
              } else if (snapshot.hasError) {
                return _buildErrorRow('Failed to load $title');
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return _buildVideoRow(snapshot.data!);
              } else {
                return _buildEmptyRow('No $title courses available');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoRow(List<TrainingVideoModel> videos) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => YouTubeVideoPlayerScreen(
                      videoId: video.id,
                      title: video.title,
                      category: video.category,
                      difficulty: video.difficulty,
                      instructor: video.instructor,
                      historyService: _historyService,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          width: 160,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 160,
                            height: 90,
                            color: Colors.grey[800],
                            child: const Icon(Icons.play_circle_outline, color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 160,
                            height: 90,
                            color: Colors.grey[800],
                            child: const Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: video.difficultyColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (video.formattedDuration.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Instructor
                  Text(
                    video.instructor,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating and enrollment
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        video.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people, color: Colors.grey[400], size: 12),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _formatEnrollment(video.enrollmentCount),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 160,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorRow(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, color: Colors.grey[600], size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1A1A1A),
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            // Home - already here
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainingHistoryScreen(historyService: _historyService),
              ),
            );
            break;
          case 2:
            // Downloads - coming soon
            break;
          case 3:
            // Profile - coming soon
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.download),
          label: 'Downloads',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  String _formatEnrollment(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
