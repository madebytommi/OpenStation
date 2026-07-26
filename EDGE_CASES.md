# Open Station — Edge Cases and Failure Behavior

## Purpose

This document defines how Open Station version 0.1 should behave when directory data, audio streams, metadata, local storage, or network conditions are unreliable.

These cases are part of the MVP quality requirements.

The application should fail clearly and recoverably. Expected failures must not crash the app, freeze the interface, remove user bookmarks, or leave playback status inaccurate.

---

## 1. Station Directory Is Unavailable

### Situation

Radio Browser cannot be reached, times out, or returns an invalid response.

### Expected behavior

* Discover shows: **Station directory unavailable**
* A Retry action is available.
* Existing bookmarks remain visible.
* Saved bookmarks may still attempt playback using their stored stream URLs.
* The interface remains responsive.
* The app does not display a blank page.
* The app does not depend permanently on one Radio Browser server.

---

## 2. One Directory Server Fails

### Situation

One Radio Browser API server is unavailable while another is working.

### Expected behavior

* The app attempts another available server.
* The user is not shown an error unless all reasonable attempts fail.
* Retry attempts are limited.
* The app does not enter an infinite retry loop.

---

## 3. Station Is Marked Working but Fails to Play

### Situation

The directory reports a station as working, but the stream is offline or unreachable when selected.

### Expected behavior

* The player shows **Connecting**.
* The connection attempt times out.
* Playback stops cleanly.
* The player shows: **This station is currently unavailable**
* A Retry action is available.
* The station is not automatically removed from bookmarks.
* The player does not remain stuck in Connecting.

---

## 4. Stream URL Redirects or Resolves Differently

### Situation

A stream URL redirects, points to an intermediary URL, or has both original and resolved forms.

### Expected behavior

* Prefer the resolved stream URL when available.
* Use the original URL only as an appropriate fallback.
* Redirects must be limited.
* The app must not enter a redirect loop.
* A failed redirect produces a clear playback error.
* Technical details may be logged for debugging.

---

## 5. Stream URL Points to a Playlist

### Situation

The station URL points to an M3U, PLS, or similar playlist rather than directly to audio.

### MVP behavior

* Play the station only if the selected audio package handles the playlist reliably.
* Otherwise show a clear unsupported-stream error.
* Do not attempt complex playlist parsing unless required by the chosen playback package.
* Do not crash or remain stuck in Connecting.

---

## 6. Unsupported Audio Format

### Situation

A station uses a codec or stream type Open Station cannot play.

### Expected behavior

* The app does not crash.
* Playback stops cleanly.
* Show: **This stream format is not currently supported**
* Show the codec name when known.
* The station remains available in search results and bookmarks.
* The app does not claim support for formats that have not been tested on Windows.

Initial format support should be limited to formats confirmed through manual testing.

---

## 7. User Rapidly Selects Multiple Stations

### Situation

The user selects several stations before earlier connection attempts finish.

### Expected behavior

* Only the most recently selected station may play.
* Previous connection attempts are cancelled.
* Existing playback stops before new playback begins.
* Audio streams never overlap.
* The player always shows the currently selected station.
* A cancelled connection does not later begin playing unexpectedly.

This is a high-priority test case.

---

## 8. Network Is Lost During Playback

### Situation

The internet connection disconnects while a station is playing.

### Expected behavior

* Playback stops or transitions to a failed state.
* Show: **Connection lost**
* A Retry action is available.
* The player does not remain in a false Playing state.
* The app does not retry forever.
* The app does not repeatedly send rapid connection requests to the station.

Manual retry is preferred for version 0.1.

---

## 9. Windows Sleeps, Wakes, or Changes Networks

### Situations to test

* Windows is locked.
* The computer sleeps and wakes.
* Wi-Fi changes.
* Internet disconnects and reconnects.
* A VPN connects or disconnects.

### Expected behavior

After the change, the player must either:

* Continue playback correctly, or
* Stop and show an understandable error.

The player must not:

* Remain falsely marked as Playing
* Start duplicate audio streams
* Leak a connection attempt
* Freeze the application

---

## 10. Station Metadata Is Missing or Invalid

### Possible problems

* Blank station name
* Extremely long station name
* Missing country or region
* Missing codec
* Missing bitrate
* Invalid or meaningless tags
* Unusual Unicode characters
* Incorrect data types
* Unexpected null values

### Expected behavior

* Missing name becomes **Unknown station**.
* Long names truncate visually without altering stored data.
* Missing metadata is omitted rather than shown as `null`.
* Unusual text does not break the layout.
* Metadata problems never prevent playback when the stream itself is valid.
* Invalid records are skipped or normalized safely.

---

## 11. Station Artwork Is Missing or Broken

### Situation

The station has no artwork, the image fails to load, or the URL returns non-image content.

### Expected behavior

* Show the standard Open Station artwork placeholder.
* Do not show a broken-image icon.
* Artwork failure does not affect playback.
* The interface does not repeatedly retry a bad image indefinitely.

---

## 12. Duplicate Station Entries Exist

### Situation

The same real-world station appears more than once with different UUIDs, stream qualities, codecs, or URLs.

### MVP decision

Do not attempt aggressive deduplication.

### Expected behavior

* Treat different station UUIDs as separate entries.
* Prevent bookmarking the exact same UUID more than once.
* Display codec and bitrate when available so entries can be distinguished.
* Do not merge entries based only on similar names.

---

## 13. A Bookmarked Station Changes

### Possible changes

* Station name changes
* Stream URL changes
* Codec changes
* Station disappears from the directory
* Station receives a new UUID
* Directory metadata becomes incomplete

### Expected behavior

* Preserve the locally saved bookmark snapshot.
* Never silently delete the bookmark.
* If metadata refresh succeeds, update appropriate fields.
* If refresh fails, continue showing saved data.
* Continue attempting playback from saved URLs when reasonable.
* A missing directory record does not remove the station from the library.

---

## 14. Bookmark Data Is Corrupted

### Situation

One or more locally saved bookmark records are incomplete, invalid, or unreadable.

### Expected behavior

* One bad record does not prevent the entire bookmark library from loading.
* Valid bookmarks remain available.
* Invalid records are skipped, isolated, or reported safely.
* The app does not crash at startup.
* The user receives a simple message only when action is needed.
* Technical details may be logged.

---

## 15. Duplicate Bookmark Request

### Situation

The user attempts to bookmark a station that is already saved.

### Expected behavior

* Do not create a duplicate record.
* Keep the bookmark in its existing state.
* The bookmark control remains filled.
* No error dialog is required.

---

## 16. Bookmark Is Removed Accidentally

### Situation

The user removes a bookmark.

### Expected behavior

* Remove it immediately.
* Show a temporary Undo action.
* Do not require a confirmation dialog.
* Undo restores the original bookmark data.

---

## 17. HTTP-Only Stream

### Situation

A station uses an unencrypted HTTP audio stream.

### MVP behavior

* Permit playback when supported by the audio package and Windows.
* Do not describe the connection as secure.
* Do not send credentials or user-specific data.
* An unencrypted-stream indicator may be added only if it remains simple and unobtrusive.

Listening to a station is not anonymous. The station and network providers may receive connection information such as the listener’s IP address.

---

## 18. Search Returns No Results

### Situation

No stations match the search.

### Expected behavior

Show:

**No stations found**

**Try a different station name or a broader genre.**

* Do not present this as an application error.
* Keep the search field available.
* Do not clear the user’s search unexpectedly.

---

## 19. Search Request Fails

### Situation

A search request times out or the directory is unreachable.

### Expected behavior

* Keep the search text visible.
* Show: **Search failed**
* Offer Retry.
* Do not replace existing valid results until the new search succeeds.
* Keep bookmarks and player controls available.

---

## 20. Application Closes During Playback or Connection

### Situation

The user closes Open Station while a station is playing or connecting.

### Expected behavior

* Stop and dispose of playback resources.
* Cancel active connection attempts.
* Save bookmarks and volume safely.
* Do not leave audio playing after the application exits.
* Do not corrupt local storage.

---

## 21. Stream Metadata is Missing, Empty, or Corrupted

### Situation

The station stream either provides no now-playing metadata, provides an empty string, or provides malformed text.

### Expected behavior

* The player immediately falls back to displaying the default station location or genre.
* No raw errors, parsing exceptions, or `null` text should appear in the UI.
* Audio playback continues uninterrupted.

---

## 22. Station is Replayed from Recently Played

### Situation

The user plays a station that is already in their local Recently Played list.

### Expected behavior

* The existing station entry is moved to the top of the list.
* A duplicate entry is not created.
* The total list size never exceeds 10.
* Playback begins normally.

---

## Privacy Behavior

Open Station must clearly communicate:

* No account is required.
* No advertising is included.
* No app-specific analytics are included.
* Bookmarks and volume are stored locally.
* Searches contact the station directory.
* Audio connections go directly to the selected station.
* Stations and network providers may observe connection information.

If Open Station sends a Radio Browser click-count notification when playback begins, that behavior must be disclosed.

The app must not claim that listening is anonymous.

---

## General Failure Rules

For all recoverable errors:

* Show a clear human-readable message.
* Explain what the user can do next.
* Offer Retry when retrying is meaningful.
* Keep unrelated parts of the app usable.
* Do not show raw exceptions or stack traces in the main interface.
* Do not retry indefinitely.
* Do not automatically delete user data.
* Do not leave playback state inaccurate.
* Do not crash.
