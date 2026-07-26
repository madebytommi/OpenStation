# Open Station Architecture and Technical Decisions

This file tracks major technical decisions for the project.

## Spike 1: Flutter Windows Baseline
* **Date**: 2026-07-19
* **Decision**: Initialize Flutter project with Windows support using Dart 3 and Flutter 3.
* **Reason**: Satisfies the minimum MVP requirement to build a local-first Windows desktop application.
* **Alternatives considered**: None (Flutter/Dart/Windows were frozen in MVP).
* **Consequences**: We now have a compilable, testable baseline app shell.
* **Validation performed**: `flutter doctor -v`, `dart format .`, `flutter analyze`, `flutter test`, `flutter build windows`.

## Spike 2: Radio Browser Connectivity
* **Date**: 2026-07-20
* **Decision**: Use `dart:io` `InternetAddress.lookup('all.api.radio-browser.info')` with reverse DNS fallback and random shuffle for server discovery, coupled with `package:http` (`http.Client`) for standard HTTP queries.
* **Reason**: Prevents permanent dependence on any single hardcoded server, implements client-side load balancing, and adheres to Radio Browser API guidelines.
* **Alternatives considered**: Hardcoded single server (rejected per MVP rules), third-party heavy networking/service locator packages (rejected per Spike 2 constraints).
* **Consequences**: `RadioBrowserService` handles server failover automatically across HTTP requests with explicit timeouts.
* **Validation performed**: Unit tests with `MockClient` for server 500 failover, timeout failover, malformed body handling, empty list handling, and live network DNS lookup test.

## Spike 3: Station Data Normalization
* **Date**: 2026-07-20
* **Decision**: Implement an immutable `Station` model (`lib/models/station.dart`) with factory constructors (`Station.fromJson` and `Station.tryFromJson`) to sanitize API records into predictable domain objects.
* **Normalization rules enforced**:
  * Missing/blank station names default to `'Unknown station'`.
  * Null or blank strings are sanitized so literal `"null"` text never appears.
  * Bitrates $\le 0$ are normalized to `null`.
  * Retain both original `url` and `resolvedUrl` (falling back to `url` if `resolvedUrl` is omitted).
  * Tags are split by comma and normalized into a clean `List<String>`.
* **Validation performed**: Automated offline unit tests in `test/station_model_test.dart` verifying complete metadata, missing names, zero bitrates, unicode support, and corrupted JSON records.


## Spike 4: Windows Audio Package Evaluation
* **Date**: 2026-07-20
* **Decision**: Adopt `media_kit` (and `media_kit_libs_windows_audio`) as the core audio engine. Reject `just_audio`.
* **Reason**: `just_audio` failed the Windows thread constraints and crashed via C++ platform channel threads when initializing standard MP3 streams. `media_kit` cleanly handled audio through its bundled libmpv engine.
* **Important Constraint**: Passing a custom `User-Agent` HTTP header is mandatory for all stream connections in `media_kit` (e.g., `Media(url, httpHeaders: {'User-Agent': 'OpenStation/0.1'})`) to prevent 403 Forbidden/Connection Rejection errors from common radio streaming providers.

## Spike 5: Playback Lifecycle and Cancellation
* **Date**: 2026-07-20
* **Decision**: Refactor player controller into a strict singleton `AudioPlayerService` (`lib/services/audio_player_service.dart`). Always execute `await _player!.stop()` prior to initializing a new stream URL via `_player!.open(...)`.
* **Reason**: Prevents overlapping audio, race conditions, or unhandled threads when the user rapidly changes stations.
* **Validation performed**: Stress test fanning out 3 rapid stream switches with a 200ms delay. Verified no overlapping playback or process deadlocks.

## Spike 6: Network and Windows Lifecycle Behavior
* **Date**: 2026-07-20
* **Decision**: Rely on `media_kit` native mpv error reporting and state transitions for network events.
* **Observed Behavior**:
  * **Windows Lock (`Win + L`)**: Audio continues uninterrupted in the background.
  * **Wi-Fi Disconnect**: Plays briefly from buffer, transitions to `CONNECTING`, then emits FFmpeg error (`0xffffff76` - socket error) and safely transitions to `STOPPED` without freezing, crashing, or entering infinite retry loops.

## Spike 7: Bookmark Persistence
* **Date**: 2026-07-20
* **Decision**: Use standard `dart:io` `File` with atomic writes to a local `bookmarks.json` file in the Application Documents directory (via `path_provider`).
* **Reason**: An embedded database (like SQLite or Isar) is overkill for storing a small list of `< 100` station objects and volume preferences. Atomic `.tmp` file renaming ensures power-loss or thread termination during save will not corrupt the user's primary bookmarks file.

## Spike 11: State Management Fit
* **Date**: 2026-07-20
* **Decision**: Adopt `package:provider` with standard `ChangeNotifier`.
* **Reason**: Cleanly decouples UI widgets from business logic and background services (`AudioPlayerService`, `BookmarkService`) while remaining lightweight and native to Flutter without introducing excessive boilerplate or rigid architectural constraints.
* **Validation performed**: Integrated `MultiProvider` at app root, converted services to `ChangeNotifier`, verified multi-service state changes automatically trigger UI rebuilds via `context.watch`.

## MVP Revision: Scope Governance and SMTC Removal
* **Date**: 2026-07-26
* **Decision**: 
  - Limited Recently Played (up to 10 stations, local only) is approved for version 0.1.
  - Station-provided metadata is approved when available.
  - SMTC/global Windows controls were removed because they were unnecessary to the core journey and added native dependency and packaging complexity.
* **Reason**: Strict boundaries ensure privacy and simplicity. Recently Played and metadata enhance the core loop, but SMTC overhead violates the MVP scope.
* **Consequences**:
  - Rust is no longer required for SMTC.
  - Visual Studio Desktop development with C++ remains required for Flutter Windows builds.
* **Validation performed**: Documentation validation is complete, while implementation-specific validation remains separate.
