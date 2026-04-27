//
//  RecentlyPlayedProvider.swift
//  iToneWIdget
//
//  Created by Mércia
//

import WidgetKit
import SwiftData

struct RecentlyPlayedProvider: TimelineProvider {

    // MARK: - Placeholder (shown with redaction in widget gallery)

    func placeholder(in context: Context) -> RecentlyPlayedEntry {
        RecentlyPlayedEntry.placeholder
    }

    // MARK: - Snapshot (quick preview when adding widget)

    func getSnapshot(in context: Context, completion: @escaping (RecentlyPlayedEntry) -> Void) {
        completion(fetchEntry(limit: songLimit(for: context.family)))
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentlyPlayedEntry>) -> Void) {
        let entry = fetchEntry(limit: songLimit(for: context.family))
        // Refresh every 15 minutes so the widget picks up newly played songs
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Private Helpers

    private func songLimit(for family: WidgetFamily) -> Int {
        // Fetch more songs for medium so we can deduplicate into 3 distinct albums
        family == .systemSmall ? 1 : 30
    }

    private func fetchEntry(limit: Int) -> RecentlyPlayedEntry {
        do {
            let schema = Schema([RecentlyPlayedSong.self])
            let config: ModelConfiguration
            if let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: iToneModelContainer.appGroupID
            ) {
                let storeURL = groupURL.appendingPathComponent("iTone.store")
                print("[Widget] Using App Group store: \(storeURL.path)")
                config = ModelConfiguration(schema: schema, url: storeURL, allowsSave: false)
            } else {
                print("[Widget] App Group not available, using default store")
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: false)
            }

            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            var descriptor = FetchDescriptor<RecentlyPlayedSong>(
                sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
            )
            descriptor.fetchLimit = limit

            let songs = try context.fetch(descriptor).map { $0.toDomain() }
            print("[Widget] Fetched \(songs.count) songs")
            return RecentlyPlayedEntry(date: .now, songs: songs)
        } catch {
            print("[Widget] Fetch error: \(error)")
            return RecentlyPlayedEntry(date: .now, songs: [])
        }
    }
}
