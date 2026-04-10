//
//  iToneModelContainer.swift
//  iTone
//
//  Created by Mércia
//

import SwiftData

// MARK: - Shared ModelContainer

// Swift Data breaking changes: Rename, remove and type change - CAREFUL
// Since this cache is for offline performance,
// a recovery strategy can be wipe on failuire and repopulate on next search
enum iToneModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([RecentlyPlayedSong.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // TODO: Avoid a crash and check if schema has changed, test wipe the store and start fresh
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
