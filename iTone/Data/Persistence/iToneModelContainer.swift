//
//  iToneModelContainer.swift
//  iTone
//
//  Created by Mércia
//

import SwiftData
import Foundation

// MARK: - Shared ModelContainer

// Swift Data breaking changes: Rename, remove and type change - CAREFUL
// Since this cache is for offline performance,
// a recovery strategy can be wipe on failuire and repopulate on next search
enum iToneModelContainer {
    /// App Group shared between the main app and the widget extension.
    static let appGroupID = "group.com.iTone"

    static let shared: ModelContainer = {
        let schema = Schema([RecentlyPlayedSong.self])
        // Use the shared App Group container so the widget can read the same store.
        // Falls back to the default local store when the App Group isn't provisioned (e.g. in the simulator without entitlements).
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        let config: ModelConfiguration
        if let groupURL {
            config = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("iTone.store"))
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // TODO: Avoid a crash and check if schema has changed, test wipe the store and start fresh
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
