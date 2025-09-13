import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/training_history_model.dart';
import '../services/training_history_service.dart';
import 'youtube_video_player_screen.dart';

class TrainingHistoryScreen extends StatefulWidget {
  final TrainingHistoryService historyService;

  const TrainingHistoryScreen({required this.historyService, Key? key}) : super(key: key);

  @override
  _TrainingHistoryScreenState createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> with TickerProviderStateMixin {
  Future<List<TrainingHistoryItem>>? _historyFuture;
  int _selectedIndex = 1;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _refreshHistory() {
    setState(() {
      _historyFuture = widget.historyService.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Learning History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _showClearHistoryDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'In Progress'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllHistoryTab(),
          _buildCompletedTab(),
          _buildInProgressTab(),
          _buildStatsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildAllHistoryTab() {
    return FutureBuilder<List<TrainingHistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load history');
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget('No learning history yet', 'Start watching courses to see your progress here');
        }
        
        return _buildHistoryList(snapshot.data!);
      },
    );
  }

  Widget _buildCompletedTab() {
    return FutureBuilder<List<TrainingHistoryItem>>(
      future: widget.historyService.getCompletedVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load completed courses');
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(
            'No completed courses yet', 
            'Complete your first course to see it here!\n🎉 You\'ll earn achievements for completed courses.',
            icon: Icons.emoji_events,
          );
        }
        
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed Courses',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${snapshot.data!.length} courses completed',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCompletedHistoryList(snapshot.data!)),
          ],
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    return FutureBuilder<List<TrainingHistoryItem>>(
      future: widget.historyService.getInProgressVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load in-progress courses');
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(
            'No courses in progress', 
            'Start watching a course to see it here!\n📚 Continue where you left off anytime.',
            icon: Icons.play_circle_outline,
          );
        }
        
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Learning',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${snapshot.data!.length} courses in progress',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildInProgressHistoryList(snapshot.data!)),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<Map<String, int>>(
      future: widget.historyService.getLearningStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load stats');
        }
        
        final stats = snapshot.data ?? {};
        return _buildStatsWidget(stats);
      },
    );
  }

  Widget _buildHistoryList(List<TrainingHistoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(context, items[index]);
      },
    );
  }

  Widget _buildCompletedHistoryList(List<TrainingHistoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildCompletedHistoryItem(context, items[index]);
      },
    );
  }

  Widget _buildInProgressHistoryList(List<TrainingHistoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildInProgressHistoryItem(context, items[index]);
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, TrainingHistoryItem item) {
    double progressPercent = item.watchProgress.clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubeVideoPlayerScreen(
                videoId: item.videoId,
                title: item.title,
                category: item.category,
                difficulty: item.difficulty,
                instructor: item.instructor,
                historyService: widget.historyService,
              ),
            ),
          ).then((_) => _refreshHistory());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with progress overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
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
                  // Progress bar overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  // Completion badge
                  if (item.isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${item.instructor}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          item.difficultyIcon,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(item.difficulty),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            children: [
                              Text(
                                item.categoryIcon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.progressStatus,
                          style: TextStyle(
                            color: item.isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item.watchProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(item.watchedAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                color: const Color(0xFF2A2A2A),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove from history', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  if (item.userRating == null)
                    PopupMenuItem(
                      value: 'rate',
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Rate course', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'remove') {
                    await widget.historyService.removeFromHistory(item.videoId);
                    _refreshHistory();
                  } else if (value == 'rate') {
                    _showRatingDialog(item);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedHistoryItem(BuildContext context, TrainingHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubeVideoPlayerScreen(
                videoId: item.videoId,
                title: item.title,
                category: item.category,
                difficulty: item.difficulty,
                instructor: item.instructor,
                historyService: widget.historyService,
              ),
            ),
          ).then((_) => _refreshHistory());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with completion badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
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
                  // Completion badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${item.instructor}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(item.difficulty),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF4CAF50),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(item.watchedAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInProgressHistoryItem(BuildContext context, TrainingHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubeVideoPlayerScreen(
                videoId: item.videoId,
                title: item.title,
                category: item.category,
                difficulty: item.difficulty,
                instructor: item.instructor,
                historyService: widget.historyService,
              ),
            ),
          ).then((_) => _refreshHistory());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with progress overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
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
                  // Progress overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: LinearProgressIndicator(
                        value: item.watchProgress,
                        backgroundColor: Colors.black.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  // Resume play button
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${item.instructor}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(item.difficulty),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item.watchProgress * 100).toInt()}% complete',
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(item.watchedAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsWidget(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  stats['completedVideos']?.toString() ?? '0',
                  Icons.check_circle,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  stats['inProgressVideos']?.toString() ?? '0',
                  Icons.play_circle_outline,
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Videos',
                  stats['totalVideos']?.toString() ?? '0',
                  Icons.video_library,
                  const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Watch Time',
                  '${stats['totalWatchTimeHours'] ?? 0}h',
                  Icons.access_time,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Achievement section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Learning Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAchievement(
                  'First Steps',
                  'Completed your first course',
                  (stats['completedVideos'] ?? 0) > 0,
                ),
                _buildAchievement(
                  'Dedicated Learner',
                  'Completed 5 courses',
                  (stats['completedVideos'] ?? 0) >= 5,
                ),
                _buildAchievement(
                  'Marathon Learner',
                  'Watched 10+ hours of content',
                  (stats['totalWatchTimeHours'] ?? 0) >= 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(String title, String description, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isUnlocked ? Icons.emoji_events : Icons.lock,
            color: isUnlocked ? const Color(0xFFFFD700) : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle, {IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.school_outlined,
            color: Colors.grey[600],
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Retry'),
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

        if (index == 0) {
          Navigator.pop(context); // Go back to home
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

  Future<void> _showClearHistoryDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear all your learning history? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.historyService.clearHistory();
              _refreshHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(TrainingHistoryItem item) {
    double rating = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Rate this course', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How would you rate "${item.title}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    rating = index + 1.0;
                  },
                  icon: Icon(
                    Icons.star,
                    color: rating > index ? Colors.amber : Colors.grey,
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (rating > 0) {
                await widget.historyService.rateVideo(item.videoId, rating);
                _refreshHistory();
              }
              Navigator.pop(context);
            },
            child: const Text('Rate', style: TextStyle(color: Color(0xFF2196F3))),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
}
