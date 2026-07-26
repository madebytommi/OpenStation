# Open Station — Product Vision

## Overview

Open Station is a simple desktop application for discovering and listening to free internet radio stations from around the world.

It helps users search a large public station directory, begin listening quickly, bookmark stations they enjoy, and return to those stations later.

Open Station is not intended to be a social network, podcast platform, music-streaming subscription service, or personalized recommendation engine. It is a clean, private radio directory and player.

## Core Experience

The central Open Station experience is:

**Discover → Search → Play → Bookmark → Reopen → Play Again**

A user should be able to:

1. Open the application.
2. Browse a useful selection of stations.
3. Search by station name or genre.
4. Start listening with minimal friction.
5. Bookmark a station.
6. Find and play that station again later.

The application should make a large and inconsistent internet-radio directory feel approachable without overwhelming the user.

## Product Values

### Simple

Open Station should remain easy to understand.

The interface should prioritize station discovery, playback, and bookmarks. Features should not be added merely because other media applications include them.

### Open

The application should provide access to publicly available internet radio without requiring a subscription or proprietary media catalog.

Open Station connects users to independent, community, public, college, commercial, and international stations that already broadcast online.

### Private

Open Station should require no user account.

Bookmarks and preferences should remain on the user’s device. The application should include no advertising, behavioral profiling, or third-party analytics.

The application must clearly explain that searches contact the station directory and that audio connections go directly to the selected station.

### Reliable

Internet-radio data is imperfect. Stations may be offline, mislabeled, duplicated, missing artwork, or using unsupported stream formats.

Open Station should handle these conditions honestly and gracefully. Failures should produce understandable messages rather than crashes, frozen interfaces, or misleading playback states.

### Personal

Bookmarks should be a central part of the experience.

The goal is not only to expose users to thousands of stations. The goal is to help each user build a small, useful personal collection of stations worth returning to.

### Friendly

Open Station should feel welcoming rather than technical.

Users should not need to understand codecs, stream URLs, playlist formats, or directory infrastructure simply to listen. Technical details may be shown when useful, but they should not dominate the interface.

## Discovery Philosophy

Users should find stations through straightforward tools rather than algorithmic personalization.

Open Station may use:

* Popular station listings
* Station-name search
* Genre or tag search
* Clear station metadata
* Simple browsing tools in future versions

Search and browsing should tolerate imperfect community-supplied metadata where practical, but Open Station should not claim to understand a user’s tastes or build behavioral profiles.

There will be no AI recommendation system inside the application.

## Visual Direction

Open Station will use a spacious, music-first interface inspired by the clarity and organization of the former Google Play Music desktop experience without copying its branding or design exactly.

The visual identity will use:

* Greens for primary actions, bookmarks, and active playback
* Blues for navigation, focus, and secondary emphasis
* A dark, calm desktop interface
* Prominent search
* Clear station cards and lists
* A persistent playback area
* Minimal visual clutter

The application should feel familiar, relaxed, and slightly nostalgic while remaining modern and accessible.

## Initial Platform Direction

Open Station will initially be built as a Windows desktop application using Flutter and Dart.

The first release will be local-first and will not require:

* A backend server
* User accounts
* Cloud synchronization
* Advertising
* Analytics
* AI features
* Mobile or web versions

Future platform expansion may be considered only after the Windows application is stable and useful.

## Long-Term Direction

Future versions may improve how users browse, organize, import, and manage stations.

Possible future areas include:

* Browsing by genre, country, region, or language
* Bookmark organization
* Recently played stations
* Custom station URLs
* Import and export
* Better stream metadata
* Additional desktop integrations
* Additional platform support

These possibilities are not commitments and must not expand the frozen version 0.1 scope.

## Product Boundary

Open Station should not become an overloaded media platform.

It succeeds when it provides:

> A clean, private way to discover internet radio and build a personal collection of favorite stations.

When considering a new feature, ask:

> Does this make it easier to discover, play, save, or return to a radio station?

If not, it should usually be deferred.
