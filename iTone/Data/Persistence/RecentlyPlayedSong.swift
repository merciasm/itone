//
//  RecentlyPlayedSong.swift
//  iTone
//
//  Created by Mércia
//

import Foundation
import SwiftData

// MARK: - Recently Played Song (SwiftData Model)
@Model
final class RecentlyPlayedSong {
    @Attribute(.unique) var trackId: Int
    var trackName: String
    var artistName: String
    var collectionId: Int
    var collectionName: String
    var artworkUrlString: String?
    var previewUrlString: String?
    var trackNumber: Int
    var playedAt: Date

    init(from song: Song) {
        self.trackId = song.id
        self.trackName = song.name
        self.artistName = song.artistName
        self.collectionId = song.collectionId
        self.collectionName = song.collectionName
        self.artworkUrlString = song.artworkUrl?.absoluteString
        self.previewUrlString = song.previewUrl?.absoluteString
        self.trackNumber = song.trackNumber
        self.playedAt = Date()
    }

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
