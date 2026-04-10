//
//  Endpoint.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

struct Endpoint: Sendable {
    // Swift 6 -> Default Actor isolation -> Main actor
    // nonisolated: this is fine to call from anywhere, don't force it to the main thread
    nonisolated let baseURL: String
    nonisolated let path: String
    nonisolated let queryItems: [URLQueryItem]

    nonisolated init(
        baseURL: String,
        path: String = "",
        queryItems: [URLQueryItem] = []
    ) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
    }

    nonisolated var url: URL? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}
