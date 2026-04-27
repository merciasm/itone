//
//  RecentlyPlayedEntry.swift
//  iToneWIdget
//
//  Created by Mércia
//

import WidgetKit

struct RecentlyPlayedEntry: TimelineEntry {
    let date: Date
    let songs: [Song]

    /// Distinct albums derived from recently played songs, in order of most recently played.
    /// Each element is the first song played from that album (carries collectionName + artworkUrl).
    var recentAlbums: [Song] {
        var seen = Set<Int>()
        return songs.filter { seen.insert($0.collectionId).inserted }
    }

    static let placeholder = RecentlyPlayedEntry(
        date: .now,
        songs: [
            Song(
                id: 0,
                name: "Song Title",
                artistName: "Artist Name",
                collectionId: 0,
                collectionName: "Album",
                artworkUrl: nil,
                previewUrl: nil,
                trackNumber: 1
            )
        ]
    )
}
