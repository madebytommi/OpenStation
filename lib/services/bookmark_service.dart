import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_station/models/bookmark.dart';
import 'package:open_station/models/station.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BookmarkService extends ChangeNotifier {
  static const int storageSchemaVersion = 2;

  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  File? _storageFile;
  final List<Bookmark> _bookmarks = [];
  double _lastVolume = 1.0;
  Completer<void>? _saveLock;
  bool _loadFailed = false;

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  double get lastVolume => _lastVolume;

  @visibleForTesting
  File? customStorageFile;

  @visibleForTesting
  DateTime Function()? customNow;

  DateTime _nowUtc() => (customNow?.call() ?? DateTime.now()).toUtc();

  Future<void> init() async {
    if (customStorageFile != null) {
      _storageFile = customStorageFile;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(directory.path, 'OpenStation'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      _storageFile = File(p.join(folder.path, 'bookmarks.json'));
    }

    _loadFailed = false;
    await _loadFromDisk();
  }

  Future<DateTime> _legacyBookmarkDate() async {
    try {
      return (await _storageFile!.lastModified()).toUtc();
    } catch (_) {
      return _nowUtc();
    }
  }

  Future<void> _loadFromDisk() async {
    if (_storageFile == null || !await _storageFile!.exists()) {
      return;
    }

    try {
      final jsonString = await _storageFile!.readAsString();
      if (jsonString.trim().isEmpty) return;

      final dynamic data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Bookmark storage root must be an object');
      }

      if (data['volume'] is num) {
        _lastVolume = (data['volume'] as num).toDouble().clamp(0.0, 1.0);
      }

      var migratedLegacyRecords = false;
      DateTime? legacyBookmarkDate;

      if (data['bookmarks'] is List) {
        final List<dynamic> rawList = data['bookmarks'];
        _bookmarks.clear();

        for (final item in rawList) {
          var bookmark = Bookmark.tryFromJson(item);

          if (bookmark == null) {
            final legacyStation = Station.tryFromJson(item);
            if (legacyStation != null) {
              legacyBookmarkDate ??= await _legacyBookmarkDate();
              bookmark = Bookmark(
                station: legacyStation,
                bookmarkedAt: legacyBookmarkDate,
              );
              migratedLegacyRecords = true;
            }
          }

          final loadedBookmark = bookmark;
          if (loadedBookmark != null &&
              !_bookmarks.any(
                (existing) =>
                    existing.station.uuid == loadedBookmark.station.uuid,
              )) {
            _bookmarks.add(loadedBookmark);
          }
        }
      }

      notifyListeners();

      if (migratedLegacyRecords) {
        await _saveToDisk();
      }
    } catch (error) {
      await _recoverFromCorruptStorage(error);
    }
  }

  Future<void> _recoverFromCorruptStorage(Object error) async {
    debugPrint('Error loading bookmarks: $error');

    _bookmarks.clear();
    _lastVolume = 1.0;

    final storageFile = _storageFile;
    if (storageFile == null || !await storageFile.exists()) {
      _loadFailed = false;
      notifyListeners();
      return;
    }

    try {
      final recoveryFile = await _nextCorruptStorageFile(storageFile);

      try {
        await storageFile.rename(recoveryFile.path);
      } on FileSystemException {
        await storageFile.copy(recoveryFile.path);
        await storageFile.delete();
      }

      _loadFailed = false;
      debugPrint(
        'Preserved corrupt bookmark data at ${recoveryFile.path}',
      );
    } catch (recoveryError) {
      _loadFailed = true;
      debugPrint(
        'Failed to preserve corrupt bookmark data: $recoveryError',
      );
    }

    notifyListeners();
  }

  Future<File> _nextCorruptStorageFile(File storageFile) async {
    final directory = storageFile.parent;
    final baseName = p.basenameWithoutExtension(storageFile.path);
    final extension = p.extension(storageFile.path);
    final timestamp = _formatCorruptTimestamp(_nowUtc());

    var collisionIndex = 0;
    while (true) {
      final collisionSuffix = collisionIndex == 0 ? '' : '-$collisionIndex';
      final candidate = File(
        p.join(
          directory.path,
          '$baseName.corrupt-$timestamp$collisionSuffix$extension',
        ),
      );

      if (!await candidate.exists()) {
        return candidate;
      }

      collisionIndex++;
    }
  }

  String _formatCorruptTimestamp(DateTime value) {
    final utc = value.toUtc();

    String pad(int number, int width) => number.toString().padLeft(width, '0');

    return '${pad(utc.year, 4)}${pad(utc.month, 2)}${pad(utc.day, 2)}'
        'T${pad(utc.hour, 2)}${pad(utc.minute, 2)}${pad(utc.second, 2)}'
        '${pad(utc.millisecond, 3)}Z';
  }

  Future<void> _saveToDisk() async {
    if (_storageFile == null || _loadFailed) return;

    while (_saveLock != null) {
      await _saveLock!.future;
    }

    _saveLock = Completer<void>();

    try {
      final data = {
        'schemaVersion': storageSchemaVersion,
        'volume': _lastVolume,
        'bookmarks': _bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      };
      final jsonString = jsonEncode(data);
      final tmpFile = File('${_storageFile!.path}.tmp');

      await tmpFile.writeAsString(jsonString, flush: true);

      try {
        await tmpFile.rename(_storageFile!.path);
      } on FileSystemException {
        await tmpFile.copy(_storageFile!.path);
        await tmpFile.delete();
      }
    } catch (e) {
      debugPrint('Failed to save bookmarks atomically: $e');
    } finally {
      final lock = _saveLock;
      _saveLock = null;
      lock?.complete();
    }
  }

  Future<void> addBookmark(Station station) async {
    if (!_bookmarks.any((bookmark) => bookmark.station.uuid == station.uuid)) {
      _bookmarks.add(Bookmark(station: station, bookmarkedAt: _nowUtc()));
      notifyListeners();
      await _saveToDisk();
    }
  }

  Future<void> removeBookmark(String uuid) async {
    final initialLength = _bookmarks.length;
    _bookmarks.removeWhere((bookmark) => bookmark.station.uuid == uuid);
    if (_bookmarks.length != initialLength) {
      notifyListeners();
      await _saveToDisk();
    }
  }

  Future<void> toggleBookmark(Station station) async {
    if (isBookmarked(station.uuid)) {
      await removeBookmark(station.uuid);
    } else {
      await addBookmark(station);
    }
  }

  bool isBookmarked(String uuid) {
    return _bookmarks.any((bookmark) => bookmark.station.uuid == uuid);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (_lastVolume != clamped) {
      _lastVolume = clamped;
      notifyListeners();
      await _saveToDisk();
    }
  }

  @visibleForTesting
  void clearMemory() {
    _bookmarks.clear();
    _lastVolume = 1.0;
    _loadFailed = false;
    customNow = null;
    notifyListeners();
  }
}
