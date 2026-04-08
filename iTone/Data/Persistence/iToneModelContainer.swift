//
//  iToneModelContainer.swift
//  iTone
//
//  Created by Mércia
//

import SwiftData

// MARK: - Shared ModelContainer for dependency injection
enum iToneModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([CachedSong.self, RecentlyPlayedSong.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
