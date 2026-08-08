# Open Station

**A minimal, local-first, privacy-focused Windows desktop internet radio player.**

Open Station provides a clean way to discover public internet radio, listen, save favorite stations, and return to them later. It requires no account and includes no app-specific advertising, cloud synchronization, or app-specific analytics. Individual radio stations may include their own broadcast advertising.

## Release status

The source is currently aligned to **v0.1.0+1**. A packaged v0.1.0 release is available.

To run the release:

1. Open the repository's **Releases** page.
2. Download `OpenStation-v0.1.0-Windows.zip`.
3. Extract the complete archive to a folder on your PC.
4. Launch `open_station.exe` from the extracted folder.

Do not move only the executable; the adjacent runtime files are required.

## Key features

- **Focused core loop:** Discover → Search → Play → Bookmark → Reopen → Play Again
- **Name and genre search:** Searches station names and Radio Browser tags
- **Local bookmarks:** Saved station snapshots remain available when the directory is offline
- **Recently Played:** Maintains a local rolling list of up to 10 stations
- **Station-provided metadata:** Displays now-playing text supplied by the active stream when available
- **Playback resilience:** Uses connection timeouts, resolved-to-original URL fallback, and latest-selection-wins switching
- **Privacy disclosures:** Explains directory requests, direct station connections, and local data storage inside the app

## Privacy and network behavior

- Searches contact Radio Browser servers.
- Audio connects directly to the selected station’s stream host.
- Station artwork may be downloaded from the favicon URL supplied by Radio Browser.
- Radio Browser servers, selected stations, station-artwork hosts, and network providers may receive your IP address and other connection information.
- Listening is not anonymous.
- Bookmarks, Recently Played, and volume settings remain local to the computer.
- Open Station does not send Radio Browser click-count notifications.

## Tech stack

- **Framework:** Flutter Desktop, targeting Windows
- **Language:** Dart
- **Directory:** Radio Browser
- **Audio engine:** `media_kit` with the bundled Windows audio libraries
- **State management:** `provider` and `ChangeNotifier`
- **Persistence:** Atomic local JSON storage using `dart:io` and `path_provider`

## Building from source

You need the Flutter SDK configured for Windows desktop development and Visual Studio with the **Desktop development with C++** workload.

```powershell
flutter pub get
flutter run -d windows
```

Build a release candidate with:

```powershell
flutter build windows
```

The Windows output is produced under:

```text
build/windows/x64/runner/Release/
```

## Testing

Run the deterministic automated suite with:

```powershell
flutter test test/bookmark_model_test.dart `
  test/bookmark_service_test.dart `
  test/radio_browser_service_test.dart `
  test/recent_stations_service_test.dart `
  test/station_model_test.dart `
  test/widget_test.dart `
  test/directory_controller_test.dart `
  test/audio_player_service_test.dart
```

`test/live_dns_test.dart` performs a real network lookup and is intentionally excluded from the deterministic release gate.