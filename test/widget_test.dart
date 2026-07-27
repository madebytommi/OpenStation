import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/services/recent_stations_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/app_shell.dart';

class MockDirectoryController extends DirectoryController {
  @override
  Future<void> loadPopularStations() async {}
}

Future<void> pumpAppShell(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerService>.value(
          value: AudioPlayerService(),
        ),
        ChangeNotifierProvider<BookmarkService>.value(
          value: BookmarkService(),
        ),
        ChangeNotifierProvider<RecentStationsService>.value(
          value: RecentStationsService(),
        ),
        ChangeNotifierProvider<DirectoryController>.value(
          value: MockDirectoryController(),
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
    expect(
      find.textContaining('no app-specific analytics'),
      findsOneWidget,
    );
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
      find.textContaining('may receive your IP address'),
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
  });

  testWidgets('About page scrolls at a short desktop window height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAppShell(tester);
    await tester.tap(find.text('About & Privacy'));
    await tester.pumpAndSettle();

    final versionText = find.text('Open Station v0.1.0 MVP');
    expect(versionText, findsOneWidget);

    await tester.ensureVisible(versionText);
    await tester.pumpAndSettle();

    expect(versionText, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
