//
//  PlayerView.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

struct PlayerView: View {
    let song: Song
    let playlist: [Song]

    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: PlayerViewModel
    @State private var showingMoreOptions = false
    @State private var showingRepeatTBD = false

    init(song: Song, playlist: [Song]) {
        self.song = song
        self.playlist = playlist
        self._viewModel = State(initialValue: PlayerViewModel(
            song: song,
            playlist: playlist,
            repository: SongRepositoryImpl(
                networkService: URLSessionNetworkService(),
                modelContainer: iToneModelContainer.shared
            ),
            audioPlayer: AVAudioPlayerService.shared
        ))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                artworkSection
                Spacer()

                VStack(spacing: 20) {
                    songInfoSection
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                    timelineSection
                    controlsSection
                }
                .frame(maxWidth: .infinity)
                .frame(height: 288)
                .padding(.horizontal, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .title) {
                Text(viewModel.currentSong.collectionName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.stopPlayback()
                    coordinator.navigateBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.primaryText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingMoreOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(.primaryText)
                }
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .onAppear { viewModel.play() }
        .sheet(isPresented: $showingMoreOptions) {
            MoreOptionsSheet(song: viewModel.currentSong) {
                coordinator.navigateToAlbum(
                    collectionId: viewModel.currentSong.collectionId,
                    title: viewModel.currentSong.collectionName
                )
            }
        }
    }

    // MARK: - Artwork

    private var artworkSection: some View {
        ArtworkImageView(
            url: viewModel.currentSong.artworkUrl?.resizedArtwork(),
            size: 264,
            cornerRadius: 16
        )
        .accessibilityLabel("Album artwork for \(viewModel.currentSong.name)")
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    // MARK: - Song Info

    private var songInfoSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.currentSong.name)
                    .font(.playerSongTitle)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)

                Text(viewModel.currentSong.artistName)
                    .font(.playerArtist)
                    .foregroundStyle(.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                viewModel.toggleRepeat()
                showingRepeatTBD = true
            } label: {
                Image(systemName: viewModel.isRepeating ? "repeat.1" : "repeat")
                    .font(.title2)
                    .foregroundStyle(viewModel.isRepeating ? .primaryText : .secondaryText)
            }
            .alert("TBD", isPresented: $showingRepeatTBD) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { viewModel.progress },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...1
            )
            .accessibilityLabel("Song progress")
            .accessibilityValue(
                "\(viewModel.formattedTime(viewModel.currentTime)) of \(viewModel.formattedTime(viewModel.duration))"
            )
            .tint(.primaryText.opacity(0.6))
            .frame(height: 24)

            HStack {
                Text(viewModel.formattedTime(viewModel.currentTime))
                    .font(.playerTimestamp)
                    .foregroundStyle(.primaryText.opacity(0.6))
                    .monospacedDigit()
                Spacer()
                Text(viewModel.formattedTime(viewModel.duration))
                    .font(.playerTimestamp)
                    .foregroundStyle(.primaryText.opacity(0.6))
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: 28) {
            Button {
                viewModel.playPrevious()
            } label: {
                Image(systemName: "backward.end.alt.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(viewModel.hasPrevious ? .primaryText : .secondaryText)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Previous")
            .buttonStyle(.plain)
            .disabled(!viewModel.hasPrevious)

            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.primaryText)
                    .frame(width: 72, height: 72)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            Button {
                viewModel.playNext()
            } label: {
                Image(systemName: "forward.end.alt.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(viewModel.hasNext ? .primaryText : .secondaryText)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Next")
            .buttonStyle(.plain)
            .disabled(!viewModel.hasNext)
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(
        id: 1,
        name: "Test Song",
        artistName: "Test Artist",
        collectionId: 1499209861,
        collectionName: "Test Album",
        artworkUrl: URL(string: ""),
        previewUrl: nil,
        trackNumber: 9
    )

    NavigationStack {
        PlayerView(song: song, playlist: [song])
            .environment(AppCoordinator())
    }
}
