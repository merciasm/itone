//
//  PlayerViewModel.swift
//  iTone
//
//  Created by Mércia
//

import Foundation

// MARK: - Player ViewModel
@MainActor
@Observable
final class PlayerViewModel {
    var currentSong: Song
    var playlist: [Song]

    private let audioPlayer: AudioPlayerServiceProtocol
    private let repository: SongRepositoryProtocol

    var isRepeating: Bool = false

    var isPlaying: Bool { audioPlayer.isPlaying }
    var currentTime: Double { audioPlayer.currentTime }
    var duration: Double { audioPlayer.duration }
    var progress: Double { audioPlayer.progress }

    var hasPrevious: Bool {
        currentIndex > 0
    }

    var hasNext: Bool {
        currentIndex < playlist.count - 1
    }

    private var currentIndex: Int {
        playlist.firstIndex(of: currentSong) ?? 0
    }

    init(song: Song,
         playlist: [Song],
         repository: SongRepositoryProtocol,
         audioPlayer: AudioPlayerServiceProtocol) {
        self.currentSong = song
        self.playlist = playlist
        self.repository = repository
        self.audioPlayer = audioPlayer
    }

    // MARK: - Playback

    func play() {
        Task { try? await repository.markAsPlayed(currentSong) }
        guard let url = currentSong.previewUrl else { return }
        audioPlayer.play(url: url)
    }

    func togglePlayPause() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if audioPlayer.currentTime > 0 {
                audioPlayer.resume()
            } else {
                play()
            }
        }
    }

    func seek(to progress: Double) {
        let time = progress * audioPlayer.duration
        audioPlayer.seek(to: time)
    }

    func playNext() {
        guard hasNext else { return }
        currentSong = playlist[currentIndex + 1]
        play()
    }

    func playPrevious() {
        // If > 3s in, restart; otherwise go back
        if audioPlayer.currentTime > 3 {
            audioPlayer.seek(to: 0)
        } else if hasPrevious {
            currentSong = playlist[currentIndex - 1]
            play()
        }
    }

    func toggleRepeat() {
        isRepeating.toggle()
    }

    func stopPlayback() {
        audioPlayer.stop()
    }

    // MARK: - Formatting

    func formattedTime(_ seconds: Double) -> String {
        guard !seconds.isNaN, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
