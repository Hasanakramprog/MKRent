class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String description;
  final int viewCount;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.description,
    required this.viewCount,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      description: json['description'] ?? '',
      viewCount: int.tryParse(json['statistics']?['viewCount'] ?? '0') ?? 0,
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
    };
  }
}
