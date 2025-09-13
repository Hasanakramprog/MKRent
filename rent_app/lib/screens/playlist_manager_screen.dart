import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_playlist_model.dart';
import '../services/playlist_service.dart';

class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  List<SavedPlaylist> _playlists = [];
  bool _isLoading = true;
  final _titleController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await PlaylistService.loadSavedPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error loading playlists: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showAddPlaylistDialog() async {
    _titleController.clear();
    _idController.clear();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Title',
                  hintText: 'Enter playlist title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Playlist ID',
                  hintText: 'Enter YouTube playlist ID',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can find the playlist ID in the YouTube URL:\nhttps://youtube.com/playlist?list=YOUR_PLAYLIST_ID',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addPlaylist();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPlaylist() async {
    final title = _titleController.text.trim();
    final id = _idController.text.trim();

    if (title.isEmpty || id.isEmpty) {
      _showError('Please fill in both title and ID');
      return;
    }

    try {
      final newPlaylist = SavedPlaylist(title: title, id: id);
      await PlaylistService.addPlaylist(newPlaylist);
      await _loadPlaylists(); // Refresh the list
      _showSuccess('Playlist added successfully!');
    } catch (e) {
      _showError('Error adding playlist: $e');
    }
  }

  Future<void> _removePlaylist(SavedPlaylist playlist) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Playlist'),
          content: Text('Are you sure you want to remove "${playlist.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      try {
        await PlaylistService.removePlaylist(playlist.id);
        await _loadPlaylists(); // Refresh the list
        _showSuccess('Playlist removed successfully!');
      } catch (e) {
        _showError('Error removing playlist: $e');
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('$label copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Playlists'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instructions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Go to YouTube and find the playlist you want to add\n'
                            '2. Copy the playlist URL (it should contain "list=" parameter)\n'
                            '3. Extract the ID after "list=" in the URL\n'
                            '4. Add the playlist using the + button below',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _playlists.isEmpty
                      ? const Center(
                          child: Text(
                            'No playlists found.\nTap the + button to add your first playlist!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[800],
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  playlist.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${playlist.id}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'copy_title':
                                        _copyToClipboard(playlist.title, 'Title');
                                        break;
                                      case 'copy_id':
                                        _copyToClipboard(playlist.id, 'ID');
                                        break;
                                      case 'copy_url':
                                        _copyToClipboard(
                                          'https://youtube.com/playlist?list=${playlist.id}',
                                          'URL'
                                        );
                                        break;
                                      case 'remove':
                                        _removePlaylist(playlist);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'copy_title',
                                      child: ListTile(
                                        leading: Icon(Icons.copy),
                                        title: Text('Copy Title'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy_id',
                                      child: ListTile(
                                        leading: Icon(Icons.copy),
                                        title: Text('Copy ID'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy_url',
                                      child: ListTile(
                                        leading: Icon(Icons.link),
                                        title: Text('Copy URL'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlaylistDialog,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
