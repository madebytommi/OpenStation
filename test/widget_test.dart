import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/app_shell.dart';

void main() {
  testWidgets('AppShell renders sidebar, main view, and player bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerService>.value(value: AudioPlayerService()),
          ChangeNotifierProvider<BookmarkService>.value(value: BookmarkService()),
          ChangeNotifierProvider<DirectoryController>.value(value: DirectoryController()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AppShell(),
        ),
      ),
    );

    expect(find.text('Open Station'), findsOneWidget);
    expect(find.text('Discover Radio Stations'), findsOneWidget);
    expect(find.text('No station selected'), findsOneWidget);
  });
}
