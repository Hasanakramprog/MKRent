import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_history_model.dart';
import '../models/training_video_model.dart';

class TrainingHistoryService {
  static const String _historyKey = 'training_watch_history';
  static const String _lastWatchedKey = 'training_last_watched';
  
  Future<List<TrainingHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        return historyList
            .map((item) => TrainingHistoryItem.fromMap(item))
            .toList()
          ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      }
      return [];
    } catch (e) {
      print('Error loading training history: $e');
      return [];
    }
  }

  Future<void> addToHistory(TrainingVideoModel video, {
    required int watchDurationInSeconds,
    required int totalDurationInSeconds,
    required double watchProgress,
    required int lastPositionInSeconds,
    bool isCompleted = false,
    double? userRating,
    List<String> completedSections = const [],
  }) async {
    try {
      final historyItem = TrainingHistoryItem(
        videoId: video.id,
        title: video.title,
        thumbnailUrl: video.thumbnailUrl,
        watchedAt: DateTime.now(),
        viewCount: video.viewCount,
        playlistTitle: null, // Will be set when called from playlist context
        category: video.category,
        difficulty: video.difficulty,
        instructor: video.instructor,
        watchDurationInSeconds: watchDurationInSeconds,
        totalDurationInSeconds: totalDurationInSeconds,
        watchProgress: watchProgress,
        lastPositionInSeconds: lastPositionInSeconds,
        isCompleted: isCompleted,
        userRating: userRating,
        completedSections: completedSections,
      );

      await _saveHistoryItem(historyItem);
      await _saveAsLastWatched(historyItem);
    } catch (e) {
      print('Error adding to training history: $e');
    }
  }

  Future<void> updateProgress({
    required String videoId,
    required double watchProgress,
    required int lastPositionInSeconds,
    int? watchDurationInSeconds,
    bool? isCompleted,
    double? userRating,
    List<String>? completedSections,
  }) async {
    try {
      final history = await getHistory();
      final existingIndex = history.indexWhere((item) => item.videoId == videoId);
      
      if (existingIndex != -1) {
        final existingItem = history[existingIndex];
        final updatedItem = existingItem.copyWith(
          watchProgress: watchProgress,
          lastPositionInSeconds: lastPositionInSeconds,
          watchDurationInSeconds: watchDurationInSeconds ?? existingItem.watchDurationInSeconds,
          isCompleted: isCompleted ?? (watchProgress >= 95.0),
          userRating: userRating,
          completedSections: completedSections,
          watchedAt: DateTime.now(),
        );
        
        history[existingIndex] = updatedItem;
        await _saveHistory(history);
        await _saveAsLastWatched(updatedItem);
      }
    } catch (e) {
      print('Error updating training progress: $e');
    }
  }

  Future<TrainingHistoryItem?> getVideoHistory(String videoId) async {
    try {
      final history = await getHistory();
      return history.firstWhere(
        (item) => item.videoId == videoId,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<TrainingHistoryItem?> getLastWatchedVideo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWatchedJson = prefs.getString(_lastWatchedKey);
      
      if (lastWatchedJson != null) {
        final Map<String, dynamic> lastWatchedMap = json.decode(lastWatchedJson);
        return TrainingHistoryItem.fromMap(lastWatchedMap);
      }
      return null;
    } catch (e) {
      print('Error loading last watched training video: $e');
      return null;
    }
  }

  Future<List<TrainingHistoryItem>> getCompletedVideos() async {
    try {
      final history = await getHistory();
      return history.where((item) => item.isCompleted).toList();
    } catch (e) {
      print('Error loading completed training videos: $e');
      return [];
    }
  }

  Future<List<TrainingHistoryItem>> getInProgressVideos() async {
    try {
      final history = await getHistory();
      return history
          .where((item) => !item.isCompleted && item.watchProgress > 0.05)
          .toList();
    } catch (e) {
      print('Error loading in-progress training videos: $e');
      return [];
    }
  }

  Future<List<TrainingHistoryItem>> getVideosByCategory(String category) async {
    try {
      final history = await getHistory();
      return history
          .where((item) => item.category.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (e) {
      print('Error loading training videos by category: $e');
      return [];
    }
  }

  Future<List<TrainingHistoryItem>> getVideosByDifficulty(String difficulty) async {
    try {
      final history = await getHistory();
      return history
          .where((item) => item.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    } catch (e) {
      print('Error loading training videos by difficulty: $e');
      return [];
    }
  }

  Future<Map<String, int>> getLearningStats() async {
    try {
      final history = await getHistory();
      final completed = history.where((item) => item.isCompleted).length;
      final inProgress = history.where((item) => !item.isCompleted && item.watchProgress > 0.05).length;
      final totalWatchTime = history.fold<int>(0, (sum, item) => sum + item.watchDurationInSeconds);
      
      return {
        'completedVideos': completed,
        'inProgressVideos': inProgress,
        'totalVideos': history.length,
        'totalWatchTimeHours': (totalWatchTime / 3600).round(),
      };
    } catch (e) {
      print('Error calculating learning stats: $e');
      return {
        'completedVideos': 0,
        'inProgressVideos': 0,
        'totalVideos': 0,
        'totalWatchTimeHours': 0,
      };
    }
  }

  Future<void> rateVideo(String videoId, double rating) async {
    try {
      await updateProgress(
        videoId: videoId,
        watchProgress: 0, // Will be ignored since we're only updating rating
        lastPositionInSeconds: 0, // Will be ignored
        userRating: rating,
      );
    } catch (e) {
      print('Error rating training video: $e');
    }
  }

  Future<void> markSectionCompleted(String videoId, String sectionName) async {
    try {
      final history = await getHistory();
      final existingIndex = history.indexWhere((item) => item.videoId == videoId);
      
      if (existingIndex != -1) {
        final existingItem = history[existingIndex];
        final updatedSections = List<String>.from(existingItem.completedSections);
        
        if (!updatedSections.contains(sectionName)) {
          updatedSections.add(sectionName);
          
          await updateProgress(
            videoId: videoId,
            watchProgress: existingItem.watchProgress,
            lastPositionInSeconds: existingItem.lastPositionInSeconds,
            completedSections: updatedSections,
          );
        }
      }
    } catch (e) {
      print('Error marking section completed: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      await prefs.remove(_lastWatchedKey);
    } catch (e) {
      print('Error clearing training history: $e');
    }
  }

  Future<void> removeFromHistory(String videoId) async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => item.videoId == videoId);
      await _saveHistory(history);
    } catch (e) {
      print('Error removing from training history: $e');
    }
  }

  Future<void> _saveHistoryItem(TrainingHistoryItem item) async {
    final history = await getHistory();
    
    // Remove existing entry if it exists
    history.removeWhere((existingItem) => existingItem.videoId == item.videoId);
    
    // Add new entry at the beginning
    history.insert(0, item);
    
    // Keep only last 100 items
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    await _saveHistory(history);
  }

  Future<void> _saveHistory(List<TrainingHistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        history.map((item) => item.toMap()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving training history: $e');
    }
  }

  Future<void> _saveAsLastWatched(TrainingHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWatchedJson = json.encode(item.toMap());
      await prefs.setString(_lastWatchedKey, lastWatchedJson);
    } catch (e) {
      print('Error saving last watched training video: $e');
    }
  }
}
