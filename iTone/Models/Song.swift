//
//  Song.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Artwork URL Resizing

extension URL {
    /// Replaces the iTunes 100x100 size suffix with the requested size,
    /// since I don't have the spec to this dimension, I'm using 300 as default.
    func resizedArtwork(size: Int = 300) -> URL? {
        let resized = absoluteString.replacingOccurrences(of: "100x100bb", with: "\(size)x\(size)bb")
        return URL(string: resized)
    }
}

// Only got the information I needed from design and requirements
// MARK: - Song Domain Model
struct Song: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let artistName: String
    let collectionId: Int
    let collectionName: String
    let artworkUrl: URL?
    let previewUrl: URL?
    let trackNumber: Int
}

// MARK: - Album Domain Model
struct Album: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let artistName: String
    let artworkUrl: URL?
    let songs: [Song]
}
