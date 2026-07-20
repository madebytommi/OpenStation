# Open Station

**A minimal, local-first, privacy-focused Windows desktop internet radio player.**

Open Station is designed for a single purpose: providing a clean, private way to discover internet radio and build a personal collection of favorite stations. No ads, no accounts, no distractions.

## 📥 Installation

1. Navigate to the **Releases** tab on the right side of this repository page.
2. Download the `OpenStation-v0.1.0-Windows.zip` file from the latest release.
3. Extract the downloaded folder to your desired location on your PC.
4. Double-click `open_station.exe` to launch the application (you can right-click this file and select *Send to > Desktop (create shortcut)* for easy access).

## 🚀 Key Features

* **Focused Core Loop**: Effortlessly navigate through the app's primary workflow: *Discover → Search → Play → Bookmark*.
* **Modern Aesthetic**: Enjoy a spacious, music-first UI featuring a classic Google Play Music-inspired dark theme, complete with calm greens and deep slate blues.
* **Debounced Searching**: Fluid, responsive search that respects API rate limits without sacrificing user experience.
* **Offline-Capable Bookmarks**: Your saved stations and metadata are stored locally. You can access and manage your bookmarks even if the radio directory is temporarily unavailable.
* **Native Windows Integration**: Full support for Windows System Media Transport Controls (SMTC). Control playback using your physical keyboard media keys (Play, Pause, Stop), and view the current station natively inside the Windows volume overlay.

## 🏗️ Tech Stack & Architecture

Open Station is built with a focus on simplicity, reliability, and testability.

* **Framework**: Flutter Desktop (Windows target)
* **Audio Engine**: `media_kit` (powered by `mpv` backend) for robust codec support and stream resilience.
* **State Management**: `provider` utilizing standard `ChangeNotifier` for clean, decoupled logic.
* **Persistence**: Atomic local JSON storage (via `path_provider`) ensuring safe, local-first bookmark saves without a heavy database dependency.
* **OS Hooks**: `smtc_windows` (via `flutter_rust_bridge`) to seamlessly integrate with native Windows APIs.

## 🛠️ Prerequisites & Building

To compile and run Open Station locally, you need the standard Flutter SDK configured for Windows desktop development, plus the Rust toolchain.

1. **Flutter SDK**: Ensure Flutter is installed and Windows desktop support is enabled (`flutter config --enable-windows-desktop`).
2. **Visual Studio**: The "Desktop development with C++" workload is required.
3. **Rust Toolchain**: Because the native SMTC integration relies on `cargokit` and `flutter_rust_bridge`, you **must** have Rust (`cargo`) installed on your system. You can install it via Winget:
   ```powershell
   winget install -e --id Rustlang.Rustup
   ```

Once the prerequisites are met, clone the repository and run the following commands to build and run the project locally:

```bash
flutter pub get
flutter run -d windows
```

### Building for Release

```bash
flutter build windows
```

## 🧪 Testing & QA

Open Station maintains a high standard of reliability. The project features clean static analysis (`flutter analyze`) and a comprehensive suite of 25+ passing unit tests covering core logic, DNS failover, state management, and file-save edge-case handling (`flutter test`).