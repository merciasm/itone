//
//  Font+Theme.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

extension Font {
    // MARK: - Songs Screen
    static let songTitle: Font = .system(size: 16, weight: .medium)
    static let songArtist: Font = .system(size: 12, weight: .medium)

    // MARK: - Player Screen
    static let playerSongTitle: Font = .system(size: 32, weight: .semibold)
    static let playerArtist: Font = .system(size: 16, weight: .medium)
    static let playerTimestamp: Font = .system(size: 14, weight: .medium)

    // MARK: - Album Screen
    static let albumTitle: Font = .system(size: 20, weight: .semibold)
    static let albumArtist: Font = .system(size: 14, weight: .medium)
    static let albumSongTitle: Font = .system(size: 16, weight: .medium)
    static let albumSongArtist: Font = .system(size: 12, weight: .medium)
}
