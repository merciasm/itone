//
//  iTunesAPI.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - iTunes API Endpoint Factory

// NOTE: Pagination limitation
//
// The iTunes Search API does NOT support server-side pagination. The only result-count
// parameter is `limit` (1–200, default 50). Although an `offset` parameter is available
// the API silently ignores it and always returns results from the beginning.
//
// Requests with different `offset` values return identical result sets.
// Apple's official documentation confirms no offset parameter:
//   - https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html
//   - https://performance-partners.apple.com/search-api
//
// Workaround: Fetch up to 200 results (the API maximum) in a single call and
// paginate client-side in SongsViewModel, revealing pages as the user scrolls.
//
// Ideal approach: server-side offset pagination (offset=N&limit=25) would let
// the ViewModel request one page at a time and append on scroll, avoiding the
// upfront fetch and the 200-item limit.
enum iTunesAPI {
    // This could be in another file something like: Constants.itunesBaseURL
    private nonisolated static let baseURL = "https://itunes.apple.com"
    private nonisolated static let fetchLimit = 200

    /// Search songs by text query (fetches up to 200 results; pagination is client-side)
    nonisolated static func searchSongs(query: String) -> Endpoint {
        // The way we build this depends on the API,
        // It usually has authentication and we send the parameters in the body, sometimes we can have a
        // different header as well, a .GET can send parameters in the URL and a
        // .POST/.PATCH usually sends the parameters in the body
        Endpoint(
            baseURL: baseURL,
            path: "/search",
            // Usually I use Alamofire to handle API calls on my projects
            // So the lib already wraps all for me, here I chose to use the native URL Session
            queryItems: [
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "limit", value: "\(fetchLimit)")
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
