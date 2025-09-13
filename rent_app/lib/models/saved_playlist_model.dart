class SavedPlaylist {
  final String title;
  final String id;

  SavedPlaylist({
    required this.title,
    required this.id,
  });

  factory SavedPlaylist.fromJson(Map<String, dynamic> json) {
    return SavedPlaylist(
      title: json['title'] ?? '',
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
    };
  }
}
