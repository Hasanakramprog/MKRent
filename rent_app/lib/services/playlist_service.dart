import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/saved_playlist_model.dart';

class PlaylistService {
  static List<SavedPlaylist>? _cachedPlaylists;

  /// Load playlists from the JSON file
  static Future<List<SavedPlaylist>> loadSavedPlaylists() async {
    if (_cachedPlaylists != null) {
      return _cachedPlaylists!;
    }

    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/saved_playlists.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Convert to SavedPlaylist objects
      _cachedPlaylists = jsonData
          .map((json) => SavedPlaylist.fromJson(json))
          .toList();
      
      return _cachedPlaylists!;
    } catch (e) {
      print('Error loading saved playlists: $e');
      return [];
    }
  }

  /// Get playlist ID by title
  static Future<String?> getPlaylistIdByTitle(String title) async {
    final playlists = await loadSavedPlaylists();
    for (var playlist in playlists) {
      if (playlist.title.toLowerCase().contains(title.toLowerCase())) {
        return playlist.id;
      }
    }
    return null;
  }

  /// Get all playlist titles
  static Future<List<String>> getAllPlaylistTitles() async {
    final playlists = await loadSavedPlaylists();
    return playlists.map((playlist) => playlist.title).toList();
  }

  /// Add a new playlist (and save to file)
  static Future<void> addPlaylist(SavedPlaylist playlist) async {
    final playlists = await loadSavedPlaylists();
    playlists.add(playlist);
    _cachedPlaylists = playlists;
    // Note: To persist changes, you'd need to write back to a file in the device storage
    // For now, changes are only in memory during app session
  }

  /// Remove a playlist
  static Future<void> removePlaylist(String playlistId) async {
    final playlists = await loadSavedPlaylists();
    playlists.removeWhere((playlist) => playlist.id == playlistId);
    _cachedPlaylists = playlists;
  }

  /// Clear cache (useful for refreshing data)
  static void clearCache() {
    _cachedPlaylists = null;
  }
}
