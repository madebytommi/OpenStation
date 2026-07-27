import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/services/recent_stations_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/app_shell.dart';
import 'package:open_station/ui/pages/about_page.dart';

const testStation = Station(
  uuid: 'station-1',
  name: 'Test Station',
  url: 'https://example.com/original',
  resolvedUrl: 'https://example.com/stream',
  countryCode: 'US',
  tags: ['jazz'],
  codec: 'MP3',
  bitrate: 128,
  isWorking: true,
);

class MockDirectoryController extends DirectoryController {
  @override
  Future<void> loadPopularStations() async {}
}

class SearchResultsDirectoryController extends DirectoryController {
  @override
  List<Station> get stations => const [testStation];

  @override
  String get searchQuery => 'jazz';

  @override
  Future<void> loadPopularStations() async {}
}

class PopularResultsDirectoryController extends DirectoryController {
  @override
  List<Station> get stations => const [testStation];

  @override
  Future<void> loadPopularStations() async {}
}

class FailedSearchDirectoryController extends SearchResultsDirectoryController {
  @override
  String? get errorMessage => 'All directory servers failed.';

  @override
  Future<void> retry() async {}
}

Future<void> pumpAppShell(
  WidgetTester tester, {
  DirectoryController? directoryController,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerService>.value(
          value: AudioPlayerService(),
        ),
        ChangeNotifierProvider<BookmarkService>.value(value: BookmarkService()),
        ChangeNotifierProvider<RecentStationsService>.value(
          value: RecentStationsService(),
        ),
        ChangeNotifierProvider<DirectoryController>.value(
          value: directoryController ?? MockDirectoryController(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.darkTheme, home: const AppShell()),
    ),
  );
}

void main() {
  testWidgets('AppShell renders sidebar, main view, and player bar', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(tester);

    expect(find.text('Open Station'), findsOneWidget);
    expect(find.text('Discover Radio Stations'), findsOneWidget);
    expect(find.text('No station selected'), findsOneWidget);
    expect(find.text('About & Privacy'), findsOneWidget);
  });

  testWidgets('About page is reachable and shows required disclosures', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(tester);

    await tester.tap(find.text('About & Privacy'));
    await tester.pumpAndSettle();

    expect(find.text('About Open Station'), findsOneWidget);
    expect(find.text('Privacy at a glance'), findsOneWidget);
    expect(find.text('Network connections'), findsOneWidget);
    expect(find.text('Now-playing information'), findsOneWidget);
    expect(
      find.textContaining('requires no account and includes no advertising'),
      findsOneWidget,
    );
    expect(find.textContaining('no app-specific analytics'), findsOneWidget);
    expect(
      find.textContaining('Bookmarks, Recently Played, and volume settings'),
      findsOneWidget,
    );
    expect(
      find.textContaining('searches contact the Radio Browser directory'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Audio connects directly to the selected station'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Radio Browser servers, selected stations, station-artwork hosts, and network providers may receive your IP address and other connection information.',
      ),
      findsOneWidget,
    );
    expect(find.text('Listening is not anonymous.'), findsOneWidget);
    expect(
      find.textContaining('does not send Radio Browser click-count'),
      findsOneWidget,
    );
    expect(
      find.textContaining('active station stream supplies it'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Open Station does not use third-party metadata enrichment, lyrics, or cloud listening-history services. Station artwork may be downloaded directly from the favicon URL supplied by Radio Browser.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('About page scrolls at a short desktop window height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: AboutPage()),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final versionText = find.text('Open Station v0.1.0 MVP');
    expect(versionText, findsOneWidget);

    await tester.ensureVisible(versionText);
    await tester.pumpAndSettle();

    expect(versionText, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search results use a vertical list with labelled controls', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(
      tester,
      directoryController: SearchResultsDirectoryController(),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('search-results-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('popular-stations-grid')), findsNothing);
    expect(find.text('Search Results · 1'), findsOneWidget);
    expect(find.text('Test Station'), findsOneWidget);
    expect(find.byTooltip('Play Test Station'), findsOneWidget);
    expect(find.byTooltip('Add Test Station to bookmarks'), findsOneWidget);
    expect(find.byTooltip('Mute'), findsOneWidget);
    expect(find.byTooltip('Play station'), findsOneWidget);
  });

  testWidgets('Popular stations retain the card grid', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(
      tester,
      directoryController: PopularResultsDirectoryController(),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('popular-stations-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-results-list')), findsNothing);
  });

  testWidgets('Search failure preserves prior results and offers Retry', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(
      tester,
      directoryController: FailedSearchDirectoryController(),
    );
    await tester.pump();

    expect(
      find.text('Search failed. Previous results are still shown.'),
      findsOneWidget,
    );
    expect(find.text('Test Station'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-results-list')), findsOneWidget);
  });
}
