//
//  LiveMatchView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

struct LiveMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let match: Match
    @State private var viewModel = MatchViewModel()
    @State private var showingEndMatchAlert = false
    @State private var showingStatsSheet = false
    @State private var appearAnimation = false
    @State private var scoreAnimation = false

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }

    var body: some View {
        ZStack {
            // Background
            FSColors.backgroundDeep
                .ignoresSafeArea()

            FSNetPattern(opacity: 0.02)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Match header bar
                matchHeader
                    .opacity(appearAnimation ? 1 : 0)

                ScrollView {
                    VStack(spacing: 24) {
                        // Main scoreboard
                        scoreBoard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)

                        if !match.isComplete {
                            // Current game/tiebreak score
                            currentGameScore
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                            // Point buttons
                            scoringButtons
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

                            // Quick stats
                            quickStatsSection
                                .opacity(appearAnimation ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
                        } else {
                            matchCompleteView
                                .opacity(appearAnimation ? 1 : 0)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !match.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEndMatchAlert = true
                    } label: {
                        Text("End")
                            .font(FSTypography.label(12))
                            .foregroundStyle(FSColors.fault)
                    }
                    .accessibilityLabel("End match early")
                    .accessibilityHint("Double tap to end the match before completion")
                }
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
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.configure(context: modelContext)
            viewModel.currentMatch = match
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Match Header

    private var matchHeader: some View {
        HStack {
            // Surface badge
            HStack(spacing: 6) {
                Image(systemName: match.surface.icon)
                    .font(.system(size: 11))
                Text(match.surface.rawValue)
                    .font(FSTypography.label(10))
                    .tracking(0.5)
            }
            .foregroundStyle(match.surface.themeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(match.surface.themeColor.opacity(0.15))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Surface: \(match.surface.rawValue)")

            Spacer()

            // Live indicator
            if !match.isComplete {
                HStack(spacing: 6) {
                    PulsingDot(color: FSColors.ace)
                    Text("LIVE")
                        .font(FSTypography.label(10))
                        .tracking(1)
                        .foregroundStyle(FSColors.ace)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Match in progress")
            }

            Spacer()

            // Format
            Text(match.format.rawValue)
                .font(FSTypography.label(10))
                .tracking(0.5)
                .foregroundStyle(FSColors.textMuted)
                .accessibilityLabel("Format: \(match.format.rawValue)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(FSColors.backgroundCard.opacity(0.8))
    }

    // MARK: - Scoreboard

    private var scoreBoard: some View {
        VStack(spacing: 0) {
            // Player 1 row
            playerScoreRow(
                name: player1?.name ?? "Player 1",
                isPlayer1: true,
                isServing: match.currentSet?.currentGame?.serverIsPlayer1 ?? false,
                isWinner: match.winner?.id == player1?.id
            )

            // Divider
            Rectangle()
                .fill(FSColors.lineWhite.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Player 2 row
            playerScoreRow(
                name: player2?.name ?? "Player 2",
                isPlayer1: false,
                isServing: !(match.currentSet?.currentGame?.serverIsPlayer1 ?? true),
                isWinner: match.winner?.id == player2?.id
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
    }

    private func playerScoreRow(name: String, isPlayer1: Bool, isServing: Bool, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            // Serving indicator + Name
            HStack(spacing: 12) {
                ServingIndicator(isServing: isServing && !match.isComplete)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(FSTypography.body(17))
                        .fontWeight(isWinner ? .bold : .medium)
                        .foregroundStyle(isWinner ? FSColors.championship : FSColors.textPrimary)

                    if isServing && !match.isComplete {
                        Text("SERVING")
                            .font(FSTypography.label(8))
                            .tracking(1)
                            .foregroundStyle(FSColors.ballYellow)
                    }
                }

                if isWinner {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FSColors.championship)
                }
            }

            Spacer()

            // Set scores
            HStack(spacing: 12) {
                ForEach(match.sets.indices, id: \.self) { index in
                    let set = match.sets[index]
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    let otherGames = isPlayer1 ? set.gamesPlayer2 : set.gamesPlayer1
                    let won = games > otherGames
                    let isCurrentSet = index == match.sets.count - 1 && !match.isComplete

                    Text("\(games)")
                        .font(FSTypography.score(28))
                        .foregroundStyle(won ? FSColors.textPrimary : FSColors.textMuted)
                        .frame(minWidth: 32)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isCurrentSet ? FSColors.backgroundElevated : Color.clear)
                        )
                        .accessibilityLabel("Set \(index + 1): \(games) games")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(buildPlayerRowAccessibilityLabel(name: name, isPlayer1: isPlayer1, isServing: isServing, isWinner: isWinner))
    }
    
    private func buildPlayerRowAccessibilityLabel(name: String, isPlayer1: Bool, isServing: Bool, isWinner: Bool) -> String {
        var label = name
        if isWinner {
            label += ", winner"
        }
        if isServing && !match.isComplete {
            label += ", currently serving"
        }
        
        // Add set scores
        let sets = match.sets.enumerated().map { index, set -> String in
            let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
            return "Set \(index + 1): \(games)"
        }.joined(separator: ", ")
        
        label += ". " + sets
        return label
    }

    // MARK: - Current Game Score

    private var currentGameScore: some View {
        VStack(spacing: 16) {
            if let currentSet = match.currentSet, currentSet.isTiebreak {
                // Tiebreak
                tiebreakScoreDisplay(set: currentSet)
            } else if let game = match.currentSet?.currentGame {
                // Regular game
                regularGameScoreDisplay(game: game)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func tiebreakScoreDisplay(set: TennisSet) -> some View {
        VStack(spacing: 16) {
            // Tiebreak badge
            Text("TIEBREAK")
                .font(FSTypography.label(11))
                .tracking(3)
                .foregroundStyle(FSColors.ace)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(FSColors.ace.opacity(0.15))
                )

            // Scores
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("\(set.tiebreakScorePlayer1 ?? 0)")
                        .font(FSTypography.display(64))
                        .foregroundStyle(FSColors.textPrimary)

                    Text(player1?.name ?? "P1")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }

                Text("–")
                    .font(FSTypography.score(40))
                    .foregroundStyle(FSColors.textMuted)

                VStack(spacing: 8) {
                    Text("\(set.tiebreakScorePlayer2 ?? 0)")
                        .font(FSTypography.display(64))
                        .foregroundStyle(FSColors.textPrimary)

                    Text(player2?.name ?? "P2")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }
            }

            Text("First to 7, win by 2")
                .font(FSTypography.label(10))
                .foregroundStyle(FSColors.textMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tiebreak: \(player1?.name ?? "Player 1") \(set.tiebreakScorePlayer1 ?? 0), \(player2?.name ?? "Player 2") \(set.tiebreakScorePlayer2 ?? 0). First to 7, win by 2")
    }

    private func regularGameScoreDisplay(game: Game) -> some View {
        VStack(spacing: 16) {
            Text("CURRENT GAME")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(game.scoreString(forPlayer1: true))
                        .font(FSTypography.display(64))
                        .foregroundStyle(FSColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(player1?.name ?? "P1")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }

                Text("–")
                    .font(FSTypography.score(40))
                    .foregroundStyle(FSColors.textMuted)

                VStack(spacing: 8) {
                    Text(game.scoreString(forPlayer1: false))
                        .font(FSTypography.display(64))
                        .foregroundStyle(FSColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(player2?.name ?? "P2")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current game: \(player1?.name ?? "Player 1") \(game.scoreString(forPlayer1: true)), \(player2?.name ?? "Player 2") \(game.scoreString(forPlayer1: false))")
    }

    // MARK: - Scoring Buttons

    private var scoringButtons: some View {
        VStack(spacing: 16) {
            Text("TAP TO AWARD POINT")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 16) {
                // Player 1 button
                scoreButton(
                    name: player1?.name ?? "Player 1",
                    color: FSColors.hardCourt
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardPoint(toPlayer1: true)
                    }
                }

                // Player 2 button
                scoreButton(
                    name: player2?.name ?? "Player 2",
                    color: FSColors.clay
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardPoint(toPlayer1: false)
                    }
                }
            }

            // Undo button
            Button {
                viewModel.undoLastPoint()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Undo Last Point")
                        .font(FSTypography.label(12))
                }
                .foregroundStyle(viewModel.canUndo ? FSColors.textSecondary : FSColors.textMuted.opacity(0.5))
            }
            .disabled(!viewModel.canUndo)
            .padding(.top, 8)
            .accessibilityLabel("Undo last point")
            .accessibilityHint(viewModel.canUndo ? "Double tap to undo the last point awarded" : "No points to undo")
        }
    }

    private func scoreButton(name: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(color)
                }

                Text(name)
                    .font(FSTypography.body(15))
                    .fontWeight(.semibold)
                    .foregroundStyle(FSColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.25), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(FSScoreButtonStyle(color: color))
        .accessibilityLabel("Award point to \(name)")
        .accessibilityHint("Double tap to give \(name) one point")
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("QUICK STATS")
                    .font(FSTypography.label(10))
                    .tracking(2)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()

                Button {
                    showingStatsSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(FSTypography.label(10))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }
                .accessibilityLabel("View all statistics")
                .accessibilityHint("Double tap to open detailed match statistics")
            }

            HStack(spacing: 12) {
                quickStatButton(
                    label: "Ace",
                    icon: "bolt.fill",
                    color: FSColors.ace,
                    player1Action: {
                        viewModel.recordAce(player1: true)
                        viewModel.awardPoint(toPlayer1: true)
                    },
                    player2Action: {
                        viewModel.recordAce(player1: false)
                        viewModel.awardPoint(toPlayer1: false)
                    }
                )

                quickStatButton(
                    label: "Double Fault",
                    icon: "xmark",
                    color: FSColors.fault,
                    player1Action: {
                        viewModel.recordDoubleFault(player1: true)
                        viewModel.awardPoint(toPlayer1: false)
                    },
                    player2Action: {
                        viewModel.recordDoubleFault(player1: false)
                        viewModel.awardPoint(toPlayer1: true)
                    }
                )

                quickStatButton(
                    label: "Winner",
                    icon: "star.fill",
                    color: FSColors.winner,
                    player1Action: {
                        viewModel.recordWinner(player1: true)
                        viewModel.awardPoint(toPlayer1: true)
                    },
                    player2Action: {
                        viewModel.recordWinner(player1: false)
                        viewModel.awardPoint(toPlayer1: false)
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func quickStatButton(label: String, icon: String, color: Color, player1Action: @escaping () -> Void, player2Action: @escaping () -> Void) -> some View {
        Menu {
            Button {
                player1Action()
            } label: {
                Label(player1?.name ?? "Player 1", systemImage: "person.fill")
            }

            Button {
                player2Action()
            } label: {
                Label(player2?.name ?? "Player 2", systemImage: "person.fill")
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)

                Text(label)
                    .font(FSTypography.label(9))
                    .foregroundStyle(FSColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to select which player scored a \(label.lowercased())")
    }

    // MARK: - Match Complete

    private var matchCompleteView: some View {
        VStack(spacing: 28) {
            // Trophy celebration
            ZStack {
                Circle()
                    .fill(FSColors.championship.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(FSColors.championship.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FSColors.championship, FSColors.championship.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: FSColors.championship.opacity(0.4), radius: 30)

            VStack(spacing: 12) {
                if let winner = match.winner {
                    Text(winner.name)
                        .font(FSTypography.headline(36))
                        .foregroundStyle(FSColors.textPrimary)

                    Text("WINS!")
                        .font(FSTypography.label(14))
                        .tracking(4)
                        .foregroundStyle(FSColors.championship)
                }

                Text(match.scoreString)
                    .font(FSTypography.score(28))
                    .foregroundStyle(FSColors.textSecondary)
                    .padding(.top, 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(match.winner?.name ?? "Unknown") wins! Final score: \(match.scoreString)")

            HStack(spacing: 12) {
                // Share button
                ShareLink(item: generateShareText()) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share Result")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(FSColors.courtGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                
                // Stats button
                Button {
                    showingStatsSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("View Stats")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(FSColors.championship)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .accessibilityLabel("View match statistics")
            .accessibilityHint("Double tap to view detailed match statistics")
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Share Functionality
    
    private func generateShareText() -> String {
        var text = "🎾 FirstServe Match Result\n\n"
        
        // Winner announcement
        if let winner = match.winner {
            text += "\(winner.name) wins!\n"
        }
        
        // Score
        text += "\(match.scoreString)\n\n"
        
        // Match info
        text += "📍 \(match.surface.rawValue)\n"
        text += "🏆 \(match.format.rawValue)\n"
        
        // Duration if available
        if let completedAt = match.completedAt {
            let duration = completedAt.timeIntervalSince(match.createdAt)
            let minutes = Int(duration) / 60
            if minutes < 60 {
                text += "⏱️ \(minutes)m\n"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                text += "⏱️ \(hours)h \(mins)m\n"
            }
        }
        
        // Key stats if notable
        let totalAces = match.acesPlayer1 + match.acesPlayer2
        let totalWinners = match.winnersPlayer1 + match.winnersPlayer2
        
        if totalAces > 0 {
            text += "⚡ \(totalAces) aces\n"
        }
        if totalWinners > 0 {
            text += "⭐ \(totalWinners) winners\n"
        }
        
        text += "\n#FirstServe #Tennis"
        
        return text
    }
}

// MARK: - Stats Sheet View

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    let match: Match

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }

    var body: some View {
        NavigationStack {
            ZStack {
                FSColors.backgroundDeep
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Match info
                        infoSection

                        // Stats comparison
                        statsComparisonSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(FSColors.textPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MATCH INFO")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            VStack(spacing: 12) {
                infoRow(label: "Format", value: match.format.rawValue)
                infoRow(label: "Surface", value: match.surface.rawValue)
                if let location = match.location {
                    infoRow(label: "Location", value: location)
                }
                infoRow(label: "Score", value: match.scoreString)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FSColors.backgroundCard)
            )
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(FSTypography.body(14))
                .foregroundStyle(FSColors.textSecondary)
            Spacer()
            Text(value)
                .font(FSTypography.body(14))
                .fontWeight(.medium)
                .foregroundStyle(FSColors.textPrimary)
        }
    }

    private var statsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(player1?.name ?? "P1")
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.hardCourt)
                    .frame(width: 80, alignment: .leading)

                Spacer()

                Text("STAT")
                    .font(FSTypography.label(10))
                    .tracking(1)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()

                Text(player2?.name ?? "P2")
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.clay)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                statRow(label: "Aces", p1: match.acesPlayer1, p2: match.acesPlayer2, icon: "bolt.fill")
                Divider().background(FSColors.lineWhite.opacity(0.06))
                statRow(label: "Double Faults", p1: match.doubleFaultsPlayer1, p2: match.doubleFaultsPlayer2, icon: "xmark")
                Divider().background(FSColors.lineWhite.opacity(0.06))
                statRow(label: "Winners", p1: match.winnersPlayer1, p2: match.winnersPlayer2, icon: "star.fill")
                Divider().background(FSColors.lineWhite.opacity(0.06))
                statRow(label: "Unforced Errors", p1: match.unforcedErrorsPlayer1, p2: match.unforcedErrorsPlayer2, icon: "exclamationmark.triangle.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FSColors.backgroundCard)
            )
        }
    }

    private func statRow(label: String, p1: Int, p2: Int, icon: String) -> some View {
        HStack {
            Text("\(p1)")
                .font(FSTypography.score(24))
                .foregroundStyle(p1 > p2 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 50, alignment: .leading)

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(FSColors.textMuted)
                Text(label)
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.textSecondary)
            }

            Spacer()

            Text("\(p2)")
                .font(FSTypography.score(24))
                .foregroundStyle(p2 > p1 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, configurations: config)

    let player1 = Player(name: "Cam")
    let player2 = Player(name: "Opponent")
    let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
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
