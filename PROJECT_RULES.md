# Open Station — Project Rules

## Purpose

This document defines the engineering and implementation rules for Open Station.

It does not replace the product vision, frozen MVP, design system, or edge-case documents. It controls how the project should be built.

When documents conflict, use this priority order:

1. Frozen MVP
2. Project Rules
3. Product Vision
4. UI Design System
5. Edge-Case Notes

The Frozen MVP is the final authority on version 0.1 scope.

---

## Product Scope Rule

Every implementation decision must support the core MVP journey:

**Discover → Search → Play → Bookmark → Reopen → Play Again**

Features that do not directly improve this journey must be deferred unless they are required for stability, accessibility, security, testing, or Windows compatibility.

Do not silently add features outside the Frozen MVP.

---

## Recently Played Boundaries

The Recently Played feature is permitted, but strictly limited:
* It must store no more than 10 stations.
* Data must remain entirely local.
* It must not track listening durations, play counts, or transmit history to any external analytics or tracking service.
* It must not be expanded into a full history manager.

---

## Metadata Boundaries

Now-playing stream metadata is permitted, but strictly limited:
* It must only use text directly provided by the active stream connection.
* It must not contact external APIs for lyrics, album artwork, or artist biographies.
* It must fail safely (falling back to default station information) if the stream metadata is missing or corrupted.

---

## Windows Integration Boundary

Do not add or restore global Windows media controls (SMTC) or volume-overlay integration during the MVP compliance pass unless the frozen MVP is explicitly revised again. They are strictly out of scope for version 0.1.

---

## Frozen Technical Direction

Open Station will use:

* Flutter
* Dart
* Windows as the first supported platform
* Radio Browser as the station-directory source
* Local-only storage for bookmarks and settings
* One active audio stream at a time
* A simple Google Play Music-inspired interface using greens and blues

Open Station version 0.1 will not require:

* A backend server
* User accounts
* Cloud synchronization
* Advertising
* Analytics
* AI features inside the application
* Mobile support
* Web support
* macOS or Linux packaging

Do not introduce infrastructure for these deferred features.

---

## Simplicity Rule

Prefer the simplest implementation that reliably satisfies the Frozen MVP.

Do not introduce abstraction solely because it may be useful in a hypothetical future version.

Avoid:

* Premature optimization
* Speculative architecture
* Generic framework layers
* Unnecessary dependency injection
* Excessive interfaces
* Complex plugin systems
* Custom design-system frameworks
* Multiple state-management systems
* Multiple persistence systems
* A database when a simpler local format is sufficient
* Rewriting working code only to make it more elegant

Complexity must solve a current, demonstrated problem.

---

## Architecture Boundaries

Keep these responsibilities separated:

### Station Directory

Responsible for:

* Discovering available Radio Browser servers
* Loading popular stations
* Searching stations
* Handling API timeouts
* Handling server failover
* Parsing and normalizing directory responses
* Returning application-level station models

### Audio Playback

Responsible for:

* Starting playback
* Pausing playback when supported
* Stopping playback
* Switching stations
* Volume
* Connection timeout
* Playback status
* Playback errors
* Cancelling an earlier playback request
* Ensuring only one stream plays at a time

### Bookmark Storage

Responsible for:

* Adding bookmarks
* Removing bookmarks
* Preventing duplicate bookmarks
* Saving bookmarks locally
* Restoring bookmarks
* Preserving bookmark snapshots
* Handling invalid or corrupted saved records safely

### Application State

Responsible for:

* Current screen
* Search state
* Search results
* Selected station
* Playback state exposed to the UI
* Bookmark state exposed to the UI
* Coordination between services

### User Interface

Responsible for:

* Rendering application state
* Accepting user input
* Displaying loading, empty, success, and failure states
* Accessibility
* Responsive Windows layouts

UI widgets must not directly:

* Call Radio Browser endpoints
* Parse API responses
* Control native audio libraries
* Read or write local files
* Implement retry loops
* Contain business rules

---

## Code Organization

Use clear feature and responsibility boundaries.

A reasonable starting structure is:

```text
lib/
├── app/
│   ├── app.dart
│   ├── app_shell.dart
│   └── app_state.dart
├── models/
│   ├── station.dart
│   └── bookmark.dart
├── services/
│   ├── station_directory_service.dart
│   └── audio_player_service.dart
├── repositories/
│   └── bookmark_repository.dart
├── screens/
│   ├── discover/
│   ├── bookmarks/
│   └── about/
├── widgets/
│   ├── station_card.dart
│   ├── station_list_tile.dart
│   ├── station_artwork.dart
│   └── persistent_player.dart
└── theme/
    ├── app_colors.dart
    ├── app_spacing.dart
    └── app_theme.dart
```

This structure is a starting point, not a requirement to create empty folders or unnecessary files.

Do not create layers that have no real responsibility.

---

## File Size and Responsibility Rules

Prefer small, focused files.

Avoid:

* Giant screen files
* Giant application-state classes
* Giant service classes
* Utility files containing unrelated functions
* Models that also perform network, storage, or UI work
* Widgets that own business logic

When a file becomes difficult to understand or test, split it by responsibility.

Do not split files merely to meet an arbitrary line count.

---

## Flutter Package Rules

Before adding a package:

1. Confirm that it supports current Flutter and Dart versions.
2. Confirm that it supports Windows desktop.
3. Check whether it is actively maintained.
4. Review open issues related to Windows.
5. Confirm that its license is compatible with the project.
6. Confirm that it solves a current MVP requirement.
7. Prefer a well-maintained package over a less common package with more features.
8. Avoid adding multiple packages that solve the same problem.

Document important package choices in `DECISIONS.md`.

Do not choose packages solely because they appear in old tutorials, generated examples, or remembered code snippets.

---

## Audio Rules

Audio behavior is a high-risk area and must be handled carefully.

The application must:

* Play only one station at a time
* Stop or cancel the previous stream before starting another
* Prevent overlapping audio
* Represent playback status accurately
* Avoid remaining permanently in a Connecting state
* Avoid displaying Playing after playback has stopped
* Handle stream failure without crashing
* Handle unsupported formats without crashing
* Allow the user to retry
* Dispose of playback resources correctly
* Handle rapid station switching
* Handle application shutdown during connection or playback

Do not claim support for a codec or stream type until it has been tested on Windows.

---

## Networking Rules

All network operations must:

* Use explicit timeouts
* Handle cancellation where practical
* Handle malformed responses
* Handle unavailable servers
* Avoid infinite retry loops
* Avoid blocking the UI thread
* Return human-readable failure states
* Log useful technical details without exposing them in the main interface

Radio Browser access must not depend permanently on one hard-coded API server.

Use a descriptive application User-Agent where supported.

Do not send unnecessary user data.

---

## Persistence Rules

Version 0.1 should use the simplest reliable local storage approach.

Persist only what the MVP requires:

* Bookmarks
* Volume level

Do not add a database unless simpler storage proves insufficient.

Bookmark storage must:

* Survive application restart
* Preserve enough station information to remain visible during a directory outage
* Avoid deleting bookmarks automatically
* Prevent exact duplicate bookmarks by station UUID
* Skip or isolate corrupted records instead of failing the entire library

Do not autoplay audio when the app launches.

---

## State-Management Rules

Use one state-management approach consistently.

The chosen approach should:

* Be understandable
* Be testable
* Support asynchronous loading and cancellation
* Avoid global mutable state
* Avoid excessive boilerplate
* Fit the size of the MVP

Do not introduce multiple competing patterns.

Do not create abstractions for hypothetical future features.

---

## UI Rules

The UI must follow the approved design-system document.

Version 0.1 must use:

* One dark theme
* Green for primary actions and active playback
* Blue for navigation, focus, and secondary emphasis
* Discover, Bookmarks, and About as the only main destinations
* Search inside Discover
* Station cards for Popular and Bookmarks
* A vertical list for Search Results
* A persistent bottom player

Do not reproduce Google Play Music exactly.

Use it only as inspiration for:

* Layout
* Spacing
* Navigation
* Card presentation
* Information hierarchy
* Persistent playback controls

Do not add visual effects that are outside the MVP.

---

## Accessibility Rules

Accessibility is part of the MVP.

The app must include:

* Keyboard-accessible controls
* Logical tab order
* Visible focus states
* Semantic labels
* Tooltips for icon-only controls
* Text-based playback status
* Sufficient contrast
* Minimum practical control sizes
* Layouts that remain usable with Windows display scaling

Do not communicate state through color alone.

---

## Error-Handling Rules

Expected failures must not crash the application.

Handle:

* Directory outage
* Directory timeout
* Malformed directory response
* Broken station stream
* Unsupported codec
* Redirect failure
* Broken station artwork
* Missing station metadata
* Rapid station switching
* Network loss
* Sleep and wake
* VPN or network changes
* Corrupted bookmark data

For recoverable errors:

* Show a clear message
* Explain what the user can do
* Provide Retry where appropriate
* Keep unrelated parts of the application usable

Do not show raw stack traces or exception objects in the main UI.

Technical error details may be logged for debugging.

---

## Testing Rules

Add tests alongside meaningful logic.

Automated tests should cover at minimum:

* Station response parsing
* Search result mapping
* Directory timeout handling
* Directory failover
* Adding bookmarks
* Removing bookmarks
* Duplicate bookmark prevention
* Bookmark persistence
* Corrupted bookmark handling
* Playback state transitions
* Switching stations
* Cancelling a previous playback attempt
* Playback failure
* Directory outage with existing bookmarks

Manual testing must include:

* MP3 stream
* AAC stream
* Ogg stream if supported
* HTTP stream
* HTTPS stream
* Redirected stream
* Broken stream
* Unsupported format
* Rapid station switching
* Network loss
* Sleep and wake
* App restart with saved bookmarks
* Windows display scaling above 100%

Do not treat compilation as proof that a feature works.

---

## Validation Rules

After each meaningful implementation phase, run:

```text
dart format .
flutter analyze
flutter test
```

Before declaring a Windows milestone complete, also run an appropriate Windows build.

Do not ignore analysis warnings without documenting why.

Do not report a validation step as successful unless it was actually executed.

If a required validation step cannot run in the current environment, state that clearly.

---

## Implementation Order

Build the project as small vertical slices.

Recommended order:

1. Create the Flutter Windows project.
2. Establish the basic app shell and theme.
3. Validate Radio Browser access.
4. Validate Windows audio playback with test streams.
5. Validate stop, switching, and cancellation.
6. Implement the station model and directory service.
7. Implement popular stations.
8. Implement search.
9. Implement bookmark persistence.
10. Connect the Discover, Bookmarks, and player UI.
11. Add error, loading, and empty states.
12. Add automated tests.
13. Perform edge-case validation.
14. Package the Windows MVP.

Do not build the polished interface before validating directory access and audio playback.

---

## Change Rules

Before changing a frozen requirement:

1. Identify the exact requirement.
2. Explain why the change is necessary.
3. Explain the impact on scope, architecture, testing, and schedule.
4. Propose the smallest possible change.
5. Wait for approval before implementing it.

Do not reinterpret a difficult requirement as optional.

Do not silently remove requirements because a package does not support them.

Do not expand the MVP to work around an implementation problem.

---

## Refactoring Rules

Refactoring is allowed when it:

* Fixes a demonstrated problem
* Improves testability
* Removes duplication
* Clarifies responsibility
* Reduces bugs
* Is required for the next approved MVP step

Before large refactors:

* Confirm the current behavior with tests
* Keep the change focused
* Avoid mixing refactoring with unrelated feature work
* Re-run formatting, analysis, and tests

Do not rewrite functioning areas solely because a different architecture is fashionable.

---

## Documentation Rules

Keep documentation concise and current.

Maintain:

* `README.md`
* `PROJECT_RULES.md`
* Frozen product documents
* `DECISIONS.md` after meaningful technical decisions begin
* Basic setup and validation instructions

Update documentation when behavior, setup, dependencies, or architecture materially changes.

Do not create large documents that repeat existing requirements.

---

## Decision Log

Create or update `DECISIONS.md` when making an important technical choice.

Each entry should include:

```text
Date:
Decision:
Reason:
Alternatives considered:
Consequences:
Validation performed:
```

Record decisions such as:

* Audio package
* State-management approach
* Persistence method
* API server-discovery method
* Packaging method
* Supported audio formats

Do not revisit a recorded decision without new evidence.

---

## Security and Privacy Rules

Open Station must:

* Require no account
* Include no analytics
* Include no advertising
* Store bookmarks locally
* Avoid collecting personal data
* Avoid unnecessary permissions
* Avoid logging sensitive local information
* Explain that searches contact the station directory
* Explain that audio connects directly to stations
* Explain that stations may receive connection information such as IP address

Do not claim that internet radio listening is anonymous.

---

## Definition of Responsible Completion

A task is complete only when:

* The approved behavior is implemented.
* Relevant error states are handled.
* Relevant tests are added or updated.
* Formatting passes.
* Analysis passes or remaining findings are documented.
* Tests pass.
* The application still follows the Frozen MVP.
* No unrelated features were added.
* Documentation is updated when necessary.

The goal is not to generate the most code.

The goal is to build the smallest reliable version of Open Station.
