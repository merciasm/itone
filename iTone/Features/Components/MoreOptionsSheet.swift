//
//  MoreOptionsSheet.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

struct MoreOptionsSheet: View {
    let song: Song
    var onViewAlbum: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center) {
                Text(song.name)
                    .font(.albumTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.albumArtist)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            .padding(.top, 30)

            Spacer()

            Button {
                dismiss()
                onViewAlbum()
            } label: {
                HStack(spacing: 16) {
                    Image("ic-setlist")
                        .foregroundStyle(.primaryText)
                        .frame(width: 24)
                    Text("View album")
                        .font(.playerArtist)
                        .foregroundStyle(.primaryText)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(192)])
        .presentationDragIndicator(.visible)
    }
}

