Open Station — UI Design System and Wireframe Specification
1. Product Interface Goal
Open Station should feel like a modernized spiritual cousin of the original Google Play Music desktop interface:
•	Spacious
•	Music-first
•	Easy to scan
•	Friendly rather than technical
•	Familiar without copying Google branding
•	Calm greens and blues instead of orange
•	Designed for mouse, keyboard, and touch-friendly Windows use
The interface should prioritize this user flow:
Discover → Search → Play → Bookmark → Reopen → Play Again
The MVP should not feel like a media platform, social network, or advanced radio utility. It should feel like a clean personal station library.
________________________________________
2. Visual Design System
Color Palette
Primary colors
Role	Name	Hex
Primary action	Open Green	#22C55E
Primary hover	Deep Green	#16A34A
Secondary accent	Signal Blue	#3B82F6
Secondary hover	Deep Blue	#2563EB
Dark interface colors
Role	Name	Hex
App background	Midnight	#101820
Sidebar background	Deep Navy	#0B131A
Card background	Slate Surface	#18232D
Raised surface	Raised Slate	#22303C
Divider	Soft Divider	#33414D
Text colors
Role	Hex
Primary text	#F5F7FA
Secondary text	#AAB7C4
Muted text	#758493
Disabled text	#56636E
Status colors
Role	Hex
Playing / connected	#22C55E
Connecting	#60A5FA
Warning	#F59E0B
Error	#EF4444
Color Usage Rules
•	Green is used for play, active playback, bookmarks, and successful states.
•	Blue is used for navigation selection, links, search focus, and secondary actions.
•	Red is reserved for real failures.
•	Avoid gradients in the MVP.
•	Avoid neon green or cyan.
•	Never communicate status through color alone.
•	Selected items should use both color and a visible shape, label, or icon change.
________________________________________
3. Typography
Use a clean system-friendly font.
Recommended font
Inter
Fallback:
Inter, Segoe UI, Arial, sans-serif
Type Scale
Role	Size	Weight
App title	26 px	700
Page heading	24 px	700
Section heading	18 px	600
Station title	16 px	600
Body text	14 px	400
Secondary metadata	13 px	400
Small label	12 px	500
Button text	14 px	600
Typography Rules
•	Station names may wrap to two lines.
•	Metadata should remain one line where practical.
•	Do not use all-caps for large headings.
•	All-caps may be used sparingly for tiny status labels.
•	Long station names should truncate gracefully rather than resize.
________________________________________
4. Spacing and Layout
Use an 8-point spacing system.
Token	Size
XS	4 px
SM	8 px
MD	16 px
LG	24 px
XL	32 px
XXL	48 px
Main Layout
•	Sidebar width: 220 px
•	Collapsed sidebar width: 72 px
•	Top page padding: 24 px
•	Horizontal content padding: 32 px
•	Card gap: 16 px
•	Bottom player height: 88 px
•	Minimum window width: 900 px
•	Minimum window height: 620 px
Breakpoint Behavior
Wide window
•	Full sidebar with labels
•	Station card grid
•	Full player controls
Medium window
•	Narrower cards
•	Sidebar remains visible
•	Metadata may truncate
Small window
•	Sidebar collapses to icons
•	Station grid becomes a list
•	Player hides nonessential metadata
•	Volume may move into a popup
The MVP does not need a mobile layout, but resizing on Windows must not break the interface.
________________________________________
5. Shape and Elevation
Corner Radius
Component	Radius
Search field	12 px
Station card	12 px
Buttons	10 px
Small icon buttons	8 px
Dialogs	16 px
Artwork	10 px
Elevation
Use subtle shadows only.
•	Standard cards: no shadow
•	Hovered cards: slight elevation
•	Player bar: clear top shadow or divider
•	Dialogs: stronger elevation
•	Avoid floating cards everywhere
The interface should feel layered but not glossy.
________________________________________
6. Iconography
Use one consistent icon library.
Recommended:
•	Flutter Material Symbols
•	Rounded style where available
Core icons:
•	Home or explore
•	Bookmark
•	Search
•	Play
•	Pause
•	Stop
•	Volume
•	Volume off
•	Refresh
•	Error
•	Information
•	External link
•	More options
Icon Rules
•	Use filled bookmark when saved.
•	Use outlined bookmark when unsaved.
•	Use tooltips on icon-only buttons.
•	Minimum interactive target: 40 × 40 px.
•	Player buttons may be 44–48 px.
________________________________________
7. Core Components
Navigation Item
Contains:
•	Icon
•	Label
•	Selected indicator
•	Hover background
States:
•	Default
•	Hover
•	Selected
•	Keyboard focus
•	Disabled
Selected appearance:
•	Blue-tinted background
•	Blue icon
•	Clear vertical indicator or pill shape
Search Field
Contains:
•	Search icon
•	Placeholder text
•	Clear button when text is entered
•	Loading indicator during search
Placeholder:
Search stations or genres
States:
•	Default
•	Focused
•	Searching
•	Error
•	Disabled
Behavior:
•	Search begins after a short debounce.
•	Enter starts search immediately.
•	Escape clears focus.
•	Clear button resets results.
Station Card
Contains:
•	Station artwork or placeholder
•	Station name
•	Country, state, or region
•	Primary genre or tag
•	Codec and bitrate
•	Play button
•	Bookmark button
Optional MVP information:
•	“Recently verified”
•	“Unavailable” state
Card states:
•	Default
•	Hover
•	Keyboard focus
•	Selected
•	Playing
•	Connecting
•	Unavailable
Playing appearance:
•	Green play-status indicator
•	Slight green border or accent
•	Play icon becomes pause
Artwork Placeholder
Used when no valid station artwork exists.
Contains:
•	Radio or broadcast icon
•	Two-tone blue-green background
•	Optional station initials
Never show a broken-image icon.
Primary Button
Used for:
•	Retry
•	Confirm
•	Main dialog action
Appearance:
•	Green background
•	White text
•	Strong focus ring
Secondary Button
Used for:
•	Cancel
•	Less important actions
•	External link
Appearance:
•	Raised slate background
•	Light text
•	Blue focus state
Empty State
Contains:
•	Simple icon
•	Short heading
•	One-sentence explanation
•	Optional action
Do not use illustrations in the MVP.
Error State
Contains:
•	Error icon
•	Human-readable message
•	Retry button
•	Optional technical details behind an expandable control
________________________________________
8. Persistent Player Design
The player remains anchored across the bottom of the window after a station has been selected.
Player Layout
Left section
•	Station artwork
•	Station name
•	Location or primary genre (Now-playing track metadata appears here when available, falling back to location/genre if missing. Must truncate to 1 line, never resize the player, and never show raw error strings.)
•	Playback status
Center section
•	Stop
•	Play or pause
•	Retry when failed
Right section
•	Volume icon
•	Volume slider
•	Bookmark button
Player States
No station selected
The player bar is hidden.
Connecting
Show:
•	Spinner
•	“Connecting to station…”
•	Stop button
Playing
Show:
•	Green status indicator
•	“Playing”
•	Pause button
•	Stop button
Paused
Show:
•	“Paused”
•	Play button
•	Stop button
Failed
Show:
•	Error icon
•	Short failure message
•	Retry
•	Stop
Unsupported format
Show:
This station uses a stream format Open Station cannot currently play.
Do not show raw exception text in the main player.
________________________________________
9. Screen-by-Screen Wireframes
Screen 1: Discover
Purpose
Help users immediately find and start playing stations.
Wireframe
┌──────────────────────────────────────────────────────────────────────┐
│ OPEN STATION                                                         │
├───────────────┬──────────────────────────────────────────────────────┤
│               │ Discover                                             │
│  Discover     │                                                      │
│  Bookmarks    │ [ Search stations or genres...              🔍  × ] │
│  About        │                                                      │
│               │ Popular Stations                                     │
│               │                                                      │
│               │ ┌────────────┐ ┌────────────┐ ┌────────────┐         │
│               │ │ Artwork    │ │ Artwork    │ │ Artwork    │         │
│               │ │ Station    │ │ Station    │ │ Station    │         │
│               │ │ Location   │ │ Location   │ │ Location   │         │
│               │ │ Genre      │ │ Genre      │ │ Genre      │         │
│               │ │ ▶      ♡   │ │ ▶      ♡   │ │ ▶      ♡   │         │
│               │ └────────────┘ └────────────┘ └────────────┘         │
│               │                                                      │
├───────────────┴──────────────────────────────────────────────────────┤
│ [Art] Station Name            ■   ▶         🔊 ───────────────  ♡    │
└──────────────────────────────────────────────────────────────────────┘
Required sections
•	Page title
•	Search field
•	Popular Stations
•	Station cards
•	Persistent player when active
Initial loading state
Show six skeleton cards.
Do not display a blank page.
Directory unavailable state
Station directory unavailable

Open Station could not load new stations.
Your bookmarks are still available.

[Retry]
Popular section rules
•	Load approximately 20 stations.
•	Hide stations currently marked as broken.
•	Prefer recognizable metadata.
•	Do not autoplay anything.

Recently Played section rules
•	Appears on the Discover page above or alongside Popular Stations.
•	Uses the standard Station Card design.
•	Ordered most recent first.
•	Must not overpower the search interface.
•	Hidden entirely if the local list is empty.
________________________________________
Screen 2: Search Results
Search results appear within Discover rather than on a separate route.
Wireframe
┌──────────────────────────────────────────────────────────────────────┐
│ Discover                                                             │
│                                                                      │
│ [ alternative rock                                  🔍  × ]          │
│                                                                      │
│ Search Results                                                       │
│ 34 stations found                                                    │
│                                                                      │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ [Art] Station Name                         Alternative · US      │ │
│ │       Tennessee · MP3 · 128 kbps                 ▶       ♡       │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ [Art] Another Station                      College Radio · UK    │ │
│ │       London · AAC · 192 kbps                    ▶       ♥       │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│                         [Load More]                                  │
└──────────────────────────────────────────────────────────────────────┘
Search result layout
Use a roomy vertical list rather than a card grid.
Reasons:
•	Easier to compare metadata
•	Better for keyboard navigation
•	Handles long station names
•	Supports larger result counts
Search states
No results
No stations found

Try a different station name or a broader genre.
Search failure
Search failed

Open Station could not reach the station directory.

[Retry]
Searching
•	Keep previous results visible.
•	Show a small progress indicator in the search field.
•	Replace results only when the new search completes.
________________________________________
Screen 3: Bookmarks
Purpose
Provide immediate access to saved stations.
Wireframe
┌──────────────────────────────────────────────────────────────────────┐
│ Bookmarks                                                            │
│                                                                      │
│ Your saved stations                                                  │
│                                                                      │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐                         │
│ │ Artwork    │ │ Artwork    │ │ Artwork    │                         │
│ │ Station    │ │ Station    │ │ Station    │                         │
│ │ Location   │ │ Location   │ │ Location   │                         │
│ │ Genre      │ │ Genre      │ │ Genre      │                         │
│ │ ▶      ♥   │ │ ▶      ♥   │ │ ▶      ♥   │                         │
│ └────────────┘ └────────────┘ └────────────┘                         │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│ [Art] Station Name            ■   ▶         🔊 ───────────────  ♥    │
└──────────────────────────────────────────────────────────────────────┘
Bookmark behavior
•	Filled green bookmark means saved.
•	Clicking the bookmark removes it.
•	Removal should update immediately.
•	No confirmation dialog is required.
•	A temporary Undo message may appear.
Example:
Station removed from Bookmarks. Undo
Empty bookmark state
No bookmarks yet

Save stations you enjoy and they will appear here.

[Discover Stations]
Offline directory behavior
Bookmarks remain visible even when Radio Browser is unavailable.
The app should still attempt playback using the saved stream URL.
________________________________________
Screen 4: About
Purpose
Explain the app, privacy behavior, and data sources without creating a full settings system.
Wireframe
┌──────────────────────────────────────────────────────────────────────┐
│ About Open Station                                                   │
│                                                                      │
│ Open Station                                                         │
│ Version 0.1.0                                                        │
│                                                                      │
│ Free internet radio without an account.                              │
│                                                                      │
│ Privacy                                                              │
│ • Bookmarks and volume are stored locally.                           │
│ • Searches contact the station directory.                            │
│ • Audio connects directly to the selected station.                   │
│ • Stations may receive your IP address and connection details.       │
│                                                                      │
│ Data Source                                                          │
│ Stations provided through Radio Browser.                             │
│                                                                      │
│ [Open Project Page]     [View Licenses]                              │
└──────────────────────────────────────────────────────────────────────┘
MVP content
Include:
•	App name
•	Version
•	Short product description
•	Privacy explanation
•	Radio Browser attribution
•	Open-source license information
•	Project website or GitHub link when available
Do not create a separate Settings screen yet.
________________________________________
10. Dialogs and Overlays
Remove Bookmark
No confirmation dialog.
Remove immediately and show an Undo snackbar.
Playback Error
Do not open a modal dialog for ordinary stream failures.
Display the error inside the persistent player.
Fatal Application Error
Use a dialog only when the application cannot continue.
Open Station encountered an unexpected problem.

[Copy Error Details] [Close]
Privacy Notice
A full first-run privacy modal is unnecessary for the MVP.
Place the information in About and optionally show a small first-run notice:
Audio connects directly to radio stations. Learn more
________________________________________
11. Motion
Keep motion restrained.
Allowed motion
•	Card hover elevation
•	Bookmark fill animation
•	Player sliding into view
•	Short page transitions
•	Loading spinner
•	Smooth volume movement
Timing
•	Fast interaction: 120–160 ms
•	Page transition: 180–240 ms
•	Player entrance: 200–250 ms
Motion Rules
•	Respect reduced-motion settings where possible.
•	Do not animate the entire station grid.
•	Do not use bouncing equalizers or visualizers in the MVP.
•	Playback state must not depend on animation.
________________________________________
12. Accessibility Requirements
•	All controls must work with keyboard navigation.
•	Tab order should follow the visible layout.
•	Enter or Space activates focused buttons.
•	Search results should be navigable without a mouse.
•	Use a visible blue focus ring.
•	Minimum touch target: 40 × 40 px.
•	Text contrast should meet WCAG AA expectations.
•	Icon-only buttons require tooltips and semantic labels.
•	Playback status must be readable by assistive technology.
•	Error messages should explain what happened and what the user can do.
•	Never rely only on green, blue, or red to communicate state.
________________________________________
13. Flutter Component Structure
Suggested widget breakdown:
OpenStationApp
├── AppShell
│   ├── NavigationSidebar
│   ├── PageContent
│   └── PersistentPlayer
├── DiscoverPage
│   ├── StationSearchField
│   ├── PopularStationsSection
│   ├── SearchResultsList
│   └── DirectoryStatusView
├── BookmarksPage
│   ├── BookmarkGrid
│   └── EmptyBookmarksView
├── AboutPage
├── StationCard
├── StationListTile
├── StationArtwork
├── PlaybackStatus
├── PrimaryButton
├── SecondaryButton
├── EmptyState
├── ErrorState
└── LoadingSkeleton
State separation
UI widgets should receive view-ready state.
They should not directly:
•	Call Radio Browser
•	Open audio streams
•	Read or write bookmark files
•	Perform retry logic
•	Parse API responses
________________________________________
14. MVP Design Rules
The following rules are frozen for version 0.1:
1.	Use one dark theme only.
2.	Use green as the primary action color.
3.	Use blue as the navigation and focus color.
4.	Keep Discover, Bookmarks, and About as the only main navigation destinations.
5.	Keep search inside Discover.
6.	Use station cards for Popular and Bookmarks.
7.	Use a vertical list for Search Results.
8.	Use a persistent bottom player.
9.	Do not add album artwork lookup.
10.	Do not add song metadata displays (except for station-provided now-playing information when available).
11.	Do not add folders, playlists, history, or sorting controls.
12.	Do not add a full Settings screen.
13.	Do not imitate Google Play Music pixel-for-pixel.
14.	Preserve the simple loop:
Discover → Search → Play → Bookmark → Reopen → Play Again
________________________________________
15. Design Definition of Done
The MVP interface is complete when:
•	All four screen states are implemented.
•	Discover loads without a blank state.
•	Search has loading, success, empty, and failure states.
•	Bookmarks have populated, empty, and offline states.
•	The player accurately displays connecting, playing, paused, stopped, and failed states.
•	Every station can be played and bookmarked using either mouse or keyboard.
•	Long names and missing metadata do not break the layout.
•	Broken artwork displays a consistent placeholder.
•	The interface remains usable at the minimum supported window size.
•	Text remains readable at Windows display scaling above 100%.
•	No out-of-scope interface features are present.

