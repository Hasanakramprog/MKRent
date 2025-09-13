import 'package:flutter/material.dart';
import 'video_model.dart';

class TrainingVideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String description;
  final int viewCount;
  final String category; // Photography, Drone, Camera, etc.
  final String difficulty; // Beginner, Intermediate, Advanced
  final int durationInSeconds;
  final List<String> tags;
  final String instructor;
  final double rating;
  final int enrollmentCount;

  TrainingVideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.description,
    required this.viewCount,
    required this.category,
    required this.difficulty,
    required this.durationInSeconds,
    required this.tags,
    required this.instructor,
    required this.rating,
    required this.enrollmentCount,
  });

  factory TrainingVideoModel.fromJson(Map<String, dynamic> json) {
    return TrainingVideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      description: json['description'] ?? '',
      viewCount: int.tryParse(json['statistics']?['viewCount'] ?? '0') ?? 0,
      category: json['category'] ?? 'Photography',
      difficulty: json['difficulty'] ?? 'Beginner',
      durationInSeconds: json['durationInSeconds'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      instructor: json['instructor'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      enrollmentCount: json['enrollmentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'description': description,
      'viewCount': viewCount,
      'category': category,
      'difficulty': difficulty,
      'durationInSeconds': durationInSeconds,
      'tags': tags,
      'instructor': instructor,
      'rating': rating,
      'enrollmentCount': enrollmentCount,
    };
  }

  // Create from the original VideoModel
  factory TrainingVideoModel.fromVideoModel(VideoModel video, {
    String category = 'Photography',
    String difficulty = 'Beginner',
    int durationInSeconds = 0,
    List<String> tags = const [],
    String instructor = '',
    double rating = 0.0,
    int enrollmentCount = 0,
  }) {
    return TrainingVideoModel(
      id: video.id,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      channelTitle: video.channelTitle,
      description: video.description,
      viewCount: video.viewCount,
      category: category,
      difficulty: difficulty,
      durationInSeconds: durationInSeconds,
      tags: tags,
      instructor: instructor,
      rating: rating,
      enrollmentCount: enrollmentCount,
    );
  }

  String get formattedDuration {
    final duration = Duration(seconds: durationInSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
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

  Color get difficultyColor {
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
