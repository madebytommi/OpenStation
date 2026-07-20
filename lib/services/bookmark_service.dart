import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_station/models/station.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BookmarkService extends ChangeNotifier {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  File? _storageFile;
  final List<Station> _bookmarks = [];
  double _lastVolume = 1.0;
  Completer<void>? _saveLock;

  List<Station> get bookmarks => List.unmodifiable(_bookmarks);
  double get lastVolume => _lastVolume;

  @visibleForTesting
  File? customStorageFile;

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

    await _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    if (_storageFile == null || !await _storageFile!.exists()) {
      return;
    }

    try {
      final jsonString = await _storageFile!.readAsString();
      if (jsonString.trim().isEmpty) return;

      final dynamic data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) return;

      if (data['volume'] is num) {
        _lastVolume = (data['volume'] as num).toDouble().clamp(0.0, 1.0);
      }

      if (data['bookmarks'] is List) {
        final List<dynamic> rawList = data['bookmarks'];
        _bookmarks.clear();
        for (final item in rawList) {
          final station = Station.tryFromJson(item);
          if (station != null) {
            if (!_bookmarks.any((b) => b.uuid == station.uuid)) {
              _bookmarks.add(station);
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveToDisk() async {
    if (_storageFile == null) return;

    while (_saveLock != null) {
      await _saveLock!.future;
    }

    _saveLock = Completer<void>();

    try {
      final data = {
        'volume': _lastVolume,
        'bookmarks': _bookmarks.map((s) => s.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      final tmpFile = File('${_storageFile!.path}.tmp');

      await tmpFile.writeAsString(jsonString, flush: true);

      if (await _storageFile!.exists()) {
        await _storageFile!.delete();
      }
      await tmpFile.rename(_storageFile!.path);
    } catch (e) {
      debugPrint('Failed to save bookmarks atomically: $e');
    } finally {
      final lock = _saveLock;
      _saveLock = null;
      lock?.complete();
    }
  }

  Future<void> addBookmark(Station station) async {
    if (!_bookmarks.any((b) => b.uuid == station.uuid)) {
      _bookmarks.add(station);
      notifyListeners();
      await _saveToDisk();
    }
  }

  Future<void> removeBookmark(String uuid) async {
    final initialLength = _bookmarks.length;
    _bookmarks.removeWhere((b) => b.uuid == uuid);
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
    return _bookmarks.any((b) => b.uuid == uuid);
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
    notifyListeners();
  }
}
