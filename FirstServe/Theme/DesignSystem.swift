//
//  DesignSystem.swift
//  FirstServe
//
//  Court Nouveau Design System - Premium Editorial Tennis Aesthetic
//

import SwiftUI

// MARK: - Color Palette

struct FSColors {
    // Primary Court Colors
    static let courtGreen = Color(red: 0.082, green: 0.278, blue: 0.196)      // Wimbledon deep green
    static let courtGreenLight = Color(red: 0.165, green: 0.463, blue: 0.333)
    static let clay = Color(red: 0.784, green: 0.384, blue: 0.278)            // Roland Garros terracotta
    static let clayLight = Color(red: 0.922, green: 0.678, blue: 0.541)
    static let hardCourt = Color(red: 0.196, green: 0.341, blue: 0.522)       // US Open blue
    static let hardCourtLight = Color(red: 0.384, green: 0.549, blue: 0.718)

    // Accent Colors
    static let championship = Color(red: 0.847, green: 0.702, blue: 0.396)    // Gold/brass
    static let ballYellow = Color(red: 0.878, green: 0.925, blue: 0.208)      // Tennis ball
    static let lineWhite = Color(red: 0.961, green: 0.957, blue: 0.941)       // Court line cream

    // Semantic Colors
    static let ace = Color(red: 1.0, green: 0.584, blue: 0.0)                 // Vibrant orange
    static let winner = Color(red: 0.298, green: 0.686, blue: 0.314)          // Success green
    static let fault = Color(red: 0.898, green: 0.224, blue: 0.208)           // Error red

    // Background Palette
    static let backgroundDeep = Color(red: 0.051, green: 0.059, blue: 0.071)  // Near black
    static let backgroundCard = Color(red: 0.086, green: 0.094, blue: 0.114)  // Card surface
    static let backgroundElevated = Color(red: 0.118, green: 0.129, blue: 0.153) // Elevated surface

    // Text Colors
    static let textPrimary = Color(red: 0.961, green: 0.957, blue: 0.941)
    static let textSecondary = Color(red: 0.608, green: 0.620, blue: 0.663)
    static let textMuted = Color(red: 0.404, green: 0.416, blue: 0.459)
}

// MARK: - Typography

struct FSTypography {
    // Display - For large scores and hero text
    static func display(_ size: CGFloat = 72) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }

    // Headline - Section titles
    static func headline(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    // Score - Numeric displays
    static func score(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }

    // Body - Regular text
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    // Label - Small labels and captions
    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    // Mono - Stats and data
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Gradients

struct FSGradients {
    static let courtGreen = LinearGradient(
        colors: [FSColors.courtGreen, FSColors.courtGreen.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let clay = LinearGradient(
        colors: [FSColors.clay, FSColors.clayLight.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let championship = LinearGradient(
        colors: [
            FSColors.championship.opacity(0.9),
            FSColors.championship,
            FSColors.championship.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSurface = LinearGradient(
        colors: [
            FSColors.backgroundCard,
            FSColors.backgroundCard.opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let meshBackground = MeshGradient(
        width: 3, height: 3,
        points: [
            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
        ],
        colors: [
            FSColors.backgroundDeep, FSColors.backgroundDeep, FSColors.courtGreen.opacity(0.15),
            FSColors.backgroundDeep, FSColors.backgroundCard, FSColors.hardCourt.opacity(0.1),
            FSColors.clay.opacity(0.08), FSColors.backgroundDeep, FSColors.backgroundDeep
        ]
    )
}

// MARK: - View Modifiers

struct FSCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(elevated ? FSColors.backgroundElevated : FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(elevated ? 0.4 : 0.2), radius: elevated ? 20 : 10, y: elevated ? 10 : 5)
    }
}

struct FSNetPattern: View {
    var opacity: Double = 0.03

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 20
                // Vertical lines
                for x in stride(from: 0, through: geo.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                // Horizontal lines
                for y in stride(from: 0, through: geo.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(FSColors.lineWhite.opacity(opacity), lineWidth: 0.5)
        }
    }
}

struct FSNoiseTexture: View {
    var opacity: Double = 0.015

    var body: some View {
        Image(systemName: "circle.fill")
            .resizable()
            .frame(width: 1, height: 1)
            .opacity(0)
            .background(
                Canvas { context, size in
                    for _ in 0..<Int(size.width * size.height * 0.1) {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                            with: .color(FSColors.lineWhite.opacity(Double.random(in: 0...opacity)))
                        )
                    }
                }
            )
    }
}

// MARK: - Button Styles

struct FSPrimaryButtonStyle: ButtonStyle {
    var color: Color = FSColors.courtGreen

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FSTypography.label(14))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(FSColors.textPrimary)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FSColors.lineWhite.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FSTypography.label(13))
            .fontWeight(.semibold)
            .foregroundStyle(FSColors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(FSColors.textMuted.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FSScoreButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(color.opacity(configuration.isPressed ? 0.3 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(color.opacity(0.4), lineWidth: 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension View {
    func fsCard(elevated: Bool = false) -> some View {
        modifier(FSCardStyle(elevated: elevated))
    }
}

// MARK: - Decorative Elements

struct CourtLineAccent: View {
    var width: CGFloat = 60

    var body: some View {
        Rectangle()
            .fill(FSColors.lineWhite.opacity(0.15))
            .frame(width: width, height: 3)
    }
}

struct ServingIndicator: View {
    var isServing: Bool

    var body: some View {
        Circle()
            .fill(isServing ? FSColors.ballYellow : Color.clear)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(FSColors.ballYellow.opacity(isServing ? 0.5 : 0.2), lineWidth: 2)
            )
            .shadow(color: isServing ? FSColors.ballYellow.opacity(0.5) : .clear, radius: 6)
    }
}

struct TrophyBadge: View {
    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(FSColors.championship)
            .padding(8)
            .background(
                Circle()
                    .fill(FSColors.championship.opacity(0.15))
            )
    }
}

// MARK: - Animated Components

struct PulsingDot: View {
    @State private var isPulsing = false
    var color: Color = FSColors.winner

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(isPulsing ? 2 : 1)
                    .opacity(isPulsing ? 0 : 0.8)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Surface Colors Helper

extension CourtSurface {
    var themeColor: Color {
        switch self {
        case .hardCourt: return FSColors.hardCourt
        case .clay: return FSColors.clay
        case .grass: return FSColors.courtGreen
        case .carpet: return FSColors.backgroundElevated
        }
    }

    var icon: String {
        switch self {
        case .hardCourt: return "square.fill"
        case .clay: return "circle.hexagonpath.fill"
        case .grass: return "leaf.fill"
        case .carpet: return "rectangle.split.3x3.fill"
        }
    }
}
