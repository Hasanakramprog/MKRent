import 'package:flutter/material.dart';
import '../models/saved_playlist_model.dart';
import '../services/playlist_service.dart';
import '../services/training_youtube_service.dart';
import '../services/training_history_service.dart';
import '../models/training_video_model.dart';
import 'youtube_video_player_screen.dart';
import 'playlist_manager_screen.dart';

class SavedPlaylistsScreen extends StatefulWidget {
  const SavedPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<SavedPlaylistsScreen> createState() => _SavedPlaylistsScreenState();
}

class _SavedPlaylistsScreenState extends State<SavedPlaylistsScreen> {
  List<SavedPlaylist> _playlists = [];
  bool _isLoading = true;
  String? _loadingPlaylistId;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await PlaylistService.loadSavedPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlists: $e')),
        );
      }
    }
  }

  Future<void> _viewPlaylist(SavedPlaylist playlist) async {
    if (_loadingPlaylistId != null) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _loadingPlaylistId = playlist.id;
    });

    try {
      final videos = await TrainingYouTubeService().fetchVideosFromPlaylist(playlist.title);
      if (mounted) {
        setState(() {
          _loadingPlaylistId = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistVideosScreen(
              playlistTitle: playlist.title,
              videos: videos,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPlaylistId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlist videos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Playlists'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaylistManagerScreen(),
                ),
              );
              // Refresh playlists after returning from manager
              _loadPlaylists();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _playlists.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved playlists found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final isLoading = _loadingPlaylistId == playlist.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        enabled: !isLoading,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[800],
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.playlist_play,
                                  color: Colors.white,
                                ),
                        ),
                        title: Text(
                          playlist.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isLoading ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          isLoading ? 'Loading videos...' : 'Playlist ID: ${playlist.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: isLoading ? null : () => _viewPlaylist(playlist),
                      ),
                    );
                  },
                    ),
          // Global loading overlay
          if (_loadingPlaylistId != null)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading playlist videos...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlaylistVideosScreen extends StatelessWidget {
  final String playlistTitle;
  final List<TrainingVideoModel> videos;

  const PlaylistVideosScreen({
    Key? key,
    required this.playlistTitle,
    required this.videos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlistTitle),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: videos.isEmpty
          ? const Center(
              child: Text(
                'No videos found in this playlist',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        video.thumbnailUrl,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.video_library),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.instructor,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(
                              ' ${video.rating}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time, size: 14, color: Colors.grey),
                            Flexible(
                              child: Text(
                                ' ${video.formattedDuration}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.play_arrow),
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
                            historyService: TrainingHistoryService(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
