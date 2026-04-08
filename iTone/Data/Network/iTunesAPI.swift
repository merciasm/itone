//
//  iTunesAPI.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - iTunes API Endpoint Factory
enum iTunesAPI {
    private nonisolated static let baseURL = "https://itunes.apple.com"
    nonisolated static let pageSize = 25

    /// Search songs by text query with pagination support
    nonisolated static func searchSongs(query: String, offset: Int = 0) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/search",
            queryItems: [
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "limit", value: "\(pageSize)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]
        )
    }

    /// Lookup all songs in an album by collection ID
    nonisolated static func albumSongs(collectionId: Int) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/lookup",
            queryItems: [
                URLQueryItem(name: "id", value: "\(collectionId)"),
                URLQueryItem(name: "entity", value: "song")
            ]
        )
    }
}
