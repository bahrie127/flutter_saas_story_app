import 'user_model.dart';

class StoryModel {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String? image;
  final String? imageUrl;
  final double? lat;
  final double? lon;
  final UserModel? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.image,
    this.imageUrl,
    this.lat,
    this.lon,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  // Alias getters for compatibility
  String? get description => content;
  String? get photoUrl => imageUrl;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'lat': lat,
      'lon': lon,
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  StoryModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    String? image,
    String? imageUrl,
    double? lat,
    double? lon,
    UserModel? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 7) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
