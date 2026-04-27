//
//  RecentlyPlayedWidgetView.swift
//  iToneWIdget
//
//  Created by Mércia
//

import SwiftUI
import WidgetKit

struct RecentlyPlayedWidgetView: View {
    let entry: RecentlyPlayedEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if entry.songs.isEmpty {
                emptyState
            } else {
                switch family {
                case .systemSmall:
                    smallWidget
                default:
                    mediumWidget
                }
            }
        }
        .containerBackground(.black, for: .widget)
    }

    // MARK: - Small Widget (single song)

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if let song = entry.songs.first {
                Spacer(minLength: 0)
                artworkPlaceholder(size: 48)
                Text(song.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(entry.songs.first.map { songURL(song: $0) })
    }

    // MARK: - Medium Widget (4 recent albums in a horizontal row)

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            HStack(spacing: 8) {
                ForEach(Array(entry.recentAlbums.prefix(4).enumerated()), id: \.offset) { _, song in
                    VStack(alignment: .leading, spacing: 4) {
                        artworkPlaceholder(size: 60)
                        Text(song.collectionName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(song.artistName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(white: 0.45))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Link(destination: albumURL(collectionId: song.collectionId, title: song.collectionName)) {
                            Color.clear
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared Components

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "music.note")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(white: 0.45))
            Text(family == .systemSmall ? "Recently Played" : "Recent Albums")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(white: 0.45))
                .textCase(.uppercase)
        }
    }

    private func artworkPlaceholder(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.white.opacity(0.1))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(Color(white: 0.45))
            }
    }

    private func songURL(song: Song) -> URL {
        var components = URLComponents()
        components.scheme = "iTone"
        components.host = "song"
        components.queryItems = [
            URLQueryItem(name: "id", value: "\(song.id)"),
            URLQueryItem(name: "name", value: song.name),
            URLQueryItem(name: "artist", value: song.artistName),
            URLQueryItem(name: "collectionId", value: "\(song.collectionId)"),
            URLQueryItem(name: "collectionName", value: song.collectionName),
            URLQueryItem(name: "artwork", value: song.artworkUrl?.absoluteString),
            URLQueryItem(name: "preview", value: song.previewUrl?.absoluteString),
            URLQueryItem(name: "trackNumber", value: "\(song.trackNumber)")
        ]
        return components.url ?? URL(string: "iTone://song")!
    }

    private func albumURL(collectionId: Int, title: String) -> URL {
        var components = URLComponents()
        components.scheme = "iTone"
        components.host = "album"
        components.queryItems = [
            URLQueryItem(name: "id", value: "\(collectionId)"),
            URLQueryItem(name: "title", value: title)
        ]
        return components.url ?? URL(string: "iTone://album")!
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 24))
                .foregroundStyle(Color(white: 0.45))
            Text("No recent songs")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(white: 0.45))
            Text("Play a song in iTone")
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.35))
        }
    }
}
