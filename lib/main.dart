import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:provider/provider.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/services/audio_player_service.dart';
import 'package:open_station/services/bookmark_service.dart';
import 'package:open_station/theme/app_theme.dart';
import 'package:open_station/ui/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await SMTCWindows.initialize();

  final audioService = AudioPlayerService();
  await audioService.init();

  final bookmarkService = BookmarkService();
  await bookmarkService.init();

  // Load stored volume setting into player service
  audioService.setVolume(bookmarkService.lastVolume);

  final directoryController = DirectoryController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerService>(create: (_) => audioService),
        ChangeNotifierProvider<BookmarkService>(create: (_) => bookmarkService),
        ChangeNotifierProvider<DirectoryController>(create: (_) => directoryController),
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
