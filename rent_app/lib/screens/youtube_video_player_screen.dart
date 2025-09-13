import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/training_video_model.dart';
import '../services/training_history_service.dart';

class YouTubeVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String category;
  final String difficulty;
  final String instructor;
  final TrainingHistoryService historyService;

  const YouTubeVideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.instructor,
    required this.historyService,
  }) : super(key: key);

  @override
  State<YouTubeVideoPlayerScreen> createState() => _YouTubeVideoPlayerScreenState();
}

class _YouTubeVideoPlayerScreenState extends State<YouTubeVideoPlayerScreen> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _hasLoadedProgress = false;
  int? _savedPositionSeconds;
  bool _isLoading = true;
  bool _isAddedToHistory = false;
  DateTime? _startWatchTime;

  @override
  void initState() {
    super.initState();
    _startWatchTime = DateTime.now();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Load saved progress first
    await _loadSavedProgress();
    
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false, // Don't auto-play until we set the position
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
        forceHD: false,
      ),
    );
    
    _controller!.addListener(_listener);
    
    setState(() {
      _isLoading = false;
    });
    
    // Check if we should show resume dialog
    _checkForResumePosition();
  }

  Future<void> _loadSavedProgress() async {
    try {
      final historyItem = await widget.historyService.getVideoHistory(widget.videoId);
      if (historyItem != null && historyItem.lastPositionInSeconds > 0) {
        _savedPositionSeconds = historyItem.lastPositionInSeconds;
        print('Found saved progress: ${historyItem.lastPositionInSeconds} seconds');
      }
    } catch (e) {
      print('Error loading saved progress: $e');
    }
  }

  Future<void> _checkForResumePosition() async {
    try {
      // Get history for this video
      final historyItem = await widget.historyService.getVideoHistory(widget.videoId);
      
      // If we have a saved position and it's less than 98% of the video
      if (historyItem != null && 
          historyItem.lastPositionInSeconds > 0 && 
          historyItem.watchProgress < 0.98) {
        // Ask user if they want to resume
        _showResumeDialog(historyItem.lastPositionInSeconds);
      }
    } catch (e) {
      print("Error checking resume position: $e");
    }
  }

  void _showResumeDialog(int resumePosition) {
    // Don't show for very short positions (less than 30 seconds)
    if (resumePosition < 30) return;

    String formattedTime = _formatDuration(Duration(seconds: resumePosition));

    // Wait for player to initialize before showing dialog
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Resume Watching?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Would you like to continue watching from $formattedTime?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Start Over',
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset the saved position flag so it doesn't auto-seek
                  _hasLoadedProgress = true;
                },
              ),
              TextButton(
                child: Text('Resume', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  if (_controller != null) {
                    _controller!.seekTo(Duration(seconds: resumePosition));
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  void _listener() {
    if (_isPlayerReady && _controller != null) {
      setState(() {
        _position = _controller!.value.position;
        _duration = _controller!.value.metaData.duration;
      });
      
      // Only auto-seek for very short positions (less than 30 seconds) to avoid conflicts with resume dialog
      if (!_hasLoadedProgress && _savedPositionSeconds != null && _savedPositionSeconds! > 0 && _savedPositionSeconds! < 30) {
        _controller!.seekTo(Duration(seconds: _savedPositionSeconds!));
        _hasLoadedProgress = true;
        print('Auto-seeked to saved position: $_savedPositionSeconds seconds');
      }
      
      // Calculate watch progress as decimal (0.0 to 1.0)
      double progress = 0.0;
      if (_duration.inSeconds > 0) {
        progress = _position.inSeconds / _duration.inSeconds;
      }

      // Add to history after 10 seconds of watching
      if (!_isAddedToHistory && _position.inSeconds >= 10) {
        _addToHistory(progress: progress);
        _isAddedToHistory = true;
      }

      // Update history periodically for progress tracking (every 30 seconds)
      if (_isAddedToHistory && _position.inSeconds % 30 == 0 && _position.inSeconds > 0) {
        _updateHistoryProgress(progress: progress);
      }
    }
  }

  Future<void> _addToHistory({required double progress}) async {
    final watchDuration = DateTime.now().difference(_startWatchTime!).inSeconds;

    // Create a TrainingVideoModel from the widget data
    final video = TrainingVideoModel(
      id: widget.videoId,
      title: widget.title,
      thumbnailUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
      channelTitle: widget.instructor,
      description: 'Video from ${widget.category} category',
      viewCount: 0,
      category: widget.category,
      difficulty: widget.difficulty,
      durationInSeconds: _duration.inSeconds,
      tags: [widget.category.toLowerCase()],
      instructor: widget.instructor,
      rating: 4.5,
      enrollmentCount: 100,
    );

    await widget.historyService.addToHistory(
      video,
      watchDurationInSeconds: watchDuration,
      totalDurationInSeconds: _duration.inSeconds,
      watchProgress: progress,
      lastPositionInSeconds: _position.inSeconds,
    );
  }

  Future<void> _updateHistoryProgress({
    required double progress,
    bool isFinal = false,
  }) async {
    final watchDuration = isFinal ? DateTime.now().difference(_startWatchTime!).inSeconds : null;

    final historyItem = await widget.historyService.getVideoHistory(widget.videoId);
    if (historyItem != null) {
      // Create updated video model
      final updatedVideo = TrainingVideoModel(
        id: widget.videoId,
        title: widget.title,
        thumbnailUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
        channelTitle: widget.instructor,
        description: 'Video from ${widget.category} category',
        viewCount: 0,
        category: widget.category,
        difficulty: widget.difficulty,
        durationInSeconds: _duration.inSeconds,
        tags: [widget.category.toLowerCase()],
        instructor: widget.instructor,
        rating: 4.5,
        enrollmentCount: 100,
      );

      await widget.historyService.addToHistory(
        updatedVideo,
        watchDurationInSeconds: watchDuration ?? historyItem.watchDurationInSeconds,
        totalDurationInSeconds: _duration.inSeconds,
        watchProgress: progress,
        lastPositionInSeconds: _position.inSeconds,
      );
    }
  }

  @override
  void dispose() {
    // Final update to watch history before disposing
    if (_isAddedToHistory && _duration.inSeconds > 0) {
      double progress = _position.inSeconds / _duration.inSeconds;
      _updateHistoryProgress(progress: progress, isFinal: true);
    }

    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds'
        : '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.red,
          ),
        ),
      );
    }
    
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        setState(() {
          _isFullScreen = false;
        });
      },
      onEnterFullScreen: () {
        setState(() {
          _isFullScreen = true;
        });
      },
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (data) {
          // Mark as completed when video ends
          final video = TrainingVideoModel(
            id: widget.videoId,
            title: widget.title,
            thumbnailUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
            channelTitle: widget.instructor,
            description: 'Video from ${widget.category} category',
            viewCount: 0,
            category: widget.category,
            difficulty: widget.difficulty,
            durationInSeconds: _duration.inSeconds,
            tags: [widget.category.toLowerCase()],
            instructor: widget.instructor,
            rating: 4.5,
            enrollmentCount: 100,
          );
          
          widget.historyService.addToHistory(
            video,
            watchDurationInSeconds: _duration.inSeconds,
            totalDurationInSeconds: _duration.inSeconds,
            watchProgress: 1.0,
            lastPositionInSeconds: _duration.inSeconds,
            isCompleted: true,
          );
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _isFullScreen
              ? null
              : AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Share video functionality
                        final videoUrl = 'https://youtube.com/watch?v=${widget.videoId}';
                        // You can add share functionality here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Video URL: $videoUrl')),
                        );
                      },
                    ),
                  ],
                ),
          body: Column(
            children: [
              // YouTube Player
              player,
              
              // Video Info (only show when not in fullscreen)
              if (!_isFullScreen)
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Video Title
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Video Progress Info
                          if (_isPlayerReady)
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  ' / ${_formatDuration(_duration)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const Spacer(),
                                if (_duration.inSeconds > 0)
                                  Text(
                                    '${(_position.inSeconds / _duration.inSeconds * 100).toInt()}% watched',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Video Details
                          _buildInfoCard('Category', widget.category, Icons.category),
                          _buildInfoCard('Difficulty', widget.difficulty, Icons.school),
                          _buildInfoCard('Instructor', widget.instructor, Icons.person),
                          
                          const SizedBox(height: 24),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final video = TrainingVideoModel(
                                      id: widget.videoId,
                                      title: widget.title,
                                      thumbnailUrl: 'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg',
                                      channelTitle: widget.instructor,
                                      description: 'Video from ${widget.category} category',
                                      viewCount: 0,
                                      category: widget.category,
                                      difficulty: widget.difficulty,
                                      durationInSeconds: _duration.inSeconds,
                                      tags: [widget.category.toLowerCase()],
                                      instructor: widget.instructor,
                                      rating: 4.5,
                                      enrollmentCount: 100,
                                    );
                                    
                                    await widget.historyService.addToHistory(
                                      video,
                                      watchDurationInSeconds: _position.inSeconds,
                                      totalDurationInSeconds: _duration.inSeconds,
                                      watchProgress: _position.inSeconds / _duration.inSeconds,
                                      lastPositionInSeconds: _position.inSeconds,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Added to learning history!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.bookmark_add),
                                  label: const Text('Save Progress'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Expanded(
                              //   child: ElevatedButton.icon(
                              //     onPressed: () {
                              //       final videoUrl = 'https://youtube.com/watch?v=${widget.videoId}';
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         SnackBar(content: Text('Video URL: $videoUrl')),
                              //       );
                              //     },
                              //     icon: const Icon(Icons.open_in_new),
                              //     label: const Text('Open in YouTube'),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.red[600],
                              //       foregroundColor: Colors.white,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[400], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
