# iTone

iTone is an iOS app that lets you search and play song previews using the Apple iTunes API.

<!-- screenshot -->

## How to Run

1. Open `iTone.xcodeproj` in Xcode 26+
2. Select an iPhone simulator or device
3. Build and run (Cmd+R)

The only third-party dependency is SwiftLint (build tool plugin) for code style enforcement.

## Tech Stack

- Swift 6
- SwiftUI
- MVVM with `@Observable`
- Swift Concurrency (async/await)
- SwiftData for persistence
- AVFoundation for audio playback
- SwiftLint (build tool plugin)

## Features

- Song search with debounced input and client-side infinite scroll pagination
- Audio preview playback with play/pause, next, previous, seek, and progress tracking
- Album detail view with track listing, navigable from search results or the player
- Recently played songs persisted locally with SwiftData
- Offline-first search — cached results are served instantly, network fetches update the cache
- Dark theme with a custom color and font system
- Accessibility labels on the player screen
- Coordinator-based navigation using `NavigationStack` and `NavigationPath`
- Protocol-based dependency injection for networking, persistence, and audio services

## Testing

- 33 tests (unit + UI)
- Unit tests cover ViewModels, DTO mapping, endpoint construction, and domain models
- UI tests cover app launch, search interaction, and launch performance
- Run with Cmd+U or `xcodebuild test`

## Roadmap

- [ ] Widgets — recently played and now playing widgets for the Home Screen
- [ ] Apple Watch support
- [ ] CarPlay support

## Architecture

```
iTone/
├── Data/
│   ├── Network/          # Endpoint, iTunesAPI, NetworkService
│   ├── Persistence/      # SwiftData models (CachedSong, RecentlyPlayedSong)
│   └── Repositories/     # SongRepository protocol + implementation
├── Extensions/           # Color and Font theme extensions
├── Features/
│   ├── Album/            # Album detail view + view model
│   ├── Components/       # Reusable views (ArtworkImageView, MoreOptionsSheet)
│   ├── Player/           # Player view + view model
│   └── Songs/            # Song list, search, row views + view model
├── Models/               # Song, Album domain models, iTunes DTOs
├── Navigation/           # AppCoordinator with typed routes
└── Services/             # AudioPlayerService protocol + AVPlayer implementation
```
