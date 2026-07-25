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

void main() {
  testWidgets('AppShell renders sidebar, main view, and player bar', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Open Station'), findsOneWidget);
    expect(find.text('Discover Radio Stations'), findsOneWidget);
    expect(find.text('No station selected'), findsOneWidget);
  });
}
