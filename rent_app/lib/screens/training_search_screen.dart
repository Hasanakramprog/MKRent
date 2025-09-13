import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/training_video_model.dart';
import '../services/training_youtube_service.dart';
import '../services/training_history_service.dart';
import 'youtube_video_player_screen.dart';

class TrainingSearchScreen extends StatefulWidget {
  const TrainingSearchScreen({Key? key}) : super(key: key);

  @override
  _TrainingSearchScreenState createState() => _TrainingSearchScreenState();
}

class _TrainingSearchScreenState extends State<TrainingSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TrainingYouTubeService _youtubeService = TrainingYouTubeService();
  final TrainingHistoryService _historyService = TrainingHistoryService();
  
  List<TrainingVideoModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _quickSearches = [
    'Camera basics',
    'Portrait photography',
    'Landscape photography',
    'Drone photography',
    'Photo editing',
    'Studio lighting',
    'Street photography',
    'Wedding photography',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search photography courses...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _performSearch,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
      ),
      body: Column(
        children: [
          if (!_hasSearched) _buildQuickSearchSection(),
          Expanded(
            child: _isSearching
                ? _buildLoadingIndicator()
                : _hasSearched
                    ? _buildSearchResults()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Quick Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickSearches.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    _quickSearches[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  onPressed: () {
                    _searchController.text = _quickSearches[index];
                    _performSearch();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          SizedBox(height: 16),
          Text(
            'Searching courses...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Search Photography Courses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find courses on camera techniques, editing, lighting and more',
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey[600],
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'No courses found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for different keywords',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSearchResultItem(_searchResults[index]);
      },
    );
  }

  Widget _buildSearchResultItem(TrainingVideoModel video) {
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
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
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
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
                      'by ${video.instructor}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
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
                        const SizedBox(width: 8),
                        Text(
                          video.category,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (video.formattedDuration.isNotEmpty)
                          Text(
                            video.formattedDuration,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                        Text(
                          _formatEnrollment(video.enrollmentCount),
                          style: TextStyle(
                            color: Colors.grey[400],
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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _youtubeService.searchTrainingVideos(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
