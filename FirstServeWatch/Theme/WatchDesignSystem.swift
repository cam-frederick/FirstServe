//
//  WatchDesignSystem.swift
//  FirstServe Watch
//
//  Court Nouveau for watchOS — distilled to its essence.
//  Dark editorial aesthetic adapted for the intimate wrist canvas.
//

import SwiftUI

// MARK: - Watch Color Palette

struct WatchColors {
    // Court Colors
    static let courtGreen = Color(red: 0.082, green: 0.278, blue: 0.196)
    static let clay = Color(red: 0.784, green: 0.384, blue: 0.278)
    static let hardCourt = Color(red: 0.196, green: 0.341, blue: 0.522)

    // Accents
    static let championship = Color(red: 0.847, green: 0.702, blue: 0.396)
    static let ballYellow = Color(red: 0.878, green: 0.925, blue: 0.208)
    static let ace = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let fault = Color(red: 0.898, green: 0.224, blue: 0.208)

    // Backgrounds
    static let backgroundDeep = Color(red: 0.051, green: 0.059, blue: 0.071)
    static let backgroundCard = Color(red: 0.086, green: 0.094, blue: 0.114)
    static let backgroundElevated = Color(red: 0.118, green: 0.129, blue: 0.153)

    // Text
    static let textPrimary = Color(red: 0.961, green: 0.957, blue: 0.941)
    static let textSecondary = Color(red: 0.608, green: 0.620, blue: 0.663)
    static let textMuted = Color(red: 0.404, green: 0.416, blue: 0.459)

    // Lines
    static let lineWhite = Color(red: 0.961, green: 0.957, blue: 0.941)
}

// MARK: - Watch Typography

struct WatchType {
    static func score(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }

    static func label(_ size: CGFloat = 9) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    static func mono(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Watch Serving Dot

struct WatchServingDot: View {
    var isServing: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(isServing ? WatchColors.ballYellow : Color.clear)
            .frame(width: 5, height: 5)
            .overlay(
                Circle()
                    .stroke(WatchColors.ballYellow.opacity(isServing ? 0.4 : 0), lineWidth: 1)
                    .scaleEffect(pulse ? 1.8 : 1)
                    .opacity(pulse ? 0 : 0.6)
            )
            .onAppear {
                guard isServing else { return }
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Watch Live Dot

struct WatchLiveDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(WatchColors.ace)
            .frame(width: 5, height: 5)
            .overlay(
                Circle()
                    .stroke(WatchColors.ace.opacity(0.4), lineWidth: 1)
                    .scaleEffect(pulse ? 2 : 1)
                    .opacity(pulse ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Court Line Accent (Watch)

struct WatchCourtLine: View {
    var width: CGFloat = 30

    var body: some View {
        Rectangle()
            .fill(WatchColors.lineWhite.opacity(0.12))
            .frame(width: width, height: 1.5)
    }
}
