//
//  AlbumView.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

struct AlbumView: View {
    let collectionId: Int
    let albumTitle: String

    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: AlbumViewModel

    init(collectionId: Int, albumTitle: String) {
        self.collectionId = collectionId
        self.albumTitle = albumTitle
        self._viewModel = State(initialValue: AlbumViewModel(
            collectionId: collectionId,
            repository: SongRepositoryImpl(
                networkService: URLSessionNetworkService(),
                modelContainer: iToneModelContainer.shared
            )
        ))
    }

    /// Preview-only init that injects a pre-loaded view model.
    fileprivate init(previewViewModel: AlbumViewModel, albumTitle: String) {
        self.collectionId = previewViewModel.album?.id ?? 0
        self.albumTitle = albumTitle
        self._viewModel = State(initialValue: previewViewModel)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch viewModel.viewState {
            case .loading:
                ProgressView()
                    .tint(.secondaryText)
            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondaryText)
                    Text(message)
                        .foregroundStyle(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") { Task { await viewModel.load() } }
                        .buttonStyle(.bordered)
                        .tint(.secondaryText)
                }
            case .loaded, .empty:
                if let album = viewModel.album {
                    albumContent(album: album)
                }
            default:
                EmptyView()
            }
        }
        .navigationTitle(albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }

    // MARK: - Album Content

    private func albumContent(album: Album) -> some View {
        List {
            // Album header
            Section {
                VStack(spacing: 16) {
                    ArtworkImageView(
                        url: album.artworkUrl?.resizedArtwork(),
                        size: 120,
                        cornerRadius: 20
                    )
                    .opacity(0.9)

                    VStack(spacing: 6) {
                        Text(album.name)
                            .font(.albumTitle)
                            .foregroundStyle(.primaryText)
                            .multilineTextAlignment(.center)
                        Text(album.artistName)
                            .font(.albumArtist)
                            .foregroundStyle(.primaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Track list
            Section {
                ForEach(album.songs) { song in
                    SongRowView(song: song)
                        .onTapGesture {
                            coordinator.navigateToPlayer(
                                song: song,
                                playlist: album.songs
                            )
                        }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Preview

private struct PreviewRepository: SongRepositoryProtocol {
    let album: Album

    func searchSongs(query: String, offset: Int) async throws -> [Song] { [] }
    func getAlbumSongs(collectionId: Int) async throws -> Album { album }
    func markAsPlayed(_ song: Song) async throws {}
    func getRecentlyPlayed(limit: Int) async throws -> [Song] { [] }
}

#Preview {
    let songs: [Song] = (1...4).map { index in
        Song(
            id: index,
            name: ["Testing", "Another music", "This is a test", "A new song"][index - 1],
            artistName: "Test Artist",
            collectionId: 1499209861,
            collectionName: "Test Album",
            artworkUrl: URL(string: ""),
            previewUrl: nil,
            trackNumber: index
        )
    }
    let album = Album(
        id: 1499209861,
        name: "Test Album",
        artistName: "Test Artist",
        artworkUrl: URL(string: ""),
        songs: songs
    )

    let viewModel = {
        let albumViewModel = AlbumViewModel(
            collectionId: album.id,
            repository: PreviewRepository(album: album)
        )
        albumViewModel.album = album
        albumViewModel.viewState = .loaded
        return albumViewModel
    }()

    NavigationStack {
        AlbumView(previewViewModel: viewModel, albumTitle: album.name)
            .environment(AppCoordinator())
    }
}
