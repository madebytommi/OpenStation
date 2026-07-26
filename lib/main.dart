import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:provider/provider.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/services/recent_stations_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final audioService = AudioPlayerService();
  await audioService.init();

  final bookmarkService = BookmarkService();
  await bookmarkService.init();

  final recentStationsService = RecentStationsService();
  await recentStationsService.init();

  // Load stored volume setting into player service
  audioService.setVolume(bookmarkService.lastVolume);

  final directoryController = DirectoryController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerService>(create: (_) => audioService),
        ChangeNotifierProvider<BookmarkService>(create: (_) => bookmarkService),
        ChangeNotifierProvider<RecentStationsService>(
          create: (_) => recentStationsService,
        ),
        ChangeNotifierProvider<DirectoryController>(
          create: (_) => directoryController,
        ),
      ],
      child: MaterialApp(
        title: 'Open Station',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    ),
  );
}
