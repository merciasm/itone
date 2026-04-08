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

// MARK: - Mock Audio Player

@MainActor
final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 30
    var progress: Double = 0

    var playedURLs: [URL] = []
    var seekedTo: Double?

    func play(url: URL) {
        playedURLs.append(url)
        isPlaying = true
        currentTime = 0
        progress = 0
    }

    func pause() { isPlaying = false }
    func resume() { isPlaying = true }

    func seek(to time: Double) {
        seekedTo = time
        currentTime = time
        progress = duration > 0 ? time / duration : 0
    }

    func stop() {
        isPlaying = false
        currentTime = 0
        duration = 0
        progress = 0
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

    func searchSongs(query: String) async throws -> [Song] {
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
    func searchEndpointURL() throws {
        let endpoint = iTunesAPI.searchSongs(query: "Daft Punk")
        let urlString = try #require(endpoint.url).absoluteString
        #expect(urlString.contains("itunes.apple.com"))
        #expect(urlString.contains("limit=200"))
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
        let repository = MockSongRepository()
        let viewModel = SongsViewModel(repository: repository)
        #expect(viewModel.viewState == .idle)
        #expect(viewModel.songs.isEmpty)
        #expect(viewModel.searchText.isEmpty)
    }

    @Test("Search returns results and sets loaded state")
    func searchReturnsResults() async throws {
        let repository = MockSongRepository()
        repository.searchResult = [.fixture(id: 1), .fixture(id: 2)]
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "Daft"
        viewModel.onSearchTextChanged()

        // Wait for debounce + fetch
        try await Task.sleep(for: .milliseconds(600))
        #expect(viewModel.songs.count == 2)
        #expect(viewModel.viewState == .loaded)
    }

    @Test("Empty search text resets to idle state")
    func emptySearchResetsState() async throws {
        let repository = MockSongRepository()
        repository.searchResult = [.fixture()]
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "test"
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))

        viewModel.searchText = ""
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.viewState == .idle)
        #expect(viewModel.songs.isEmpty)
    }

    @Test("Network error sets error state when no songs cached")
    func networkErrorSetsErrorState() async throws {
        let repository = MockSongRepository()
        repository.shouldThrow = NetworkError.noConnection
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "test"
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))

        if case .error = viewModel.viewState {
            // Expected
        } else {
            Issue.record("Expected error state, got \(viewModel.viewState)")
        }
    }

    @Test("loadMore reveals next page of client-side results")
    func loadMoreRevealsNextPage() async throws {
        let page = SongsViewModel.pageSize
        let repository = MockSongRepository()
        repository.searchResult = (1...page * 2).map { Song.fixture(id: $0) }
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "test"
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))
        #expect(viewModel.songs.count == page)
        #expect(viewModel.hasMorePages)

        // Reveal next page (client-side, no network call)
        viewModel.loadMore()
        #expect(viewModel.songs.count == page * 2)
        #expect(!viewModel.hasMorePages)
    }

    @Test("loadMore does nothing when hasMorePages is false")
    func loadMoreNoOpWhenNoPagesLeft() async throws {
        let repository = MockSongRepository()
        repository.searchResult = (1...10).map { Song.fixture(id: $0) }
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "test"
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))

        // All 10 results fit in one page, so hasMorePages is false
        #expect(viewModel.songs.count == 10)
        #expect(!viewModel.hasMorePages)

        viewModel.loadMore()
        #expect(viewModel.songs.count == 10)
    }

    @Test("refresh re-fetches search results when query is active")
    func refreshWithActiveQuery() async throws {
        let repository = MockSongRepository()
        repository.searchResult = [.fixture(id: 1)]
        let viewModel = SongsViewModel(repository: repository)

        viewModel.searchText = "test"
        viewModel.onSearchTextChanged()
        try await Task.sleep(for: .milliseconds(600))
        #expect(viewModel.songs.count == 1)

        // Update mock and refresh
        repository.searchResult = [.fixture(id: 1), .fixture(id: 2)]
        await viewModel.refresh()
        #expect(viewModel.songs.count == 2)
    }

    @Test("refresh loads recently played when no query is active")
    func refreshWithNoQuery() async throws {
        let repository = MockSongRepository()
        repository.recentlyPlayed = [.fixture(id: 10)]
        let viewModel = SongsViewModel(repository: repository)

        await viewModel.refresh()
        #expect(viewModel.recentlyPlayed.count == 1)
    }

    @Test("Recently played songs are loaded on appear")
    func recentlyPlayedLoaded() async throws {
        let repository = MockSongRepository()
        repository.recentlyPlayed = [.fixture(id: 10), .fixture(id: 11)]
        let viewModel = SongsViewModel(repository: repository)

        await viewModel.loadRecentlyPlayed()
        #expect(viewModel.recentlyPlayed.count == 2)
    }
}

// MARK: - AlbumViewModel Tests

@Suite("AlbumViewModel Tests")
@MainActor
struct AlbumViewModelTests {
    @Test("Loads album successfully")
    func loadsAlbum() async {
        let repository = MockSongRepository()
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2)]
        repository.albumResult = Album(
            id: 100, name: "Test Album", artistName: "Test Artist",
            artworkUrl: nil, songs: songs)
        let viewModel = AlbumViewModel(collectionId: 100, repository: repository)
        await viewModel.load()
        #expect(viewModel.viewState == .loaded)
        #expect(viewModel.album?.songs.count == 2)
    }

    @Test("Error state on network failure")
    func errorStateOnFailure() async {
        let repository = MockSongRepository()
        repository.shouldThrow = NetworkError.noConnection
        let viewModel = AlbumViewModel(collectionId: 100, repository: repository)
        await viewModel.load()
        if case .error = viewModel.viewState {
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
        let songA = Song.fixture(id: 1)
        let songB = Song.fixture(id: 1)
        let differentSong = Song.fixture(id: 2)
        #expect(songA == songB)
        #expect(songA != differentSong)
    }
}

// MARK: - PlayerViewModel Tests

@Suite("PlayerViewModel Tests")
@MainActor
struct PlayerViewModelTests {
    private func makePlayerViewModel(
        song: Song = .fixture(id: 1),
        playlist: [Song]? = nil,
        audioPlayer: MockAudioPlayerService = MockAudioPlayerService(),
        repository: MockSongRepository = MockSongRepository()
    ) -> (PlayerViewModel, MockAudioPlayerService) {
        let list = playlist ?? [song]
        let viewModel = PlayerViewModel(
            song: song,
            playlist: list,
            repository: repository,
            audioPlayer: audioPlayer
        )
        return (viewModel, audioPlayer)
    }

    @Test("Play starts playback")
    func playStartsPlayback() {
        let (viewModel, player) = makePlayerViewModel()
        viewModel.play()
        #expect(player.isPlaying)
        #expect(player.playedURLs.count == 1)
    }

    @Test("Toggle play/pause pauses when playing")
    func togglePause() {
        let (viewModel, player) = makePlayerViewModel()
        viewModel.play()
        #expect(player.isPlaying)
        viewModel.togglePlayPause()
        #expect(!player.isPlaying)
    }

    @Test("Toggle play/pause resumes when paused mid-song")
    func toggleResume() {
        let (viewModel, player) = makePlayerViewModel()
        viewModel.play()
        viewModel.togglePlayPause() // pause
        player.currentTime = 5
        viewModel.togglePlayPause() // resume
        #expect(player.isPlaying)
    }

    @Test("Seek updates progress")
    func seekUpdatesProgress() {
        let (viewModel, player) = makePlayerViewModel()
        player.duration = 30
        viewModel.seek(to: 0.5)
        #expect(player.seekedTo == 15)
    }

    @Test("playNext advances to next song")
    func playNextAdvances() {
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2), Song.fixture(id: 3)]
        let (viewModel, player) = makePlayerViewModel(song: songs[0], playlist: songs)
        viewModel.play()
        #expect(viewModel.hasNext)

        viewModel.playNext()
        #expect(viewModel.currentSong.id == 2)
        #expect(player.playedURLs.count == 2)
    }

    @Test("playNext does nothing at end of playlist")
    func playNextAtEnd() {
        let songs = [Song.fixture(id: 1)]
        let (viewModel, _) = makePlayerViewModel(song: songs[0], playlist: songs)
        #expect(!viewModel.hasNext)
        viewModel.playNext()
        #expect(viewModel.currentSong.id == 1)
    }

    @Test("playPrevious goes to previous song when near start")
    func playPreviousGoesBack() {
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2)]
        let (viewModel, player) = makePlayerViewModel(song: songs[1], playlist: songs)
        player.currentTime = 1 // < 3 seconds
        viewModel.playPrevious()
        #expect(viewModel.currentSong.id == 1)
    }

    @Test("playPrevious restarts song when past 3 seconds")
    func playPreviousRestarts() {
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2)]
        let (viewModel, player) = makePlayerViewModel(song: songs[1], playlist: songs)
        player.currentTime = 5 // > 3 seconds
        viewModel.playPrevious()
        #expect(viewModel.currentSong.id == 2) // stays on same song
        #expect(player.seekedTo == 0)   // but restarted
    }

    @Test("stopPlayback stops the player")
    func stopPlayback() {
        let (viewModel, player) = makePlayerViewModel()
        viewModel.play()
        viewModel.stopPlayback()
        #expect(!player.isPlaying)
    }

    @Test("formattedTime formats correctly")
    func formattedTime() {
        let (viewModel, _) = makePlayerViewModel()
        #expect(viewModel.formattedTime(0) == "0:00")
        #expect(viewModel.formattedTime(65) == "1:05")
        #expect(viewModel.formattedTime(125) == "2:05")
        #expect(viewModel.formattedTime(.nan) == "0:00")
        #expect(viewModel.formattedTime(-5) == "0:00")
    }

    @Test("Toggle play/pause from cold state triggers play")
    func togglePlayPauseFromColdState() {
        let (viewModel, player) = makePlayerViewModel()
        // Not playing, currentTime == 0 → should call play()
        viewModel.togglePlayPause()
        #expect(player.isPlaying)
        #expect(player.playedURLs.count == 1)
    }

    @Test("hasPrevious and hasNext are correct")
    func navigationFlags() {
        let songs = [Song.fixture(id: 1), Song.fixture(id: 2), Song.fixture(id: 3)]
        let (viewModel, _) = makePlayerViewModel(song: songs[1], playlist: songs)
        #expect(viewModel.hasPrevious)
        #expect(viewModel.hasNext)
    }
}
