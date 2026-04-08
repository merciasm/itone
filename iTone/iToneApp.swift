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
    }
}
