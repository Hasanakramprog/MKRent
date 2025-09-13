import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/training_video_model.dart';
import '../services/training_history_service.dart';

class TrainingVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String category;
  final String difficulty;
  final String instructor;
  final TrainingHistoryService historyService;

  const TrainingVideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.instructor,
    required this.historyService,
  }) : super(key: key);

  @override
  _TrainingVideoPlayerScreenState createState() => _TrainingVideoPlayerScreenState();
}

class _TrainingVideoPlayerScreenState extends State<TrainingVideoPlayerScreen> {
  bool _isFullScreen = false;
  bool _isAddedToHistory = false;
  int _totalDuration = 0;
  int _currentPosition = 0;
  Timer? _progressTracker;
  DateTime? _startWatchTime;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _startWatchTime = DateTime.now();
    _checkForResumePosition();
    
    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  @override
  void dispose() {
    // Final update to watch history before disposing
    if (_isAddedToHistory && _totalDuration > 0) {
      double progress = (_currentPosition / _totalDuration) * 100;
      _updateHistoryProgress(progress: progress, isFinal: true);
    }

    _progressTracker?.cancel();
    super.dispose();
  }

  void _startControlsTimer() {
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _checkForResumePosition() async {
    try {
      final historyItem = await widget.historyService.getVideoHistory(widget.videoId);
      if (historyItem != null && historyItem.lastPositionInSeconds > 30) {
        _showResumeDialog(historyItem.lastPositionInSeconds);
      }
    } catch (e) {
      print('Error checking resume position: $e');
    }
  }

  void _showResumeDialog(int resumePosition) {
    String formattedTime = _formatDuration(Duration(seconds: resumePosition));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Resume Watching?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Would you like to resume from $formattedTime?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start from beginning
            },
            child: const Text(
              'Start Over',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPosition = resumePosition;
              });
            },
            child: const Text(
              'Resume',
              style: TextStyle(color: Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
                if (_showControls) {
                  _startControlsTimer();
                }
              },
              child: Container(
                width: double.infinity,
                height: _isFullScreen ? MediaQuery.of(context).size.height : 200,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Video thumbnail (placeholder for actual video)
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    
                    // Video Controls Overlay
                    if (_showControls)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Top controls
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isFullScreen = !_isFullScreen;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Center play button
                            Center(
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 80,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPlaying = !_isPlaying;
                                    if (!_isAddedToHistory && _isPlaying) {
                                      _addToHistory(progress: 0.0);
                                      _isAddedToHistory = true;
                                    }
                                  });
                                  if (_isPlaying) {
                                    _startControlsTimer();
                                  }
                                },
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Bottom controls
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Progress bar
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(Duration(seconds: _currentPosition)),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _totalDuration > 0 ? _currentPosition / _totalDuration : 0.0,
                                          onChanged: (value) {
                                            setState(() {
                                              _currentPosition = (value * _totalDuration).round();
                                            });
                                          },
                                          activeColor: const Color(0xFF2196F3),
                                          inactiveColor: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(Duration(seconds: _totalDuration)),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Video Info and Actions
            if (!_isFullScreen)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Title and Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(widget.difficulty),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.difficulty,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.category,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'by ${widget.instructor}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(Icons.thumb_up_outlined, 'Like'),
                            _buildActionButton(Icons.bookmark_outline, 'Save'),
                            _buildActionButton(Icons.share, 'Share'),
                            _buildActionButton(Icons.download_outlined, 'Download'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Course Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this course',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This comprehensive ${widget.category.toLowerCase()} course is designed for ${widget.difficulty.toLowerCase()} level photographers. Learn professional techniques and best practices from industry expert ${widget.instructor}.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Related Videos (placeholder)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'More from this series',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Related videos coming soon',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () {
            // Handle action
          },
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return const Color(0xFF4CAF50);
      case 'Intermediate':
        return const Color(0xFFFF9800);
      case 'Advanced':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF2196F3);
    }
  }

  Future<void> _addToHistory({required double progress}) async {
    final watchDuration = DateTime.now().difference(_startWatchTime!).inSeconds;

    // Create a temporary video model for history
    final video = TrainingVideoModel(
      id: widget.videoId,
      title: widget.title,
      thumbnailUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
      channelTitle: widget.instructor,
      description: '',
      viewCount: 0,
      category: widget.category,
      difficulty: widget.difficulty,
      durationInSeconds: _totalDuration,
      tags: [],
      instructor: widget.instructor,
      rating: 0.0,
      enrollmentCount: 0,
    );

    await widget.historyService.addToHistory(
      video,
      watchDurationInSeconds: watchDuration,
      totalDurationInSeconds: _totalDuration,
      watchProgress: progress,
      lastPositionInSeconds: _currentPosition,
    );
  }

  Future<void> _updateHistoryProgress({
    required double progress,
    bool isFinal = false,
  }) async {
    final watchDuration = DateTime.now().difference(_startWatchTime!).inSeconds;

    await widget.historyService.updateProgress(
      videoId: widget.videoId,
      watchProgress: progress,
      lastPositionInSeconds: _currentPosition,
      watchDurationInSeconds: watchDuration,
      isCompleted: progress >= 95.0,
    );
  }
}
