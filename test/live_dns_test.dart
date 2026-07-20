import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/services/radio_browser_service.dart';

void main() {
  test(
    'Live Radio Browser DNS & API Connectivity Test',
    () async {
      final service = RadioBrowserService();

      // 1. Discover servers via DNS
      final servers = await service.discoverServers();
      debugPrint('Discovered servers: $servers');
      expect(servers, isNotEmpty);

      // 2. Fetch popular stations
      final popular = await service.getPopularStations(limit: 5);
      debugPrint('Popular stations count: ${popular.length}');
      expect(popular, isNotEmpty);

      debugPrint('RAW STATION JSON SAMPLE:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(popular.first));

      // 3. Search by name
      final bbc = await service.searchByName('BBC', limit: 5);
      debugPrint('BBC search count: ${bbc.length}');
      expect(bbc, isNotEmpty);

      // 4. Search by tag
      final jazz = await service.searchByTag('jazz', limit: 5);
      debugPrint('Jazz search count: ${jazz.length}');
      expect(jazz, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
