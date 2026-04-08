//
//  SongRepositoryImpl.swift
//  iTone
//
//  Created by Mércia
//

import Foundation
import SwiftData

// MARK: - Song Repository Implementation (offline-first)
final class SongRepositoryImpl: SongRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let modelContainer: ModelContainer
    private var refreshTask: Task<Void, Never>?

    init(networkService: NetworkServiceProtocol, modelContainer: ModelContainer) {
        self.networkService = networkService
        self.modelContainer = modelContainer
    }

    // MARK: - Search Songs (cache-first, network-refresh)
    func searchSongs(query: String) async throws -> [Song] {
        refreshTask?.cancel()

        let cached = (try? await getCachedSongs(for: query)) ?? []
        if cached.isEmpty {
            return try await fetchAndCacheSongs(query: query)
        }
        // Return cache immediately; refresh in the background so the next search is fresh
        refreshTask = Task { try? await fetchAndCacheSongs(query: query) }
        return cached
    }

    // MARK: - Album Songs
    func getAlbumSongs(collectionId: Int) async throws -> Album {
        let endpoint = iTunesAPI.albumSongs(collectionId: collectionId)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)

        let songs = response.results
            .filter { $0.wrapperType == "track" }
            .compactMap { $0.toDomain() }
            .sorted { $0.trackNumber < $1.trackNumber }

        let albumDTO = response.results.first { $0.wrapperType == "collection" }
        let artworkUrl = albumDTO?.artworkUrl100.flatMap { URL(string: $0) }
            ?? songs.first?.artworkUrl

        return Album(
            id: collectionId,
            name: albumDTO?.collectionName ?? songs.first?.collectionName ?? "",
            artistName: albumDTO?.artistName ?? songs.first?.artistName ?? "",
            artworkUrl: artworkUrl,
            songs: songs
        )
    }

    // MARK: - Mark As Played
    @MainActor
    func markAsPlayed(_ song: Song) async throws {
        let context = modelContainer.mainContext
        let trackId = song.id
        let descriptor = FetchDescriptor<RecentlyPlayedSong>(
            predicate: #Predicate { $0.trackId == trackId }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
        }
        let record = RecentlyPlayedSong(from: song)
        context.insert(record)
        try context.save()
    }

    // MARK: - Recently Played
    @MainActor
    func getRecentlyPlayed(limit: Int) async throws -> [Song] {
        let context = modelContainer.mainContext
        var descriptor = FetchDescriptor<RecentlyPlayedSong>(
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    // MARK: - Private Helpers

    @MainActor
    private func getCachedSongs(for query: String) async throws -> [Song] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<CachedSong>(
            predicate: #Predicate { $0.searchQuery == query },
            sortBy: [SortDescriptor(\.cachedAt)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    private func fetchAndCacheSongs(query: String) async throws -> [Song] {
        let endpoint = iTunesAPI.searchSongs(query: query)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)
        let songs = response.results.compactMap { $0.toDomain() }

        await MainActor.run {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<CachedSong>(
                predicate: #Predicate { $0.searchQuery == query }
            )
            if let stale = try? context.fetch(descriptor) {
                for entry in stale { context.delete(entry) }
            }
            for song in songs {
                let cached = CachedSong(from: song, searchQuery: query)
                context.insert(cached)
            }
            try? context.save()
        }

        return songs
    }
}
