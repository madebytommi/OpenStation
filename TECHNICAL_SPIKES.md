# Open Station — Technical Spikes

## Purpose

This document defines the technical experiments that must be completed before Open Station’s production architecture and polished interface are treated as settled.

The goal of each spike is to reduce uncertainty early.

A spike is not production code unless it is intentionally reviewed, cleaned up, tested, and accepted for reuse.

The spikes should answer practical questions about:

* Radio Browser reliability
* Windows audio playback
* Stream switching and cancellation
* Bookmark persistence
* Flutter package suitability
* Windows packaging

Do not expand the MVP while completing these experiments.

---

## Spike Rules

Each spike must:

1. Test one clearly defined technical risk.
2. Use the smallest practical implementation.
3. Record the packages and versions used.
4. Record the exact tests performed.
5. Record what worked and what failed.
6. Produce a clear pass, conditional pass, or fail result.
7. Avoid polished UI work.
8. Avoid unrelated refactoring or feature development.
9. Update `DECISIONS.md` when a major technical choice is accepted.

A spike is complete only when its findings are documented.

---

# Spike 1 — Flutter Windows Baseline

## Question

Can the chosen Flutter and Dart environment create, analyze, test, build, and run a basic Windows desktop application reliably?

## Experiment

Create the initial Flutter project with Windows support.

Verify:

* Flutter environment is healthy
* Windows desktop support is enabled
* App launches locally
* Hot reload works
* Window resizing works
* Minimum window size can be enforced if needed
* Dart formatting works
* Static analysis works
* Tests run
* Release build completes

## Required commands

```text
flutter doctor -v
dart format .
flutter analyze
flutter test
flutter build windows
```

## Pass condition

* The app launches on Windows.
* Formatting succeeds.
* Analysis succeeds without unresolved errors.
* Tests run successfully.
* A Windows release build is produced.
* Environment limitations are documented.

## Output

Document:

* Flutter version
* Dart version
* Windows version
* Visual Studio workload status
* Build result
* Known environment warnings

---

# Spike 2 — Radio Browser Connectivity

## Question

Can Open Station reliably connect to Radio Browser without depending permanently on one hard-coded API server?

## Experiment

Build a small service or diagnostic screen that:

* Discovers or obtains available Radio Browser API servers
* Selects a server
* Loads popular stations
* Searches by station name
* Searches by tag
* Uses a descriptive User-Agent
* Applies request timeouts
* Handles malformed responses
* Tries another server when one fails

Do not build the final Discover screen during this spike.

## Test cases

* Successful popular-station request
* Successful station-name search
* Successful tag search
* First server unavailable
* First server times out
* Invalid response body
* Empty response
* All servers unavailable
* Request cancelled before completion

## Pass condition

* Popular stations can be retrieved.
* Search by name works.
* Search by tag works.
* The implementation is not permanently tied to one server.
* A failed server does not crash the app.
* Requests time out predictably.
* All-server failure produces a clean application-level error.

## Findings to record

* Server-discovery method
* Endpoint behavior
* Timeout value tested
* Retry or failover strategy
* Response fields actually needed for the MVP
* Unexpected API inconsistencies
* Rate-limit or usage considerations
* Recommended station model fields

---

# Spike 3 — Station Data Normalization

## Question

Can inconsistent Radio Browser records be converted into safe, predictable application models?

## Experiment

Collect a varied sample of station records containing:

* Complete metadata
* Missing station name
* Missing favicon
* Missing codec
* Missing bitrate
* Long names
* Multiple tags
* Unusual Unicode
* HTTP stream URL
* HTTPS stream URL
* Original and resolved URLs
* Invalid or unexpected values

Create a station-mapping layer that converts API data into an application-level station model.

## Required behavior

* Missing names become `Unknown station`.
* Missing optional values remain optional.
* Null values are not shown as literal text.
* Long names remain stored without breaking the UI model.
* Tags are normalized into a usable list.
* Invalid records are skipped or handled safely.
* Station UUID is used as the primary directory identity.

## Pass condition

* Sample records map without crashes.
* Invalid optional metadata does not block playback.
* Required fields have safe fallback behavior.
* Parsing logic can be tested without live network access.

## Findings to record

* Required model fields
* Optional model fields
* Normalization rules
* Records that must be rejected
* Fields that should not be trusted
* Whether original and resolved stream URLs should both be retained

---

# Spike 4 — Windows Audio Package Evaluation

## Question

Which maintained Flutter audio package provides the most reliable internet-radio playback on Windows?

## Candidate evaluation

Evaluate only serious candidates that:

* Support current Flutter and Dart versions
* Support Windows desktop
* Are actively maintained
* Support remote audio streams
* Expose playback state
* Support stop and volume
* Permit resource cleanup
* Have a compatible license

Do not add several playback packages permanently to the project.

## Stream test set

Test approximately 15–20 stations or controlled URLs covering:

* MP3
* AAC
* AAC+
* Ogg Vorbis
* HTTP
* HTTPS
* Redirected URLs
* Direct audio URLs
* Playlist URLs
* Slow connection
* Broken stream
* Unsupported stream
* Long-running playback

Record each test URL privately in the spike notes or test fixtures as appropriate. Do not treat one successful station as proof of broad codec support.

## Required playback tests

* Start playback
* Stop playback
* Pause and resume, when supported
* Change volume
* Play for at least several minutes
* Handle connection failure
* Handle unsupported format
* Dispose player and reopen it
* Close app during playback
* Build and run in release mode

## Pass condition

The selected package must:

* Reliably play the required initial formats
* Stop cleanly
* Expose accurate state
* Avoid crashes on broken streams
* Work in a Windows release build
* Dispose resources correctly
* Have acceptable package maintenance and licensing

## Decision output

Record in `DECISIONS.md`:

* Selected package
* Package version
* Alternatives considered
* Formats verified
* Formats not verified
* Known limitations
* Native runtime or binary requirements
* Packaging consequences

Do not claim support for formats that were not successfully tested.

---

# Spike 5 — Playback Lifecycle and Cancellation

## Question

Can Open Station guarantee that only the latest selected station plays?

## Experiment

Build a minimal playback controller separate from the final UI.

Test:

* Start one station
* Stop it
* Switch to another station
* Select five stations rapidly
* Select a new station while the previous one is connecting
* Stop while connecting
* Retry after failure
* Disconnect internet during playback
* Reconnect internet
* Close the application while connecting
* Close the application while playing

## Required state model

At minimum, evaluate these states:

* Idle
* Connecting
* Playing
* Paused, if supported
* Stopped
* Failed

The controller must not report Playing when audio has stopped.

## Pass condition

* Only one stream is audible.
* Previous connection attempts are cancelled or made harmless.
* A cancelled stream never begins playing later.
* Switching stations does not leave stale UI state.
* Stop works during Connecting.
* Failures produce a stable Failed state.
* Closing the app disposes playback resources.
* No hanging process remains after exit.

## Findings to record

* Cancellation mechanism
* Sequence or race-condition risks
* State transition rules
* Timeout behavior
* Whether pause is reliable enough for the MVP
* Cleanup requirements
* Package-specific workarounds

---

# Spike 6 — Network and Windows Lifecycle Behavior

## Question

How does playback behave when Windows or the network environment changes?

## Experiment

Test the selected audio implementation under:

* Windows lock
* Sleep
* Wake
* Wi-Fi disconnect
* Wi-Fi reconnect
* Switching networks
* VPN connection
* VPN disconnection
* Internet loss during Connecting
* Internet loss during Playing

## Pass condition

After each event, the player must either:

* Continue playback correctly, or
* Stop and enter a clear failure state

The application must not:

* Freeze
* Play duplicate streams
* Remain falsely marked Playing
* Retry indefinitely
* Leak connection attempts
* Require force termination

## Findings to record

* Actual behavior after sleep and wake
* Whether lifecycle hooks are needed
* Whether playback should be stopped proactively
* Whether manual retry is sufficient
* Any Windows-specific package limitations

---

# Spike 7 — Bookmark Persistence

## Question

What is the simplest reliable way to store bookmarks and volume locally?

## Candidate approach

Prefer a simple local storage method suitable for:

* Bookmark records
* Volume level
* Small data size
* Safe app restart
* Future migrations if needed

Do not introduce a database unless simpler storage proves inadequate.

## Experiment

Test:

* Add a bookmark
* Restart the app
* Load the bookmark
* Remove the bookmark
* Prevent duplicate UUIDs
* Store multiple bookmarks
* Save and restore volume
* Start with no storage file
* Start with an empty storage file
* Start with malformed data
* Include one corrupted bookmark among valid bookmarks
* Simulate interrupted or incomplete write when practical

## Pass condition

* Bookmarks survive restart.
* Volume survives restart.
* Duplicate UUIDs are prevented.
* One bad bookmark does not prevent valid bookmarks from loading.
* Missing storage initializes cleanly.
* Corrupted storage does not crash startup.
* Bookmarks remain visible without directory access.
* No audio starts automatically after launch.

## Decision output

Record in `DECISIONS.md`:

* Selected persistence package or method
* File location
* Storage format
* Corruption-handling behavior
* Write strategy
* Migration approach, if any

---

# Spike 8 — Saved Bookmark Playback During Directory Outage

## Question

Can a saved station remain useful when Radio Browser is unavailable?

## Experiment

1. Load a station from Radio Browser.
2. Save a bookmark snapshot.
3. Close the app.
4. Make the directory unavailable or replace it with a failing test service.
5. Reopen the app.
6. Open Bookmarks.
7. Attempt playback using the stored station data.

## Pass condition

* Bookmark appears without contacting Radio Browser.
* Saved metadata remains available.
* Playback attempts the stored resolved stream URL.
* An appropriate fallback may use the stored original stream URL.
* Directory failure does not block access to Bookmarks.
* Playback failure does not delete the bookmark.

## Findings to record

* Minimum bookmark snapshot fields
* Preferred playback URL
* Fallback URL behavior
* Whether metadata refresh should be deferred until after initial display

---

# Spike 9 — Artwork Failure Handling

## Question

Can station artwork be loaded safely without harming performance or stability?

## Experiment

Test artwork URLs that are:

* Valid images
* Missing
* Empty
* Slow
* Unreachable
* HTML instead of an image
* Very large
* Unusual dimensions
* Repeated across several cards

## Pass condition

* Valid artwork loads.
* Invalid artwork shows the Open Station placeholder.
* Broken artwork does not affect playback.
* The app does not retry failed images indefinitely.
* Large images do not break layout.
* Cards remain stable while artwork loads.

## Findings to record

* Image widget strategy
* Timeout or caching behavior
* Placeholder behavior
* Whether a dedicated image package is necessary

Do not add a package when Flutter’s built-in capabilities are sufficient.

---

# Spike 10 — Search Timing and Cancellation

## Question

Can station search remain responsive without sending unnecessary requests or showing stale results?

## Experiment

Build a minimal search field and test:

* Typing slowly
* Typing quickly
* Clearing the field
* Pressing Enter
* Starting a second search before the first completes
* Search timeout
* Empty results
* Directory failure
* Returning to popular stations after clearing search

## Expected behavior

* Search uses a short debounce.
* Enter may trigger immediately.
* Older results do not replace newer results.
* Search text remains visible after failure.
* Previous valid results may remain visible while a new request runs.
* Clearing search returns to the default Discover state.
* Requests are cancelled or stale responses are ignored.

## Pass condition

* Search remains responsive.
* Request volume is reasonable.
* Stale responses never overwrite newer results.
* Empty results are distinct from errors.
* Search failure does not affect bookmarks or playback.

## Findings to record

* Debounce duration
* Cancellation strategy
* Result limit
* Search endpoint or query method
* Name and tag search behavior

---

# Spike 11 — State Management Fit

## Question

What is the simplest state-management approach that can coordinate discovery, search, bookmarks, and playback without unnecessary complexity?

## Evaluation criteria

The approach must support:

* Asynchronous loading
* Search cancellation
* Playback state updates
* Bookmark changes
* Testable business logic
* Clear ownership of resources
* Disposal
* Understandable code

## Experiment

Implement a small vertical slice containing:

* Popular station loading
* One search request
* One playback action
* One bookmark action
* Persistent player state

Compare complexity, testability, and clarity.

## Pass condition

* One consistent pattern is sufficient.
* UI widgets do not call network, audio, or storage code directly.
* State can be tested without rendering the full app.
* Resource disposal is clear.
* Boilerplate remains proportional to the MVP.

## Decision output

Record:

* Selected approach
* Why it fits
* Alternatives considered
* Rules for where state belongs
* Patterns that should not be mixed into the project

---

# Spike 12 — Windows Packaging and Runtime Dependencies

## Question

Can Open Station be packaged and run on another Windows computer with all required audio dependencies?

## Experiment

Create a release build and test it outside the development workflow.

Verify:

* App launches from the release output
* Audio runtime dependencies are included or clearly installed
* Radio Browser requests work
* Streams play
* Bookmarks persist
* App closes completely
* No development-only paths are required
* Required licenses and notices can be included

When possible, test on a second Windows user account or computer.

## Pass condition

* Release build launches successfully.
* Required playback binaries are present.
* No missing-library errors occur.
* Core MVP flow works in release mode.
* Distribution requirements are documented.
* Package licenses are compatible and attributable.

## Findings to record

* Packaging method
* Installer requirements
* Native libraries
* File size
* Antivirus or SmartScreen observations
* Known machine-specific dependencies
* Steps required for a clean-machine test

---

# Spike Completion Report

At the end of the spike phase, create a short report containing:

## Confirmed decisions

* Audio package
* Verified stream formats
* State-management approach
* Persistence method
* Radio Browser failover method
* Search cancellation method
* Windows packaging method

## Known limitations

List technical limitations that remain accepted for version 0.1.

Examples:

* HLS not supported
* Ogg support inconsistent
* Pause unreliable for live streams
* Some playlist URLs unsupported
* Playback may require manual retry after Windows wakes

## Blocking issues

List anything that prevents the MVP from proceeding.

Do not begin polished UI implementation while a blocking issue remains unresolved.

## Recommended next step

Proceed to production implementation only when these four capabilities are proven:

**Fetch → Play → Switch Safely → Save and Restore**
