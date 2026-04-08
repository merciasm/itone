//
//  iToneTests.swift
//  iToneTests
//
//  Created by Mércia
//

import Testing
import Foundation
@testable import iTone

// MARK: - Mock Network Service

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var mockResponse: (any Sendable)?
    var shouldThrow: Error?

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if let error = shouldThrow { throw error }
        guard let response = mockResponse as? T else {
            throw NetworkError.decodingError(NSError(domain: "Mock", code: 0))
        }
        return response
    }
}

// MARK: - Mock Repository

@MainActor
final class MockSongRepository: SongRepositoryProtocol {
    var searchResult: [Song] = []
    var albumResult: Album = Album(id: 0, name: "", artistName: "", artworkUrl: nil, songs: [])
    var recentlyPlayed: [Song] = []
    var markedAsPlayed: [Song] = []
    var shouldThrow: Error?

    func searchSongs(query: String, offset: Int) async throws -> [Song] {
        if let error = shouldThrow { throw error }
        return searchResult
    }

    func getAlbumSongs(collectionId: Int) async throws -> Album {
        if let error = shouldThrow { throw error }
        return albumResult
    }

    func markAsPlayed(_ song: Song) async throws {
        markedAsPlayed.append(song)
    }

    func getRecentlyPlayed(limit: Int) async throws -> [Song] {
        if let error = shouldThrow { throw error }
        return Array(recentlyPlayed.prefix(limit))
    }
}

// MARK: - Test Fixtures

extension Song {
    static func fixture(
        id: Int = 1,
        name: String = "Test Song",
        artistName: String = "Test Artist",
        collectionId: Int = 100
    ) -> Song {
        Song(
            id: id,
            name: name,
            artistName: artistName,
            collectionId: collectionId,
            collectionName: "Test Album",
            artworkUrl: nil,
            previewUrl: URL(string: "https://example.com/preview.m4a"),
            trackNumber: 1
        )
    }
}

// MARK: - Endpoint Tests

@Suite("Endpoint Tests")
struct EndpointTests {
    @Test("Search endpoint builds correct URL")
    func searchEndpointURL() {
        let endpoint = iTunesAPI.searchSongs(query: "Daft Punk", offset: 0)
        let url = endpoint.url
        #expect(url != nil)
        let urlString = url!.absoluteString
        #expect(urlString.contains("itunes.apple.com"))
        #expect(urlString.contains("limit=25"))
        #expect(urlString.contains("offset=0"))
    }

    @Test("Search endpoint uses correct offset for pagination")
    func searchEndpointPagination() {
        let endpoint = iTunesAPI.searchSongs(query: "test", offset: 25)
        let urlString = endpoint.url?.absoluteString ?? ""
        #expect(urlString.contains("offset=25"))
    }

    @Test("Album lookup endpoint builds correct URL")
    func albumLookupURL() {
        let endpoint = iTunesAPI.albumSongs(collectionId: 12345)
        let urlString = endpoint.url?.absoluteString ?? ""
        #expect(urlString.contains("lookup"))
        #expect(urlString.contains("12345"))
        #expect(urlString.contains("entity=song"))
    }
}

// MARK: - DTO Mapping Tests

@Suite("iTunesTrackDTO Mapping Tests")
@MainActor
struct DTOMappingTests {
    @Test("Valid DTO maps to Song correctly")
    func validDTOMapsToSong() {
        let dto = iTunesTrackDTO(
            wrapperType: "track",
            kind: "song",
            trackId: 42,
            trackName: "Get Lucky",
            artistName: "Daft Punk",
            collectionId: 99,
            collectionName: "Random Access Memories",
            artworkUrl100: "https://example.com/100x100bb.jpg",
            previewUrl: "https://example.com/preview.m4a",
            trackNumber: 8
        )

        let song = dto.toDomain()
        #expect(song != nil)
        #expect(song?.id == 42)
        #expect(song?.name == "Get Lucky")
        #expect(song?.artistName == "Daft Punk")
        #expect(song?.collectionId == 99)
        #expect(song?.trackNumber == 8)
    }

    @Test("DTO with missing required fields returns nil")
    func incompleteDTOReturnsNil() {
        let dto = iTunesTrackDTO(
            wrapperType: "track",
            kind: "song",
            trackId: nil,
            trackName: nil,
            artistName: nil,
            collectionId: nil,
            collectionName: nil,
            artworkUrl100: nil,
            previewUrl: nil,
            trackNumber: nil
        )
        #expect(dto.toDomain() == nil)
    }
}

// MARK: - SongsViewModel Tests

@Suite("SongsViewModel Tests")
@MainActor
struct SongsViewModelTests {
    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let repo = MockSongRepository()
        let vm = SongsViewModel(repository: repo)
        #expect(vm.viewState == .idle)
        #expect(vm.songs.isEmpty)
        #expect(vm.searchText.isEmpty)
    }

    @Test("Search returns results and sets loaded state")
    func searchReturnsResults() async throws {
        let repo = MockSongRepository()
        repo.searchResult = [.fixture(id: 1), .fixture(id: 2)]
        let vm = SongsViewModel(repository: repo)

        vm.searchText = "Daft"
        vm.onSearchTextChanged()

        // Wait for debounce + fetch
        try await Task.sleep(for: .milliseconds(600))
        #expect(vm.songs.count == 2)
        #expect(vm.viewState == .loaded)
    }

    @Test("Empty search text resets to idle state")
    func emptySearchResetsState() async throws {
        let repo = MockSongRepository()
        repo.searchResult = [.fixture()]
        let vm = SongsViewModel(repository: repo)

        vm.searchText = "test"
        vm.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))

        vm.searchText = ""
        vm.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.viewState == .idle)
        #expect(vm.songs.isEmpty)
    }

    @Test("Network error sets error state when no songs cached")
    func networkErrorSetsErrorState() async throws {
        let repo = MockSongRepository()
        repo.shouldThrow = NetworkError.noConnection
        let vm = SongsViewModel(repository: repo)

        vm.searchText = "test"
        vm.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))

        if case .error = vm.viewState {
            // Expected
        } else {
            Issue.record("Expected error state, got \(vm.viewState)")
        }
    }

    @Test("loadMore appends songs to existing list")
    func loadMoreAppendsSongs() async throws {
        let repo = MockSongRepository()
        repo.searchResult = Array((1...25).map { Song.fixture(id: $0) })
        let vm = SongsViewModel(repository: repo)

        vm.searchText = "test"
        vm.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))
        #expect(vm.songs.count == 25)

        // Second page
        repo.searchResult = Array((26...50).map { Song.fixture(id: $0) })
        vm.loadMore()
        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.songs.count == 50)
    }

    @Test("Recently played songs are loaded on appear")
    func recentlyPlayedLoaded() async throws {
        let repo = MockSongRepository()
        repo.recentlyPlayed = [.fixture(id: 10), .fixture(id: 11)]
        let vm = SongsViewModel(repository: repo)

        await vm.loadRecentlyPlayed()
        #expect(vm.recentlyPlayed.count == 2)
    }
}

// MARK: - AlbumViewModel Tests

@Suite("AlbumViewModel Tests")
@MainActor
struct AlbumViewModelTests {
    @Test("Loads album successfully")
    func loadsAlbum() async {
        let repo = MockSongRepository()
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2)]
        repo.albumResult = Album(
            id: 100, name: "Test Album", artistName: "Test Artist",
            artworkUrl: nil, songs: songs)
        let vm = AlbumViewModel(collectionId: 100, repository: repo)
        await vm.load()
        #expect(vm.viewState == .loaded)
        #expect(vm.album?.songs.count == 2)
    }

    @Test("Error state on network failure")
    func errorStateOnFailure() async {
        let repo = MockSongRepository()
        repo.shouldThrow = NetworkError.noConnection
        let vm = AlbumViewModel(collectionId: 100, repository: repo)
        await vm.load()
        if case .error = vm.viewState {
            // Expected
        } else {
            Issue.record("Expected error state")
        }
    }
}

// MARK: - Song Domain Model Tests

@Suite("Song Domain Model Tests")
@MainActor
struct SongModelTests {
    @Test("artworkUrl replaces size suffix for higher resolution")
    func artworkUrlResizing() {
        let song = Song(
            id: 1, name: "Test", artistName: "Artist",
            collectionId: 1, collectionName: "Album",
            artworkUrl: URL(string: "https://example.com/image/100x100bb.jpg"),
            previewUrl: nil,
            trackNumber: 1
        )
        let url = song.artworkUrl?.resizedArtwork(size: 600)
        #expect(url?.absoluteString.contains("600x600bb") == true)
    }

    @Test("Song conforms to Hashable using id")
    func songHashable() {
        let s1 = Song.fixture(id: 1)
        let s2 = Song.fixture(id: 1)
        let s3 = Song.fixture(id: 2)
        #expect(s1 == s2)
        #expect(s1 != s3)
    }
}

