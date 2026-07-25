import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/radio_browser_service.dart';

class DirectoryController extends ChangeNotifier {
  final RadioBrowserService _service;

  List<Station> _stations = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedTag;

  Timer? _debounceTimer;
  int _requestToken = 0;

  DirectoryController({RadioBrowserService? service})
    : _service = service ?? RadioBrowserService();

  List<Station> get stations => List.unmodifiable(_stations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  Future<void> loadPopularStations() async {
    _searchQuery = '';
    _selectedTag = null;
    await _executeFetch(() => _service.getPopularStations(limit: 24));
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _selectedTag = null;
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      loadPopularStations();
      return;
    }

    // Spike 10: 300ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeFetch(() => _service.searchByName(query.trim(), limit: 50));
    });
  }

  void selectTag(String? tag) {
    if (_selectedTag == tag) {
      // Toggle off tag if re-clicked
      loadPopularStations();
      return;
    }

    _selectedTag = tag;
    _searchQuery = '';
    _debounceTimer?.cancel();

    if (tag == null || tag.isEmpty) {
      loadPopularStations();
      return;
    }

    _executeFetch(() => _service.searchByTag(tag, limit: 50));
  }

  Future<void> retry() async {
    if (_selectedTag != null) {
      selectTag(_selectedTag);
    } else if (_searchQuery.isNotEmpty) {
      onSearchChanged(_searchQuery);
    } else {
      loadPopularStations();
    }
  }

  Future<void> _executeFetch(
    Future<List<dynamic>> Function() fetchAction,
  ) async {
    final currentToken = ++_requestToken;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawList = await fetchAction();
      if (currentToken != _requestToken) return; // Ignore stale request

      final List<Station> parsed = [];
      for (final raw in rawList) {
        final station = Station.tryFromJson(raw);
        if (station != null) {
          parsed.add(station);
        }
      }

      _stations = parsed;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (currentToken != _requestToken) return; // Ignore stale error

      _isLoading = false;
      _errorMessage = e.toString().replaceAll('RadioBrowserException: ', '');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
