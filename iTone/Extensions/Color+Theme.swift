//
//  Color+Theme.swift
//  iTone
//
//  Created by Mércia
//

import SwiftUI

extension Color {
    // MARK: - Background
    static let appBackground = Color.black
    static let surfaceBackground = Color.white.opacity(0.1)

    // MARK: - Text
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.45)

}

// MARK: - ShapeStyle shorthand so .primaryText / .accentOrange etc. work in foregroundStyle
extension ShapeStyle where Self == Color {
    static var appBackground: Color { .appBackground }
    static var surfaceBackground: Color { .surfaceBackground }
    static var primaryText: Color { .primaryText }
    static var secondaryText: Color { .secondaryText }
}
