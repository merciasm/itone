//
//  SongRepository.swift
//  iTone
//
//  Created by Mércia
//

import Foundation
import SwiftData

protocol SongRepositoryProtocol: Sendable {
    func searchSongs(query: String) async throws -> [Song]

    func getAlbumSongs(collectionId: Int) async throws -> Album

    /// Record that a song was played (for recently played list).
    func markAsPlayed(_ song: Song) async throws

    /// Fetch recently played songs ordered by most recent first.
    func getRecentlyPlayed(limit: Int) async throws -> [Song]
}

// MARK: - Song Repository Implementation
// Applying mainActor here means that all public methods will run on the main thread
@MainActor
final class SongRepository: SongRepositoryProtocol {
    static let shared = SongRepository(
        networkService: URLSessionNetworkService(),
        modelContainer: iToneModelContainer.shared
    )

    private let networkService: NetworkServiceProtocol
    private let modelContainer: ModelContainer

    init(networkService: NetworkServiceProtocol, modelContainer: ModelContainer) {
        self.networkService = networkService
        self.modelContainer = modelContainer
    }

    // MARK: - Public functions
    func searchSongs(query: String) async throws -> [Song] {
        return try await fetchSongs(query: query)
    }

    func getAlbumSongs(collectionId: Int) async throws -> Album {
        let endpoint = iTunesAPI.albumSongs(collectionId: collectionId)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)

        let albumDTO = response.results.first { $0.wrapperType == .collection }
        let songs = response.results
            .filter { $0.wrapperType == .track }
            .compactMap { $0.toDomain() }
            .sorted { $0.trackNumber < $1.trackNumber }

        return Album(
            id: collectionId,
            name: albumDTO?.collectionName ?? songs.first?.collectionName ?? "",
            artistName: albumDTO?.artistName ?? songs.first?.artistName ?? "",
            artworkUrl: albumDTO?.artworkUrl100.flatMap { URL(string: $0) } ?? songs.first?.artworkUrl,
            songs: songs
        )
    }

    func markAsPlayed(_ song: Song) async throws {
        let context = modelContainer.mainContext
        let trackId = song.id
        // Used to query persisted data
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

    func getRecentlyPlayed(limit: Int) async throws -> [Song] {
        let context = modelContainer.mainContext
        var descriptor = FetchDescriptor<RecentlyPlayedSong>(
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    // MARK: - Private Helpers

    private func fetchSongs(query: String) async throws -> [Song] {
        let endpoint = iTunesAPI.searchSongs(query: query)
        let response: iTunesSearchResponse = try await networkService.request(endpoint)
        return response.results.compactMap { $0.toDomain() }
    }
}
