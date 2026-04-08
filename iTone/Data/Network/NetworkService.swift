//
//  NetworkService.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noConnection
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError: return "Failed to decode response"
        case .noConnection: return "No internet connection"
        case .unknown(let err): return err.localizedDescription
        }
    }
}

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - URLSession Implementation
final class URLSessionNetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.noConnection
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
