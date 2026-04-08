//
//  Endpoint.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String, Sendable {
    case get = "GET"
}

// MARK: - Endpoint
struct Endpoint: Sendable {
    nonisolated let baseURL: String
    nonisolated let path: String
    nonisolated let queryItems: [URLQueryItem]
    nonisolated let method: HTTPMethod
    nonisolated let headers: [String: String]

    nonisolated init(
        baseURL: String,
        path: String = "",
        queryItems: [URLQueryItem] = [],
        method: HTTPMethod = .get,
        headers: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
    }

    nonisolated var url: URL? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}
