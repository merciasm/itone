//
//  AudioPlayerService.swift
//  iTone
//
//  Created by Mércia
//

import Foundation
import AVFoundation

// MARK: - Audio Player Protocol
@MainActor
protocol AudioPlayerServiceProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: Double { get }
    var duration: Double { get }
    var progress: Double { get }

    func play(url: URL)
    func pause()
    func resume()
    func seek(to time: Double)
    func stop()
}

// MARK: - AVPlayer Implementation
@MainActor
@Observable
final class AVAudioPlayerService: AudioPlayerServiceProtocol {
    static let shared = AVAudioPlayerService()

    private var player: AVPlayer?
    private var timeObserver: Any?

    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 0
    var progress: Double = 0

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }

    func play(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        Task {
            do {
                let cmDuration = try await item.asset.load(.duration)
                duration = cmDuration.seconds.isNaN ? 0 : cmDuration.seconds
            } catch {
                duration = 0
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        addPeriodicObserver()
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        progress = duration > 0 ? time / duration : 0
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        progress = 0
    }

    // MARK: - Private

    private func addPeriodicObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let seconds = time.seconds
            guard !seconds.isNaN else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                self.currentTime = seconds
                self.progress = self.duration > 0 ? seconds / self.duration : 0
            }
        }
    }

    @objc private func playerDidFinish() {
        isPlaying = false
        currentTime = 0
        progress = 0
    }
}
