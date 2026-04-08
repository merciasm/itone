//
//  PersistableSong.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Shared conversion for persisted song models
nonisolated protocol PersistableSong {
    var trackId: Int { get }
    var trackName: String { get }
    var artistName: String { get }
    var collectionId: Int { get }
    var collectionName: String { get }
    var artworkUrlString: String? { get }
    var previewUrlString: String? { get }
    var trackNumber: Int { get }
}

extension PersistableSong {
    func toDomain() -> Song {
        Song(
            id: trackId,
            name: trackName,
            artistName: artistName,
            collectionId: collectionId,
            collectionName: collectionName,
            artworkUrl: artworkUrlString.flatMap { URL(string: $0) },
            previewUrl: previewUrlString.flatMap { URL(string: $0) },
            trackNumber: trackNumber
        )
    }
}
