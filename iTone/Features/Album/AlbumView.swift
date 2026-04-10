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
            repository: SongRepository.shared
        ))
    }

    var body: some View {
        ZStack {
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
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - Album Content

    private func albumContent(album: Album) -> some View {
        List {
            // Album header
            Section {
                VStack(alignment: .center, spacing: 16) {
                    ArtworkImageView(
                        url: album.artworkUrl?.resizedArtwork(),
                        size: 120,
                        cornerRadius: 20
                    )
                    .opacity(0.9)

                    VStack(spacing: 8) {
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
                .listRowInsets(EdgeInsets())
                .listSectionSpacing(0)
                .padding(.bottom, 48)
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
            .background(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listSectionSpacing(20)

        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}
