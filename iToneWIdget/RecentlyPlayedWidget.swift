//
//  RecentlyPlayedWidget.swift
//  iToneWIdget
//
//  Created by Mércia
//

import WidgetKit
import SwiftUI

struct RecentlyPlayedWidget: Widget {
    let kind = "RecentlyPlayedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentlyPlayedProvider()) { entry in
            RecentlyPlayedWidgetView(entry: entry)
        }
        .configurationDisplayName("Recently Played")
        .description("See your recently played songs from iTone.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
