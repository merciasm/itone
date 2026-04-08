//
//  CachedSong.swift
//  iTone
//
//  Created by Mércia
//

import Foundation
import SwiftData

// MARK: - Cached Song (SwiftData Model)
@Model
final class CachedSong {
    @Attribute(.unique) var trackId: Int
    var trackName: String
    var artistName: String
    var collectionId: Int
    var collectionName: String
    var artworkUrlString: String?
    var previewUrlString: String?
    var trackNumber: Int
    var searchQuery: String
    var cachedAt: Date

    init(from song: Song, searchQuery: String) {
        self.trackId = song.id
        self.trackName = song.name
        self.artistName = song.artistName
        self.collectionId = song.collectionId
        self.collectionName = song.collectionName
        self.artworkUrlString = song.artworkUrl?.absoluteString
        self.previewUrlString = song.previewUrl?.absoluteString
        self.trackNumber = song.trackNumber
        self.searchQuery = searchQuery
        self.cachedAt = Date()
    }

    func toDomain() -> Song {
        return Song(
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
