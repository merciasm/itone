//
//  iTunesResponse.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - API Response Wrapper
struct iTunesSearchResponse: Decodable, Sendable {
    let resultCount: Int
    let results: [iTunesTrackDTO]
}

// MARK: - Wrapper Type
enum WrapperType: String, Decodable, Sendable {
    case track
    case collection
}

// MARK: - Track DTO
// Model that mirrors the iTunes API response for a track, used for decoding JSON and mapping to the domain model.
struct iTunesTrackDTO: Decodable, Sendable {
    let wrapperType: WrapperType?
    let kind: String?
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionId: Int?
    let collectionName: String?
    let artworkUrl100: String?
    let previewUrl: String?
    let trackNumber: Int?

    // MARK: - Mapping to Domain Model
    nonisolated func toDomain() -> Song? {
        guard
            let trackId,
            let trackName,
            let artistName,
            let collectionId,
            let collectionName
        else { return nil }

        let artworkUrl = artworkUrl100.flatMap { URL(string: $0) }
        let previewUrl = previewUrl.flatMap { URL(string: $0) }

        return Song(
            id: trackId,
            name: trackName,
            artistName: artistName,
            collectionId: collectionId,
            collectionName: collectionName,
            artworkUrl: artworkUrl,
            previewUrl: previewUrl,
            trackNumber: trackNumber ?? 1
        )
    }
}
