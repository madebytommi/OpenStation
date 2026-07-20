import 'package:flutter/foundation.dart';

/// Application model representing a radio station, normalized from Radio Browser API.
@immutable
class Station {
  final String uuid;
  final String name;
  final String url;
  final String resolvedUrl;
  final String? homepage;
  final String? faviconUrl;
  final String? countryCode;
  final String? state;
  final List<String> tags;
  final String? codec;
  final int? bitrate;
  final bool? isWorking;

  const Station({
    required this.uuid,
    required this.name,
    required this.url,
    required this.resolvedUrl,
    this.homepage,
    this.faviconUrl,
    this.countryCode,
    this.state,
    this.tags = const [],
    this.codec,
    this.bitrate,
    this.isWorking,
  });

  /// Sanitizes string inputs to ensure `null` or blank strings do not become literal `"null"` text.
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    return str;
  }

  /// Safely converts a raw JSON map from Radio Browser into a normalized [Station] object.
  /// Throws [FormatException] if essential fields (like `stationuuid` or `url`) are missing.
  factory Station.fromJson(Map<String, dynamic> json) {
    final uuid = _cleanString(json['stationuuid']);
    if (uuid == null) {
      throw const FormatException('Missing required stationuuid field');
    }

    final rawUrl = _cleanString(json['url']);
    final rawResolvedUrl = _cleanString(json['url_resolved']);
    final url = rawUrl ?? rawResolvedUrl;

    if (url == null) {
      throw const FormatException('Missing required stream URL field');
    }

    final resolvedUrl = rawResolvedUrl ?? url;

    final nameStr = _cleanString(json['name']);
    final name = nameStr ?? 'Unknown station';

    // Parse bitrate (treat 0 or negative as null)
    int? bitrate;
    if (json['bitrate'] != null) {
      if (json['bitrate'] is num) {
        final val = (json['bitrate'] as num).toInt();
        if (val > 0) bitrate = val;
      } else if (json['bitrate'] is String) {
        final val = int.tryParse(json['bitrate']);
        if (val != null && val > 0) bitrate = val;
      }
    }

    // Parse tags into a clean List<String>
    final List<String> tagsList = [];
    final rawTags = json['tags'];
    if (rawTags is String) {
      final split = rawTags.split(',');
      for (final t in split) {
        final cleaned = _cleanString(t);
        if (cleaned != null) tagsList.add(cleaned);
      }
    } else if (rawTags is List) {
      for (final t in rawTags) {
        final cleaned = _cleanString(t);
        if (cleaned != null) tagsList.add(cleaned);
      }
    }

    // Parse lastcheckok boolean flag
    bool? isWorking;
    if (json['lastcheckok'] != null) {
      if (json['lastcheckok'] is num) {
        isWorking = (json['lastcheckok'] as num).toInt() == 1;
      } else if (json['lastcheckok'] is bool) {
        isWorking = json['lastcheckok'] as bool;
      }
    }

    return Station(
      uuid: uuid,
      name: name,
      url: url,
      resolvedUrl: resolvedUrl,
      homepage: _cleanString(json['homepage']),
      faviconUrl: _cleanString(json['favicon']),
      countryCode: _cleanString(json['countrycode']),
      state: _cleanString(json['state']),
      tags: List.unmodifiable(tagsList),
      codec: _cleanString(json['codec']),
      bitrate: bitrate,
      isWorking: isWorking,
    );
  }

  /// Safely attempts to parse JSON, returning `null` if the record is invalid or missing required keys.
  static Station? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return Station.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'stationuuid': uuid,
      'name': name,
      'url': url,
      'url_resolved': resolvedUrl,
      'homepage': homepage,
      'favicon': faviconUrl,
      'countrycode': countryCode,
      'state': state,
      'tags': tags.join(','),
      'codec': codec,
      'bitrate': bitrate,
      'lastcheckok': isWorking == true ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;
}
