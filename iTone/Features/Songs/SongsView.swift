//
//  SongsView.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

struct SongsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @State private var viewModel: SongsViewModel
    @State private var songForOptions: Song?
    @State private var isSearchActive = false

    init() {
        self._viewModel = State(initialValue: SongsViewModel(
            repository: SongRepository.shared
        ))
    }

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            Group {
                switch viewModel.viewState {
                case .idle:
                    idleContent
                case .loading where viewModel.songs.isEmpty:
                    loadingView
                case .empty:
                    emptyView
                case .error(let message):
                    errorView(message: message)
                default:
                    songsList
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if isSearchActive {
                searchBar
                    .background(Color.appBackground)
            }
        }
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(isSearchActive ? .inline : .large)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .onChange(of: viewModel.searchText) { viewModel.onSearchTextChanged() }
        .onChange(of: isSearchActive) {
            if !isSearchActive {
                viewModel.searchText = ""
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.loadRecentlyPlayed() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isSearchActive = true
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.primaryText)
                }
            }
        }
    }

    // MARK: - Search Bar

    // From the design, I got that the idea was to have the search bar hidden
    // then show it when tapping the search icon
    // It was hard to achieve a great result with this requirement using the native search bar
    // that's why we have a custom one that slides from the top when activating the search mode
    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondaryText)
                    .font(.body)
                TextField("Search", text: $viewModel.searchText)
                    .foregroundStyle(.primaryText)
                    .focused($isSearchFieldFocused)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 44)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                isSearchActive = false
                isSearchFieldFocused = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primaryText)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Idle (no search query)

    @ViewBuilder
    private var idleContent: some View {
        if viewModel.recentlyPlayed.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondaryText)
                Text("Search for songs")
                    .font(.title3)
                    .foregroundStyle(.secondaryText)
            }
        } else {
            songsList
        }
    }

    // MARK: - Songs List

    private var songsList: some View {
        List {
            if !viewModel.recentlyPlayed.isEmpty && viewModel.searchText.isEmpty {
                recentlyPlayedSection
            }

            if !viewModel.songs.isEmpty {
                songsSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .sheet(item: $songForOptions) { song in
            MoreOptionsSheet(song: song) {
                coordinator.navigateToAlbum(
                    collectionId: song.collectionId,
                    title: song.collectionName
                )
            }
        }
    }

    // MARK: - Recently Played Section

    private var recentlyPlayedSection: some View {
        Section {
            ForEach(viewModel.recentlyPlayed) { song in
                SongRowView(song: song, imageSize: 52) {
                    songForOptions = song
                }
                .onTapGesture {
                    coordinator.navigateToPlayer(
                        song: song,
                        playlist: viewModel.recentlyPlayed
                    )
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listSectionSpacing(20)
    }

    // MARK: - Search Results Section

    private var songsSection: some View {
        Section {
            ForEach(viewModel.songs) { song in
                SongRowView(song: song, imageSize: 52) {
                    songForOptions = song
                }
                .onTapGesture {
                    coordinator.navigateToPlayer(
                        song: song,
                        playlist: viewModel.allSongs
                    )
                }
                .onAppear {
                    if song.id == viewModel.songs.last?.id {
                        viewModel.loadMore()
                    }
                }
            }

            // Shown during the initial network fetch; loadMore() is synchronous so no spinner needed
            if viewModel.viewState == .loading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.secondaryText)
                    Spacer()
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listSectionSpacing(20)
    }

    // MARK: - States

    private var loadingView: some View {
        ProgressView()
            .tint(.secondaryText)
            .scaleEffect(1.5)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondaryText)
            Text("No results found")
                .font(.title3)
                .foregroundStyle(.primaryText)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondaryText)
            Text("Something went wrong")
                .font(.title3)
                .foregroundStyle(.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try again") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.bordered)
            .tint(.secondaryText)
        }
    }
}
