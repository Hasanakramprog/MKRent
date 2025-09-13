class TrainingPlaylist {
  final String title;
  final String id;
  final String description;
  final String thumbnailUrl;
  final String category;
  final String difficulty;
  final int videoCount;
  final String instructor;
  final double rating;
  final int enrollmentCount;
  final List<String> tags;
  final bool isPremium;
  final double price;

  TrainingPlaylist({
    required this.title,
    required this.id,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.videoCount,
    required this.instructor,
    required this.rating,
    required this.enrollmentCount,
    required this.tags,
    this.isPremium = false,
    this.price = 0.0,
  });

  factory TrainingPlaylist.fromJson(Map<String, dynamic> json) {
    return TrainingPlaylist(
      title: json['title'] ?? '',
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      category: json['category'] ?? 'Photography',
      difficulty: json['difficulty'] ?? 'Beginner',
      videoCount: json['videoCount'] ?? 0,
      instructor: json['instructor'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      enrollmentCount: json['enrollmentCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isPremium: json['isPremium'] ?? false,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'difficulty': difficulty,
      'videoCount': videoCount,
      'instructor': instructor,
      'rating': rating,
      'enrollmentCount': enrollmentCount,
      'tags': tags,
      'isPremium': isPremium,
      'price': price,
    };
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

  String get formattedPrice {
    if (!isPremium || price == 0.0) {
      return 'Free';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedEnrollment {
    if (enrollmentCount >= 1000000) {
      return '${(enrollmentCount / 1000000).toStringAsFixed(1)}M students';
    } else if (enrollmentCount >= 1000) {
      return '${(enrollmentCount / 1000).toStringAsFixed(1)}K students';
    } else {
      return '$enrollmentCount students';
    }
  }
}
