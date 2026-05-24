import 'package:equatable/equatable.dart';

class FeedCommentEntity extends Equatable {
  const FeedCommentEntity({
    required this.id,
    required this.songId,
    required this.userId,
    required this.userName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String songId;
  final String userId;
  final String userName;
  final String text;
  final DateTime? createdAt;

  factory FeedCommentEntity.fromJson(Map<String, dynamic> json) {
    return FeedCommentEntity(
      id: json['id']?.toString() ?? '',
      songId: json['songId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, songId, userId, userName, text, createdAt];

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Ignore unsupported timestamp formats.
    }

    return null;
  }
}
