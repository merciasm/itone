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
@MainActor
@Observable
final class SongsViewModel {
    var songs: [Song] = []
    var recentlyPlayed: [Song] = []
    var searchText: String = ""
    var viewState: ViewState = .idle
    var hasMorePages: Bool = true

    private let repository: SongRepositoryProtocol
    private var currentOffset: Int = 0
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

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(query: query, reset: true)
        }
    }

    func loadMore() {
        guard hasMorePages, viewState != .loading, !currentQuery.isEmpty else { return }
        Task { await search(query: currentQuery, reset: false) }
    }

    func refresh() async {
        if currentQuery.isEmpty {
            await loadRecentlyPlayed()
        } else {
            await search(query: currentQuery, reset: true)
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

    private func search(query: String, reset: Bool) async {
        if reset {
            currentOffset = 0
            currentQuery = query
            songs = []
            hasMorePages = true
        }

        guard !Task.isCancelled else { return }
        viewState = .loading

        do {
            let results = try await repository.searchSongs(query: query, offset: currentOffset)
            guard !Task.isCancelled else { return }

            if reset {
                songs = results
            } else {
                songs.append(contentsOf: results)
            }

            currentOffset += results.count
            hasMorePages = results.count >= iTunesAPI.pageSize
            viewState = songs.isEmpty ? .empty : .loaded
        } catch {
            guard !Task.isCancelled else { return }
            viewState = songs.isEmpty ? .error(error.localizedDescription) : .loaded
        }
    }

    private func resetSearch() {
        songs = []
        currentOffset = 0
        currentQuery = ""
        hasMorePages = true
        viewState = .idle
    }
}
