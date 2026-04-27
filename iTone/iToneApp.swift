//
//  iToneApp.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI
import SwiftData

@main
struct iToneApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .modelContainer(iToneModelContainer.shared)
                .preferredColorScheme(ColorScheme.dark)
        }
    }
}

// MARK: - Root View (NavigationStack host)
struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.path) {
            SongsView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .player(let song, let playlist):
                        PlayerView(song: song, playlist: playlist)
                    case .album(let collectionId, let title):
                        AlbumView(collectionId: collectionId, albumTitle: title)
                    }
                }
        }
        .tint(.secondaryText)
        .onOpenURL { url in
            guard url.scheme == "iTone",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { return }

            coordinator.path = NavigationPath()

            switch url.host {
            case "album":
                guard let id = components.intValue(for: "id"),
                      let title = components.stringValue(for: "title")
                else { return }
                coordinator.navigateToAlbum(collectionId: id, title: title)

            case "song":
                guard let id = components.intValue(for: "id"),
                      let name = components.stringValue(for: "name"),
                      let artist = components.stringValue(for: "artist"),
                      let collectionId = components.intValue(for: "collectionId"),
                      let collectionName = components.stringValue(for: "collectionName"),
                      let trackNumber = components.intValue(for: "trackNumber")
                else { return }
                let song = Song(
                    id: id,
                    name: name,
                    artistName: artist,
                    collectionId: collectionId,
                    collectionName: collectionName,
                    artworkUrl: components.stringValue(for: "artwork").flatMap { URL(string: $0) },
                    previewUrl: components.stringValue(for: "preview").flatMap { URL(string: $0) },
                    trackNumber: trackNumber
                )
                coordinator.navigateToPlayer(song: song, playlist: [song])

            default:
                break
            }
        }
    }
}
