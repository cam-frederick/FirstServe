//
//  LiveMatchView.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData
import UIKit

struct LiveMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let match: Match
    @State private var viewModel = MatchViewModel()
    @State private var showingEndMatchAlert = false
    @State private var showingStatsSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    /// Drives the match-win confetti overlay
    @State private var showMatchConfetti = false
    
    /// Tracks the previous completion state so we fire confetti exactly once
    @State private var wasComplete = false
    
    /// Opacity for scoring button backgrounds — slightly higher in dark mode for legibility.
    private var buttonBgOpacity: Double { colorScheme == .dark ? 0.18 : 0.10 }
    
    var body: some View {
        ZStack {
            // ── Base layout ──
            VStack(spacing: 0) {
                matchHeader
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 24) {
                        scoreBoard
                        
                        if !match.isComplete {
                            currentGameScore
                            Divider()
                            scoringButtons
                            statsButtons
                        } else {
                            matchCompleteView
                        }
                    }
                    .padding()
                    // Swipe-left-to-undo gesture (FS-T9)
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                                if isHorizontal && value.translation.width < -80 && viewModel.canUndo && !match.isComplete {
                                    viewModel.undoLastPoint()
                                    triggerHaptic(.light)
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !match.isComplete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("End Match") { showingEndMatchAlert = true }
                    }
                }
            }
            
            // ── Match-win confetti overlay ──
            if showMatchConfetti {
                MatchConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .alert("End Match Early?", isPresented: $showingEndMatchAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Match", role: .destructive) {
                viewModel.endMatch()
                dismiss()
            }
        } message: {
            Text("This match is not complete. Are you sure you want to end it?")
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsView(match: match)
        }
        .onAppear {
            viewModel.configure(context: modelContext)
            viewModel.currentMatch = match
            wasComplete = match.isComplete
        }
        .onChange(of: match.isComplete) { _, newComplete in
            if newComplete && !wasComplete {
                showMatchConfetti = true
                wasComplete = true
                triggerHaptic(.heavy)
                // Auto-dismiss confetti after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showMatchConfetti = false
                }
            }
        }
    }
    
    // MARK: - Match Header
    
    private var matchHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label(match.surface.rawValue, systemImage: "sportscourt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(match.format.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Score Board
    
    private var scoreBoard: some View {
        VStack(spacing: 12) {
            playerScoreLine(
                name: match.players.first?.name ?? "Player 1",
                isPlayer1: true,
                isServing: match.currentSet?.currentGame?.serverIsPlayer1 ?? false,
                isWinner: match.winner?.id == match.players.first?.id
            )
            Divider()
            playerScoreLine(
                name: match.players.last?.name ?? "Player 2",
                isPlayer1: false,
                isServing: !(match.currentSet?.currentGame?.serverIsPlayer1 ?? true),
                isWinner: match.winner?.id == match.players.last?.id
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func playerScoreLine(name: String, isPlayer1: Bool, isServing: Bool, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                if isServing && !match.isComplete {
                    Image(systemName: "tennis.racket")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                Text(name)
                    .font(.headline)
                    .fontWeight(isWinner ? .bold : .regular)
                    .foregroundStyle(isWinner ? .green : .primary)
                if isWinner {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Set scores with animated transitions
            HStack(spacing: 12) {
                ForEach(match.sets.indices, id: \.self) { index in
                    let set = match.sets[index]
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    
                    Text("\(games)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: games)
                }
            }
        }
    }
    
    // MARK: - Current Game Score
    
    private var currentGameScore: some View {
        VStack(spacing: 8) {
            if let currentSet = match.currentSet, currentSet.isTiebreak {
                tiebreakScore(currentSet)
            } else {
                regularGameScore
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func tiebreakScore(_ currentSet: TennisSet) -> some View {
        VStack {
            Text("TIEBREAK")
                .font(.headline)
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
            
            HStack(spacing: 40) {
                scoreDigit(currentSet.tiebreakScorePlayer1 ?? 0, label: match.players.first?.name ?? "P1")
                Text("-").font(.title).foregroundStyle(.secondary)
                scoreDigit(currentSet.tiebreakScorePlayer2 ?? 0, label: match.players.last?.name  ?? "P2")
            }
            
            Text("First to 7, win by 2")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var regularGameScore: some View {
        VStack {
            Text("Current Game")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let game = match.currentSet?.currentGame {
                HStack(spacing: 40) {
                    scoreDigit(Int(game.scoreString(forPlayer1: true)) ?? 0,
                               label: match.players.first?.name ?? "P1",
                               scoreString: game.scoreString(forPlayer1: true))
                    Text("-").font(.title).foregroundStyle(.secondary)
                    scoreDigit(Int(game.scoreString(forPlayer1: false)) ?? 0,
                               label: match.players.last?.name  ?? "P2",
                               scoreString: game.scoreString(forPlayer1: false))
                }
            }
        }
    }
    
    /// Shared score-digit widget with spring animation
    private func scoreDigit(_ value: Int, label: String, scoreString: String? = nil) -> some View {
        VStack {
            Text(scoreString ?? "\(value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Scoring Buttons  (with haptic feedback)
    
    private var scoringButtons: some View {
        VStack(spacing: 16) {
            Text("Tap to Award Point")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 20) {
                // Player 1
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardPoint(toPlayer1: true)
                    }
                    triggerHaptic(.medium)
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                        Text(match.players.first?.name ?? "Player 1")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.blue.opacity(buttonBgOpacity))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
                }
                .accessibilityIdentifier("player1ScoreButton")
                
                // Player 2
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardPoint(toPlayer1: false)
                    }
                    triggerHaptic(.medium)
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                        Text(match.players.last?.name ?? "Player 2")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.green.opacity(buttonBgOpacity))
                    .foregroundStyle(.green)
                    .cornerRadius(12)
                }
                .accessibilityIdentifier("player2ScoreButton")
            }
            
            // Undo
            Button {
                viewModel.undoLastPoint()
                triggerHaptic(.light)
            } label: {
                Label("Undo", systemImage: "arrow.uturn.left")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canUndo)
            .opacity(viewModel.canUndo ? 1 : 0.4)
            .accessibilityIdentifier("undoButton")
        }
    }
    
    // MARK: - Stats Buttons
    
    private var statsButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingStatsSheet = true
            } label: {
                Label("View Stats", systemImage: "chart.bar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            HStack(spacing: 12) {
                aceMenu
                doubleFaultMenu
                winnerMenu
            }
        }
    }
    
    private var aceMenu: some View {
        Menu {
            Button("Player 1 Ace") {
                viewModel.recordAce(player1: true)
                viewModel.awardPoint(toPlayer1: true)
                triggerHaptic(.medium)
            }
            Button("Player 2 Ace") {
                viewModel.recordAce(player1: false)
                viewModel.awardPoint(toPlayer1: false)
                triggerHaptic(.medium)
            }
        } label: {
            Label("Ace", systemImage: "bolt.fill").font(.caption)
        }
        .buttonStyle(.bordered)
    }
    
    private var doubleFaultMenu: some View {
        Menu {
            Button("Player 1 DF") {
                viewModel.recordDoubleFault(player1: true)
                viewModel.awardPoint(toPlayer1: false)
                triggerHaptic(.medium)
            }
            Button("Player 2 DF") {
                viewModel.recordDoubleFault(player1: false)
                viewModel.awardPoint(toPlayer1: true)
                triggerHaptic(.medium)
            }
        } label: {
            Label("Double Fault", systemImage: "exclamationmark.2").font(.caption)
        }
        .buttonStyle(.bordered)
    }
    
    private var winnerMenu: some View {
        Menu {
            Button("Player 1 Winner") {
                viewModel.recordWinner(player1: true)
                viewModel.awardPoint(toPlayer1: true)
                triggerHaptic(.medium)
            }
            Button("Player 2 Winner") {
                viewModel.recordWinner(player1: false)
                viewModel.awardPoint(toPlayer1: false)
                triggerHaptic(.medium)
            }
        } label: {
            Label("Winner", systemImage: "star.fill").font(.caption)
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Match Complete View
    
    private var matchCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            if let winner = match.winner {
                Text("\(winner.name) Wins!")
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("Match Complete")
                    .font(.title)
            }
            
            Text("Final Score: \(match.scoreString)")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button {
                showingStatsSheet = true
            } label: {
                Label("View Full Stats", systemImage: "chart.bar.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Haptic Helper

/// Fire an impact haptic — centralised so we can swap generators later.
private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let gen = UIImpactFeedbackGenerator(style: style)
    gen.impactOccurred()
}

// MARK: - Match Confetti  (celebratory particle burst on match win)

private struct MatchConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                for p in particles {
                    var ctx = context
                    ctx.translateBy(x: p.x, y: p.y)
                    ctx.rotate(by: p.rotation)
                    let rect = CGRect(x: -6, y: -6, width: 12, height: 12)
                    ctx.fill(Path(rect), with: .color(p.color))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { spawnAndAnimate() }
    }
    
    private func spawnAndAnimate() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        particles = (0..<80).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -30,
                velocityY: CGFloat.random(in: 3...7),
                velocityX: CGFloat.random(in: -3...3),
                rotation: Angle(degrees: Double.random(in: 0...360)),
                rotationSpeed: Angle(degrees: Double.random(in: -8...8)),
                color: colors.randomElement() ?? .red
            )
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            // Stop after particles are well off-screen
            let allGone = particles.allSatisfy { $0.y > UIScreen.main.bounds.height + 60 }
            if allGone { timer.invalidate(); return }
            
            for i in 0..<particles.count {
                particles[i].y += particles[i].velocityY
                particles[i].x += particles[i].velocityX
                particles[i].velocityY += 0.08  // gravity
                particles[i].rotation += particles[i].rotationSpeed
            }
        }
    }
}

/// Shared particle model (also used by MelXWord CompletionView if linked).
struct ConfettiParticle {
    var x:             CGFloat
    var y:             CGFloat
    var velocityY:     CGFloat
    var velocityX:     CGFloat
    var rotation:      Angle
    var rotationSpeed: Angle
    var color:         Color
}

// MARK: - Stats Sheet

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    let match: Match
    
    var body: some View {
        NavigationStack {
            List {
                Section("Match Info") {
                    LabeledContent("Format",  value: match.format.rawValue)
                    LabeledContent("Surface", value: match.surface.rawValue)
                    if let loc = match.location { LabeledContent("Location", value: loc) }
                }
                
                Section("Score") {
                    LabeledContent("Sets", value: match.scoreString)
                }
                
                Section(match.players.first?.name ?? "Player 1") {
                    LabeledContent("Aces",            value: "\(match.acesPlayer1)")
                    LabeledContent("Double Faults",   value: "\(match.doubleFaultsPlayer1)")
                    LabeledContent("Winners",         value: "\(match.winnersPlayer1)")
                    LabeledContent("Unforced Errors", value: "\(match.unforcedErrorsPlayer1)")
                }
                
                Section(match.players.last?.name ?? "Player 2") {
                    LabeledContent("Aces",            value: "\(match.acesPlayer2)")
                    LabeledContent("Double Faults",   value: "\(match.doubleFaultsPlayer2)")
                    LabeledContent("Winners",         value: "\(match.winnersPlayer2)")
                    LabeledContent("Unforced Errors", value: "\(match.unforcedErrorsPlayer2)")
                }
            }
            .navigationTitle("Match Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, configurations: config)
    
    let player1 = Player(name: "Cam")
    let player2 = Player(name: "Opponent")
    let match   = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
    match.startNewSet()
    match.currentSet?.startNewGame(serverIsPlayer1: true)
    
    container.mainContext.insert(match)
    container.mainContext.insert(player1)
    container.mainContext.insert(player2)
    
    return NavigationStack {
        LiveMatchView(match: match)
    }
    .modelContainer(container)
}
