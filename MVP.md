MVP Specification
Product Goal
Build a Windows desktop internet radio app that lets users find a working public radio stream, listen to it, bookmark it, close the app, reopen it, and play the bookmarked station again.
The MVP is complete only when that full loop works reliably.
Target Platform
•	Windows 10 and Windows 11
•	Desktop application
•	Local-first
•	No account required
•	No backend server
•	No cloud sync
•	No AI features inside the app
Primary User Flow
1.	User opens the app.
2.	The app loads a list of popular working stations.
3.	User searches by station name or genre/tag.
4.	User selects a station.
5.	The station begins playing.
6.	User can stop playback or adjust volume.
7.	User bookmarks the station.
8.	User closes and reopens the app.
9.	The bookmark is still present.
10.	User plays the bookmarked station again.
Required Screens
Discover
Must include:
•	Search field
•	Popular stations list
•	Search results
•	Loading state
•	Empty-results state
•	Directory-unavailable state
•	Retry button
Search must support:
•	Station name
•	Genre or tag
Bookmarks
Must include:
•	Saved station list
•	Play button
•	Remove-bookmark button
•	Station name
•	Available location information
•	Main genre or tag
•	Codec and bitrate when known
•	Placeholder artwork when artwork is unavailable
Persistent Player
Must include:
•	Selected station name
•	Play or pause control
•	Stop control
•	Volume control
•	Connecting state
•	Playing state
•	Stopped state
•	Playback-failed state
•	Retry action after failure
Required Features
Station Directory
Use Radio Browser as the directory source.
The app must:
•	Discover or rotate between available Radio Browser servers
•	Avoid permanent dependence on one hard-coded server
•	Load approximately 20 popular stations
•	Return no more than 50 search results at once
•	Prefer stations currently marked as working
•	Use station UUIDs as stable identifiers
•	Use a descriptive User-Agent
•	Handle API timeouts, malformed responses, and unavailable servers
Audio Playback
The app must:
•	Play one stream at a time
•	Stop the previous stream before starting another
•	Prevent overlapping playback
•	Support volume adjustment
•	Display accurate playback state
•	Time out when a stream cannot connect
•	Cancel an earlier connection attempt when the user selects another station
•	Fail cleanly on unsupported or broken streams
Initial supported formats should be limited to those verified during development, prioritizing:
•	MP3
•	AAC or AAC+
•	Ogg Vorbis only if reliably supported
Unsupported formats must show a clear error instead of crashing.
Bookmarks
The app must:
•	Add a station to bookmarks
•	Remove a station from bookmarks
•	Prevent duplicate bookmarks by station UUID
•	Store bookmarks locally
•	Restore bookmarks after restart
•	Keep bookmarks visible when the station directory is offline
•	Never automatically delete a bookmark because a station is temporarily unavailable
Each bookmark should retain a local snapshot containing:
•	Station UUID
•	Station name
•	Original stream URL
•	Resolved stream URL
•	Homepage URL
•	Artwork URL
•	Country code
•	State or region
•	Tags
•	Codec
•	Bitrate
•	Last-known working status
•	Bookmark date
Local Settings
Persist:
•	Bookmarks
•	Volume level


Do not automatically resume audio when the app launches.

Recently Played
The app must:
•	Maintain a rolling list of up to 10 recently played stations.
•	Store the list locally on the user's computer.
•	Add a station only after playback actually begins, not merely when clicked.
•	Place the most recently played station first.
•	Move an existing station to the front instead of creating a duplicate if replayed.
•	Display the section on the Discover page.
•	Retain the list after app restart.
•	Require no account, cloud synchronization, analytics, or external history service.

Station-Provided Now-Playing Metadata
The app must:
•	Display now-playing text supplied directly by the active station stream when available.
•	Support song title, artist/title string, show name, or other stream-provided text.
•	Fall back to normal station information when metadata is missing, empty, malformed, or unavailable.
•	Never let a metadata failure prevent, stop, or affect audio playback.
•	Clear the metadata when the selected station changes, playback stops, or playback fails.
Required Error Handling
The app must handle these cases without crashing:
•	Radio Browser is unavailable
•	One directory server fails
•	Stream is offline
•	Stream connection times out
•	Stream redirects
•	Stream URL points to a playlist
•	Codec is unsupported
•	Artwork URL is broken
•	Station name or metadata is missing
•	Metadata contains unusually long text or unusual Unicode characters
•	User rapidly selects several stations
•	Internet connection is lost during playback
•	Computer sleeps and wakes
•	VPN or network changes during playback
•	One saved bookmark record is invalid or corrupted
Expected behavior:
•	Show a clear human-readable message
•	Stop playback cleanly when necessary
•	Offer Retry where appropriate
•	Never leave the interface permanently stuck in “Connecting”
•	Never display “Playing” when audio is no longer playing
•	Never remove user bookmarks automatically
Privacy Requirements
The app must:
•	Require no user account
•	Include no advertising
•	Include no third-party analytics
•	Store bookmarks and settings locally
•	Clearly state that searches contact the station directory
•	Clearly state that audio connections go directly to the selected station
•	Clearly state that stations may receive the listener’s IP address and connection information
•	Disclose any Radio Browser click-count notification behavior if implemented
Accessibility Requirements
The app must include:
•	Keyboard-accessible controls
•	Visible keyboard focus indicators
•	Proper control labels
•	Sufficient text contrast
•	Text-based playback status
•	No status communicated by color alone
Internal Architecture
Production code must separate these responsibilities:
StationDirectory
Handles:
•	Server discovery
•	Search
•	Popular stations
•	Response mapping
•	Failover
•	Timeouts
AudioPlayer
Handles:
•	Play
•	Pause
•	Stop
•	Volume
•	Connection lifecycle
•	Playback state
•	Errors
BookmarkRepository
Handles:
•	Local bookmark storage
•	Bookmark retrieval
•	Duplicate prevention
•	Corrupted-record handling
ApplicationState
Handles:
•	Selected station
•	Current screen
•	Player state exposed to the interface
•	Coordination between directory, player, and bookmarks
The user interface must not directly contain API, audio, or file-storage logic.
Required Tests
Automated tests must cover:
•	Search response mapping
•	Directory server failover
•	API timeout handling
•	Adding and removing bookmarks
•	Duplicate bookmark prevention
•	Bookmark persistence
•	Corrupted bookmark handling
•	Playback state transitions
•	Switching stations
•	Cancelling an earlier connection
•	Stream failure
•	Directory outage with existing bookmarks
Manual validation must cover:
•	MP3 stream
•	AAC stream
•	Ogg stream if supported
•	HTTP stream
•	HTTPS stream
•	Redirected stream
•	Broken stream
•	Unsupported codec
•	Rapid station switching
•	Network loss
•	Sleep and wake
•	Restart with saved bookmarks
Explicitly Out of Scope
Do not implement these in the MVP:
•	Bookmark folders
•	Full listening history, statistics, most-played rankings, and management features (the rolling Recently Played list is permitted)
•	Custom station URLs
•	M3U or PLS importing
•	Cloud synchronization
•	User accounts
•	Mobile apps
•	Web app
•	macOS or Linux releases
•	Retro theme
•	Multiple themes
•	System tray controls
•	SMTC, global media keys, and Windows volume-overlay integration are outside version 0.1 and have been removed.
•	Notifications
•	Alarm clock
•	Sleep timer
•	Equalizer
•	Audio visualization
•	Recording
•	Casting
•	Location detection
•	Maps
•	Ratings
•	Social features
•	Podcasts
•	External metadata enrichment, artwork lookup, lyrics, and metadata history (station-provided text is permitted)
•	AI recommendations
Definition of Done
Version 0.1.0 is complete when:
•	The app installs and launches on Windows 10 and Windows 11.
•	Popular stations load.
•	Search by station name works.
•	Search by genre or tag works.
•	A supported station plays successfully.
•	Playback can be stopped.
•	Volume control works.
•	Rapid station switching never produces overlapping audio.
•	A station can be bookmarked and removed.
•	Bookmarks survive app restart.
•	Bookmarks remain visible during a directory outage.
•	Saved stations can still attempt playback during a directory outage.
•	Failed streams show a clear error.
•	Bad metadata and artwork do not crash the app.
•	Directory failover works.
•	Core logic has automated tests.
•	The agreed edge-case checklist produces no known crashes.
•	No out-of-scope features have been added.
Scope Rule
Any proposed feature that does not directly improve the following loop must be deferred:
Discover → Search → Play → Bookmark → Reopen → Play Again
