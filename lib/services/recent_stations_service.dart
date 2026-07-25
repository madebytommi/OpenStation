import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_station/models/station.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RecentStationsService extends ChangeNotifier {
  static final RecentStationsService _instance =
      RecentStationsService._internal();
  factory RecentStationsService() => _instance;
  RecentStationsService._internal();

  File? _storageFile;
  final List<Station> _recentStations = [];
  Completer<void>? _saveLock;
  bool _loadFailed = false;

  List<Station> get recentStations => List.unmodifiable(_recentStations);

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
      _storageFile = File(p.join(folder.path, 'recent_stations.json'));
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

      if (data['recentStations'] is List) {
        final List<dynamic> rawList = data['recentStations'];
        _recentStations.clear();
        for (final item in rawList) {
          final station = Station.tryFromJson(item);
          if (station != null) {
            if (!_recentStations.any((b) => b.uuid == station.uuid)) {
              _recentStations.add(station);
            }
          }
        }

        // Enforce the 10 limit just in case a corrupted file had more
        while (_recentStations.length > 10) {
          _recentStations.removeLast();
        }
      }
      notifyListeners();
    } catch (e) {
      _loadFailed = true;
      debugPrint('Error loading recent stations: $e');
    }
  }

  Future<void> _saveToDisk() async {
    if (_storageFile == null || _loadFailed) return;

    while (_saveLock != null) {
      await _saveLock!.future;
    }

    _saveLock = Completer<void>();

    try {
      final data = {
        'recentStations': _recentStations.map((s) => s.toJson()).toList(),
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
      debugPrint('Failed to save recent stations atomically: $e');
    } finally {
      final lock = _saveLock;
      _saveLock = null;
      lock?.complete();
    }
  }

  Future<void> addRecentStation(Station station) async {
    final index = _recentStations.indexWhere((s) => s.uuid == station.uuid);

    if (index != -1) {
      // If it exists, remove it from its current position
      _recentStations.removeAt(index);
    }

    // Insert at the top (most recent)
    _recentStations.insert(0, station);

    // Enforce exactly 10 limit by removing the oldest from the end
    while (_recentStations.length > 10) {
      _recentStations.removeLast();
    }

    notifyListeners();
    await _saveToDisk();
  }

  @visibleForTesting
  void clearMemory() {
    _recentStations.clear();
    _loadFailed = false;
    notifyListeners();
  }
}
