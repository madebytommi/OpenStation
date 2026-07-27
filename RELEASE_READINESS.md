# Open Station v0.1.0 Release Readiness

**Audit date:** July 27, 2026  
**Target:** Windows 10 and Windows 11  
**Source version:** `0.1.0+1`

## Current decision

**AUTOMATED GATES PASSED — READY FOR FINAL WINDOWS MANUAL TESTING**

The feature scope for v0.1.0 is frozen. No additional product features should be added during this pass. A `v0.1.0` tag and packaged release should be created only after:

1. Every automated gate below passes on the release branch.
2. The manual Windows checklist is completed on the packaged candidate.
3. No release-blocking finding remains open.

## Governing-document audit

| Source | Status | Evidence |
| --- | --- | --- |
| `VISION.md` | Implemented | Discover, name/tag search, playback, local bookmarks, reopen persistence, and play-again behavior are represented in the application and automated tests. |
| `MVP.md` | Implemented with manual gates remaining | Core services, persistence, Recently Played, stream metadata, directory failover, timeout handling, and latest-selection-wins playback have deterministic coverage. Windows stream-format and lifecycle scenarios remain manual. |
| `PROJECT_RULES.md` | Implemented | Flutter/Dart/Windows direction, one active stream, local JSON storage, Provider state management, UI/service separation, and scope boundaries remain intact. |
| `DESIGN_SYSTEM.md` | Implemented for release scope | One dark theme, green/blue hierarchy, three destinations, persistent player, popular-station grid, and vertical search-results list are present. |
| `EDGE_CASES.md` | Automated core covered; environment cases remain manual | Directory failure, malformed data, rapid switching, timeout/fallback, bookmark corruption, and metadata failure have automated coverage. Sleep/wake, network changes, and real stream formats require Windows testing. |
| `TECHNICAL_SPIKES.md` and `DECISIONS.md` | Consistent | Radio Browser, `media_kit`, Provider, and local JSON decisions match the current dependencies and implementation. |
| `README.md` | Corrected | Version, build output, release availability, privacy claims, and deterministic test instructions now describe the repository honestly. |

## Release blockers repaired in this branch

### Version identity

- Changed the Flutter package version from `1.0.0+1` to `0.1.0+1`.
- Replaced the default Flutter package description with an Open Station description.
- Kept the UI, Radio Browser User-Agent, documentation, and intended release name aligned to v0.1.0.

### Search presentation and failure continuity

- Search and tag results now render as a vertical list.
- Popular stations remain a card grid.
- Existing valid results remain visible while a new request is loading.
- A failed refresh shows a Retry action without discarding previously loaded results.
- A complete directory outage still shows the full unavailable state and Retry action.

### Accessibility and explicit retry behavior

- Added labels/tooltips to station play, pause, resume, retry, bookmark, mute, unmute, and persistent-player controls.
- The failed persistent-player action now uses a Retry icon and Retry label rather than appearing as ordinary Play.
- The volume slider exposes a percentage description to assistive technology.
- The connecting indicator exposes live semantic status.

### Release documentation

- Removed the implication that a packaged release already exists.
- Documented the complete-folder requirement for portable Windows builds.
- Removed a fixed test-count claim that would become stale.
- Documented the deterministic suite and the exclusion of the live DNS test.

## Automated release gates

The branch workflow passed all of the following:

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- Focused release widget tests
- Complete deterministic test suite
- Scope and repository-hygiene checks
- Windows release build
- Candidate ZIP creation and artifact upload

**Automated result:** PASSED on GitHub Actions with Flutter 3.44.6. The uploaded artifact is named `OpenStation-v0.1.0-Windows`, is approximately 20.3 MB, and has SHA-256 digest `6c5d4e4469cf34d8a836db437de56494db44fbeef1b83f1444c822028450dd05`.

## Scope and repository-hygiene requirements

The final tree must contain:

- No tracked `build/` or `dist/` output
- No Rust source or generated bridge artifacts
- No `smtc_windows` or `flutter_rust_bridge` dependency or production reference
- No global media-control or Windows volume-overlay integration
- No analytics or telemetry dependency
- No account, backend, or cloud-sync infrastructure
- No Radio Browser station-click notification call
- No external metadata enrichment, artwork lookup, lyrics, or listening-history service

## Manual Windows release checklist

Complete these checks using the packaged release candidate rather than `flutter run`.

### Installation and launch

- [ ] Extract the entire candidate ZIP on Windows 10.
- [ ] Launch `open_station.exe` successfully on Windows 10.
- [ ] Extract the entire candidate ZIP on Windows 11.
- [ ] Launch `open_station.exe` successfully on Windows 11.
- [ ] Confirm no development SDK is required on the test machine.
- [ ] Confirm the app does not autoplay at launch.

### Core journey

- [ ] Popular stations load.
- [ ] Search by station name works.
- [ ] Search by genre or tag works.
- [ ] Search results appear as a vertical list.
- [ ] A working station begins playing.
- [ ] Stop works.
- [ ] Pause and resume work.
- [ ] Volume and mute work.
- [ ] A station can be bookmarked and removed.
- [ ] Recently Played updates only after playback begins.
- [ ] Close and reopen the app.
- [ ] Bookmarks, Recently Played, and volume persist.
- [ ] A saved station can be played again after restart.

### Stream and network behavior

- [ ] MP3 stream plays.
- [ ] AAC or AAC+ stream plays.
- [ ] Ogg stream is tested and claimed only if it works reliably.
- [ ] HTTP stream behavior is verified.
- [ ] HTTPS stream behavior is verified.
- [ ] Redirected/resolved stream behavior is verified.
- [ ] Broken stream reaches a clear Failed state.
- [ ] Unsupported stream fails without crashing or remaining in Connecting.
- [ ] Rapid A→B→C switching produces only the latest station and no overlapping audio.
- [ ] Stop during Connecting cancels the attempt.
- [ ] Network loss during playback does not leave a false Playing state.
- [ ] Sleep and wake do not freeze the app or create duplicate audio.
- [ ] Wi-Fi or VPN changes do not freeze the app or create duplicate audio.

### Persistence and offline behavior

- [ ] Bookmarks remain visible while Radio Browser is unavailable.
- [ ] A saved station still attempts playback while Radio Browser is unavailable.
- [ ] A malformed bookmark file is preserved under a recovery filename.
- [ ] New bookmarks save and reload after damaged-file recovery.
- [ ] One invalid record does not hide valid bookmarks.

### Interface and accessibility

- [ ] Discover, Bookmarks, and About & Privacy are keyboard reachable.
- [ ] Focus indicators are visible.
- [ ] Playback state is communicated by text as well as color.
- [ ] Icon-only controls expose useful tooltips.
- [ ] The sidebar and About page remain usable at short window heights.
- [ ] The interface remains usable above 100% Windows display scaling.

## Known non-blocking limitations

- Station availability and directory metadata are controlled by third parties and may change without warning.
- The audio backend does not reliably classify every native failure as a specific codec error; failures are normalized into stable user-facing messages.
- The Windows distribution is a portable folder archive rather than an installer.
- The Undo behavior described for bookmark removal in `EDGE_CASES.md` is not part of the higher-priority frozen MVP requirements and remains deferred.
- The live DNS test is intentionally outside the deterministic release gate because it depends on the external network.

## Release action after sign-off

After every required checkbox is complete:

1. Merge this branch.
2. Confirm `main` is green and clean.
3. Create the annotated tag `v0.1.0` from the approved `main` commit.
4. Publish `OpenStation-v0.1.0-Windows.zip` with concise release notes and the known limitations above.
5. Perform one final download-and-launch check using the published asset.
