import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Custom exception thrown when Radio Browser API fails across all servers.
class RadioBrowserException implements Exception {
  final String message;
  final dynamic details;

  RadioBrowserException(this.message, [this.details]);

  @override
  String toString() =>
      'RadioBrowserException: $message${details != null ? " ($details)" : ""}';
}

/// Service handling DNS discovery, query execution, and failover for Radio Browser API.
class RadioBrowserService {
  static const String userAgent =
      'OpenStation/0.1.0 (Windows Desktop Radio App)';
  static const Duration defaultTimeout = Duration(seconds: 5);

  final http.Client _client;
  List<String> _servers = [];
  int _currentServerIndex = 0;

  RadioBrowserService({http.Client? client})
    : _client = client ?? http.Client();

  List<String> get servers => List.unmodifiable(_servers);
  String? get activeServer =>
      _servers.isNotEmpty ? _servers[_currentServerIndex] : null;

  /// Discover servers via DNS lookup for all.api.radio-browser.info.
  /// Falls back to default known mirrors if DNS lookup fails.
  Future<List<String>> discoverServers() async {
    final List<String> discovered = [];

    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        'all.api.radio-browser.info',
      ).timeout(const Duration(seconds: 5));
      for (final addr in addresses) {
        try {
          final reverse = await addr.reverse();
          if (reverse.host.isNotEmpty && !discovered.contains(reverse.host)) {
            discovered.add(reverse.host);
          }
        } catch (_) {
          // If reverse DNS fails for an IP, fallback to IP address host string
          if (!discovered.contains(addr.address)) {
            discovered.add(addr.address);
          }
        }
      }
    } catch (_) {
      // DNS lookup error fallback
    }

    // Default fallback servers if DNS lookup yields empty results
    if (discovered.isEmpty) {
      discovered.addAll([
        'de1.api.radio-browser.info',
        'nl1.api.radio-browser.info',
        'at1.api.radio-browser.info',
      ]);
    }

    // Shuffle for simple load balancing across clients
    discovered.shuffle();

    _servers = discovered;
    _currentServerIndex = 0;
    return _servers;
  }

  /// Manually set server list (useful for testing or custom overrides).
  void setServers(List<String> servers) {
    _servers = List.from(servers);
    _currentServerIndex = 0;
  }

  /// Execute an API request with automatic server failover and explicit timeouts.
  Future<List<dynamic>> _fetchJsonList(
    String pathWithQuery, {
    Duration timeout = defaultTimeout,
  }) async {
    if (_servers.isEmpty) {
      await discoverServers();
    }

    int attempts = 0;
    final int maxAttempts = _servers.length;
    Object? lastError;

    while (attempts < maxAttempts) {
      final host = _servers[_currentServerIndex];
      final url = Uri.parse('https://$host$pathWithQuery');

      try {
        final response = await _client
            .get(
              url,
              headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            return decoded;
          } else {
            throw RadioBrowserException(
              'Malformed API response: Expected JSON list, got ${decoded.runtimeType}',
            );
          }
        } else {
          lastError = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }
      } catch (e) {
        lastError = e;
      }

      // Failover to next server
      attempts++;
      _currentServerIndex = (_currentServerIndex + 1) % _servers.length;
    }

    throw RadioBrowserException(
      'All Radio Browser API servers failed after $attempts attempts.',
      lastError,
    );
  }

  /// Fetch ~20 popular working stations.
  Future<List<dynamic>> getPopularStations({
    int limit = 20,
    Duration timeout = defaultTimeout,
  }) async {
    return _fetchJsonList(
      '/json/stations/search?limit=$limit&order=clickcount&reverse=true&hidebroken=true',
      timeout: timeout,
    );
  }

  /// Search stations by name (returns max 50 by default).
  Future<List<dynamic>> searchByName(
    String name, {
    int limit = 50,
    Duration timeout = defaultTimeout,
  }) async {
    final encodedName = Uri.encodeComponent(name);
    return _fetchJsonList(
      '/json/stations/search?name=$encodedName&limit=$limit&hidebroken=true',
      timeout: timeout,
    );
  }

  /// Search stations by tag/genre (returns max 50 by default).
  Future<List<dynamic>> searchByTag(
    String tag, {
    int limit = 50,
    Duration timeout = defaultTimeout,
  }) async {
    final encodedTag = Uri.encodeComponent(tag);
    return _fetchJsonList(
      '/json/stations/search?tag=$encodedTag&limit=$limit&hidebroken=true',
      timeout: timeout,
    );
  }

  /// Search stations by name and tag in parallel, merging and deduplicating results.
  Future<List<dynamic>> searchByNameOrTag(
    String query, {
    int limit = 50,
    Duration timeout = defaultTimeout,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    List<dynamic>? nameResults;
    List<dynamic>? tagResults;
    Object? nameError;
    Object? tagError;

    await Future.wait([
      searchByName(trimmed, limit: limit, timeout: timeout)
          .then((res) {
            nameResults = res;
          })
          .catchError((err) {
            nameError = err;
          }),
      searchByTag(trimmed, limit: limit, timeout: timeout)
          .then((res) {
            tagResults = res;
          })
          .catchError((err) {
            tagError = err;
          }),
    ]);

    if (nameResults == null && tagResults == null) {
      if (nameError is RadioBrowserException) {
        throw nameError as RadioBrowserException;
      } else if (tagError is RadioBrowserException) {
        throw tagError as RadioBrowserException;
      } else {
        throw RadioBrowserException(
          'Both name and tag search failed for "$trimmed".',
          nameError ?? tagError,
        );
      }
    }

    final List<dynamic> merged = [];
    final Set<String> seenUuids = {};

    void addRecords(List<dynamic>? list) {
      if (list == null) return;
      for (final item in list) {
        if (merged.length >= limit) break;
        if (item is Map) {
          final uuid = item['stationuuid']?.toString();
          if (uuid != null && uuid.isNotEmpty) {
            if (seenUuids.contains(uuid)) continue;
            seenUuids.add(uuid);
          }
        }
        merged.add(item);
      }
    }

    addRecords(nameResults);
    addRecords(tagResults);

    return merged;
  }

  void dispose() {
    _client.close();
  }
}
