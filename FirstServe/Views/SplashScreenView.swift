//
//  SplashScreenView.swift
//  FirstServe
//
//  Premium animated splash screen with serve trajectory animation
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showBackground = false
    @State private var showGlassCard = false
    @State private var showNumber = false
    @State private var arcProgress: CGFloat = 0
    @State private var showBall = false
    @State private var ballScale: CGFloat = 0
    @State private var showTitle = false
    @State private var titleLetterOffsets: [CGFloat] = Array(repeating: 30, count: 10)
    @State private var titleLetterOpacities: [Double] = Array(repeating: 0, count: 10)
    @State private var lightRayRotation: Double = 0
    @State private var isFinished = false

    var onFinished: () -> Void

    // Brand colors matching the icon
    private let deepNavy = Color(red: 0.1, green: 0.04, blue: 0.18)
    private let midNavy = Color(red: 0.086, green: 0.13, blue: 0.24)
    private let accentNavy = Color(red: 0.06, green: 0.2, blue: 0.38)
    private let serveOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let ballYellow = Color(red: 0.87, green: 1.0, blue: 0)
    private let ballGreen = Color(red: 0.6, green: 0.8, blue: 0.2)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep gradient background
                backgroundGradient
                    .opacity(showBackground ? 1 : 0)

                // Animated light rays
                lightRays
                    .opacity(showBackground ? 0.15 : 0)
                    .rotationEffect(.degrees(lightRayRotation))

                // Main content
                VStack(spacing: 40) {
                    Spacer()

                    // Logo composition
                    ZStack {
                        // Glass card
                        glassCard
                            .scaleEffect(showGlassCard ? 1 : 0.3)
                            .opacity(showGlassCard ? 1 : 0)

                        // Number "1"
                        numberOne
                            .opacity(showNumber ? 1 : 0)
                            .offset(y: showNumber ? 0 : 20)

                        // Animated serve arc
                        serveArc

                        // Tennis ball
                        tennisBall
                            .scaleEffect(ballScale)
                            .opacity(showBall ? 1 : 0)
                    }
                    .frame(width: 200, height: 180)

                    // App title with staggered animation
                    titleText
                        .opacity(showTitle ? 1 : 0)

                    Spacer()
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Background Components

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [deepNavy, midNavy, accentNavy]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lightRays: some View {
        ZStack {
            ForEach(0..<8) { i in
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 600)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }

    // MARK: - Glass Card

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 5, y: 10)
    }

    // MARK: - Number One

    private var numberOne: some View {
        Text("1")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .offset(x: -55, y: -45)
    }

    // MARK: - Serve Arc

    private var serveArc: some View {
        ServeArcShape(progress: arcProgress)
            .stroke(
                serveOrange,
                style: StrokeStyle(lineWidth: 7, lineCap: .round)
            )
            .frame(width: 140, height: 80)
            .offset(x: 5, y: 15)
    }

    // MARK: - Tennis Ball

    private var tennisBall: some View {
        ZStack {
            // Ball body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ballYellow, ballGreen],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 48, height: 48)

            // Seam lines
            BallSeams()
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: 48, height: 48)
        }
        .offset(x: 52, y: -12)  // Position at end of arc
    }

    // MARK: - Title Text

    private var titleText: some View {
        HStack(spacing: 0) {
            ForEach(Array("FirstServe".enumerated()), id: \.offset) { index, letter in
                Text(String(letter))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        index < 5 ? .white : serveOrange
                    )
                    .offset(y: titleLetterOffsets[index])
                    .opacity(titleLetterOpacities[index])
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Phase 1: Background fade in
        withAnimation(.easeOut(duration: 0.6)) {
            showBackground = true
        }

        // Start light ray rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            lightRayRotation = 360
        }

        // Phase 2: Glass card scales in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showGlassCard = true
            }
        }

        // Phase 3: Number "1" appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                showNumber = true
            }
        }

        // Phase 4: Serve arc draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.7)) {
                arcProgress = 1.0
            }
        }

        // Phase 5: Ball bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showBall = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                ballScale = 1.0
            }
        }

        // Phase 6: Title reveals letter by letter
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showTitle = true
            for i in 0..<10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        titleLetterOffsets[i] = 0
                        titleLetterOpacities[i] = 1
                    }
                }
            }
        }

        // Phase 7: Finish and transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isFinished = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onFinished()
            }
        }
    }
}

// MARK: - Custom Shapes

struct ServeArcShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Arc starts from lower left, curves up to upper right (where ball is)
        let startPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let endPoint = CGPoint(x: rect.maxX - 10, y: rect.minY)
        let controlPoint = CGPoint(x: rect.midX - 30, y: rect.minY - 20)

        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)

        return path.trimmedPath(from: 0, to: progress)
    }
}

struct BallSeams: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2

        // Left seam
        path.move(to: CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: center.x - radius * 0.35, y: center.y + radius * 0.7),
            control: CGPoint(x: center.x - radius * 0.9, y: center.y)
        )

        // Right seam
        path.move(to: CGPoint(x: center.x + radius * 0.35, y: center.y - radius * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 0.7),
            control: CGPoint(x: center.x + radius * 0.9, y: center.y)
        )

        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SplashScreenView(onFinished: {})
}
