//
//  SongRowView.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

struct SongRowView: View {
    let song: Song
    var imageSize: CGFloat = 44
    var onMoreOptions: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            ArtworkImageView(url: song.artworkUrl?.resizedArtwork(), size: imageSize)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.songTitle)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.songArtist)
                    .foregroundStyle(.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let onMoreOptions {
                Button(action: onMoreOptions) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color(red: 0.33, green: 0.33, blue: 0.33))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
}
