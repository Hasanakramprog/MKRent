class TrainingHistoryItem {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime watchedAt;
  final int viewCount;
  final String? playlistTitle;
  final String category;
  final String difficulty;
  final String instructor;
  
  // Enhanced tracking fields
  final int watchDurationInSeconds;
  final int totalDurationInSeconds;
  final double watchProgress;
  final int lastPositionInSeconds;
  final bool isCompleted;
  final double? userRating;
  final List<String> completedSections;

  TrainingHistoryItem({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.watchedAt,
    required this.viewCount,
    this.playlistTitle,
    required this.category,
    required this.difficulty,
    required this.instructor,
    this.watchDurationInSeconds = 0,
    this.totalDurationInSeconds = 0,
    this.watchProgress = 0.0,
    this.lastPositionInSeconds = 0,
    this.isCompleted = false,
    this.userRating,
    this.completedSections = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'watchedAt': watchedAt.toIso8601String(),
      'viewCount': viewCount,
      'playlistTitle': playlistTitle,
      'category': category,
      'difficulty': difficulty,
      'instructor': instructor,
      'watchDurationInSeconds': watchDurationInSeconds,
      'totalDurationInSeconds': totalDurationInSeconds,
      'watchProgress': watchProgress,
      'lastPositionInSeconds': lastPositionInSeconds,
      'isCompleted': isCompleted,
      'userRating': userRating,
      'completedSections': completedSections,
    };
  }

  factory TrainingHistoryItem.fromMap(Map<String, dynamic> map) {
    return TrainingHistoryItem(
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      watchedAt: DateTime.parse(map['watchedAt'] ?? DateTime.now().toIso8601String()),
      viewCount: map['viewCount'] ?? 0,
      playlistTitle: map['playlistTitle'],
      category: map['category'] ?? 'Photography',
      difficulty: map['difficulty'] ?? 'Beginner',
      instructor: map['instructor'] ?? '',
      watchDurationInSeconds: map['watchDurationInSeconds'] ?? 0,
      totalDurationInSeconds: map['totalDurationInSeconds'] ?? 0,
      watchProgress: map['watchProgress']?.toDouble() ?? 0.0,
      lastPositionInSeconds: map['lastPositionInSeconds'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      userRating: map['userRating']?.toDouble(),
      completedSections: List<String>.from(map['completedSections'] ?? []),
    );
  }

  TrainingHistoryItem copyWith({
    String? videoId,
    String? title,
    String? thumbnailUrl,
    DateTime? watchedAt,
    int? viewCount,
    String? playlistTitle,
    String? category,
    String? difficulty,
    String? instructor,
    int? watchDurationInSeconds,
    int? totalDurationInSeconds,
    double? watchProgress,
    int? lastPositionInSeconds,
    bool? isCompleted,
    double? userRating,
    List<String>? completedSections,
  }) {
    return TrainingHistoryItem(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      watchedAt: watchedAt ?? this.watchedAt,
      viewCount: viewCount ?? this.viewCount,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      instructor: instructor ?? this.instructor,
      watchDurationInSeconds: watchDurationInSeconds ?? this.watchDurationInSeconds,
      totalDurationInSeconds: totalDurationInSeconds ?? this.totalDurationInSeconds,
      watchProgress: watchProgress ?? this.watchProgress,
      lastPositionInSeconds: lastPositionInSeconds ?? this.lastPositionInSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      userRating: userRating ?? this.userRating,
      completedSections: completedSections ?? this.completedSections,
    );
  }

  String get difficultyIcon {
    switch (difficulty) {
      case 'Beginner':
        return '🌱';
      case 'Intermediate':
        return '⭐';
      case 'Advanced':
        return '🏆';
      default:
        return '📚';
    }
  }

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'photography':
        return '📸';
      case 'drone':
        return '🚁';
      case 'camera':
        return '📹';
      case 'lighting':
        return '💡';
      case 'editing':
        return '✂️';
      default:
        return '🎬';
    }
  }

  String get progressStatus {
    if (isCompleted) return 'Completed';
    if (watchProgress >= 90) return 'Almost Done';
    if (watchProgress >= 50) return 'In Progress';
    if (watchProgress >= 10) return 'Started';
    return 'Not Started';
  }

  String get formattedDuration {
    final duration = Duration(seconds: lastPositionInSeconds);
    final total = Duration(seconds: totalDurationInSeconds);
    
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
      if (d.inHours > 0) {
        return '${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
      } else {
        return '$twoDigitMinutes:$twoDigitSeconds';
      }
    }
    
    if (totalDurationInSeconds == 0) return '--:--';
    return '${formatDuration(duration)} / ${formatDuration(total)}';
  }
}
