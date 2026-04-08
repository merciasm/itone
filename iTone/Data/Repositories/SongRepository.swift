//
//  SongRepository.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Song Repository Protocol
protocol SongRepositoryProtocol: Sendable {
    /// Search songs with pagination. Serves cache first, then fetches from network.
    func searchSongs(query: String, offset: Int) async throws -> [Song]

    /// Get all tracks for an album by collection ID.
    func getAlbumSongs(collectionId: Int) async throws -> Album

    /// Record that a song was played (for recently played list).
    func markAsPlayed(_ song: Song) async throws

    /// Fetch recently played songs ordered by most recent first.
    func getRecentlyPlayed(limit: Int) async throws -> [Song]
}
