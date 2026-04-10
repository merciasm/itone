//
//  AppCoordinator.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

// MARK: - Navigation Destinations
enum AppRoute: Hashable {
    case player(song: Song, playlist: [Song])
    case album(collectionId: Int, title: String)
}

// MARK: - App Coordinator
@MainActor
@Observable
final class AppCoordinator {
    // array of routes
    var path: NavigationPath = NavigationPath()

    func navigateToPlayer(song: Song, playlist: [Song]) {
        path.append(AppRoute.player(song: song, playlist: playlist))
    }

    func navigateToAlbum(collectionId: Int, title: String) {
        path.append(AppRoute.album(collectionId: collectionId, title: title))
    }

    func navigateBack() {
        path.removeLast()
    }
}
