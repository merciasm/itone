//
//  SongsViewModel.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - View State
enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

// MARK: - Songs ViewModel

/// Uses client-side pagination because the iTunes Search API lacks server-side
/// offset support (see iTunesAPI.swift). All results are fetched once; `songs`
/// is a sliding window that grows by `pageSize` items as the user scrolls.
@MainActor
@Observable
final class SongsViewModel {
    var songs: [Song] = []
    var recentlyPlayed: [Song] = []
    var searchText: String = ""
    var viewState: ViewState = .idle
    var hasMorePages: Bool = false

    /// All fetched results (used as the full playlist when navigating to the player)
    var allSongs: [Song] { allResults }

    static let pageSize = 25
    private let repository: SongRepositoryProtocol
    private var allResults: [Song] = []
    private var currentQuery: String = ""
    private var searchTask: Task<Void, Never>?

    init(repository: SongRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Search (debounced)
    func onSearchTextChanged() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespaces)

        guard !query.isEmpty else {
            resetSearch()
            Task { await loadRecentlyPlayed() }
            return
        }

        // Only start searching after the user stops typing for 400ms, to reduce API calls
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(query: query)
        }
    }

    func loadMore() {
        guard hasMorePages, viewState != .loading else { return }
        let nextCount = min(songs.count + Self.pageSize, allResults.count)
        songs = Array(allResults.prefix(nextCount))
        hasMorePages = songs.count < allResults.count
    }

    func refresh() async {
        if currentQuery.isEmpty {
            await loadRecentlyPlayed()
        } else {
            await search(query: currentQuery)
        }
    }

    func loadRecentlyPlayed() async {
        do {
            recentlyPlayed = try await repository.getRecentlyPlayed(limit: 20)
        } catch {
            recentlyPlayed = []
        }
    }

    // MARK: - Private

    private func search(query: String) async {
        currentQuery = query

        guard !Task.isCancelled else { return }
        viewState = .loading

        do {
            let results = try await repository.searchSongs(query: query)
            guard !Task.isCancelled else { return }

            allResults = results
            songs = Array(results.prefix(Self.pageSize))
            hasMorePages = songs.count < allResults.count
            viewState = songs.isEmpty ? .empty : .loaded
        } catch {
            guard !Task.isCancelled else { return }
            viewState = songs.isEmpty ? .error(error.localizedDescription) : .loaded
        }
    }

    private func resetSearch() {
        allResults = []
        songs = []
        currentQuery = ""
        hasMorePages = false
        viewState = .idle
    }
}
