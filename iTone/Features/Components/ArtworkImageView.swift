//
//  ArtworkImageView.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

// MARK: - Async Artwork Image with placeholder
struct ArtworkImageView: View {
    let url: URL?
    let size: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                case .empty:
                    placeholder.overlay {
                        ProgressView()
                            .tint(.secondaryText)
                    }
                @unknown default:
                    placeholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholder
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.surfaceBackground)
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondaryText)
                    .font(.system(size: size * 0.35))
            }
    }
}
