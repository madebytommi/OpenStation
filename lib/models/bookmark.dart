import 'package:flutter/foundation.dart';
import 'package:open_station/models/station.dart';

/// A locally saved station snapshot and the time it was bookmarked.
@immutable
class Bookmark {
  const Bookmark({required this.station, required this.bookmarkedAt});

  final Station station;
  final DateTime bookmarkedAt;

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final station = Station.tryFromJson(json['station']);
    if (station == null) {
      throw const FormatException('Missing or invalid bookmark station');
    }

    final rawBookmarkedAt = json['bookmarkedAt'];
    if (rawBookmarkedAt is! String) {
      throw const FormatException('Missing bookmark date');
    }

    final bookmarkedAt = DateTime.tryParse(rawBookmarkedAt.trim());
    if (bookmarkedAt == null) {
      throw const FormatException('Invalid bookmark date');
    }

    return Bookmark(
      station: station,
      bookmarkedAt: bookmarkedAt.toUtc(),
    );
  }

  static Bookmark? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    try {
      return Bookmark.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'station': station.toJson(),
      'bookmarkedAt': bookmarkedAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bookmark &&
            station == other.station &&
            bookmarkedAt.toUtc() == other.bookmarkedAt.toUtc();
  }

  @override
  int get hashCode => Object.hash(station, bookmarkedAt.toUtc());
}
