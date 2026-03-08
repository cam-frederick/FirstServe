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
    @State private var showingMatchSummary = false
    @State private var shotPickerStatType: StatType = .winner
    @State private var shotPickerIsPlayer1 = true
    @State private var appearAnimation = false
    @State private var shotPickerPhase: ShotPickerPhase = .hidden
    @State private var selectedContactType: ContactType?

    private enum ShotPickerPhase {
        case hidden
        case selectResultType
        case selectContactType
        case selectShotType
    }
    @State private var scoreAnimation = false
    @State private var isFirstServe = true
    @State private var showServeIndicator = false

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
                            if match.scoringMode == .gamesOnly {
                                // Games-only: just award games directly
                                gamesOnlyScoringButtons
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
                            } else {
                                // Points and Full Stats: show current game score
                                currentGameScore
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                                // Full Stats only: serve flow + live stats bar
                                if match.scoringMode == .fullStats {
                                    serveFlowSection
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 20)
                                        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)
                                }

                                if match.scoringMode == .fullStats {
                                    // Full Stats: integrated flow — pick who won → result type → shot details
                                    if shotPickerPhase == .hidden {
                                        fullStatsScoringButtons
                                            .opacity(appearAnimation ? 1 : 0)
                                            .offset(y: appearAnimation ? 0 : 20)
                                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
                                    } else {
                                        inlineShotPicker
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                } else {
                                    // Points mode: simple point buttons
                                    scoringButtons
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 20)
                                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
                                }
                            }
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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(FSTypography.label(13))
                        }
                        .foregroundStyle(FSColors.textSecondary)
                    }
                    .accessibilityLabel("Go back")

                }
            }

            if !match.isComplete && match.scoringMode != .gamesOnly {
                ToolbarItem(placement: .principal) {
                    Button {
                        showingStatsSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 12))
                            Text("Stats")
                                .font(FSTypography.label(12))
                        }
                        .foregroundStyle(FSColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(FSColors.backgroundElevated)
                        )
                    }
                    .accessibilityLabel("View match statistics")
                }
            }

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
        .sheet(isPresented: $showingMatchSummary) {
            MatchSummaryView(match: match)
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
        ZStack {
            // Surface (leading) and Format (trailing)
            HStack {
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

                Text(match.format.displayName)
                    .font(FSTypography.label(10))
                    .tracking(0.5)
                    .foregroundStyle(FSColors.textMuted)
                    .accessibilityLabel("Format: \(match.format.displayName)")
            }

            // Live indicator (centered)
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
                isServing: (match.currentSet?.currentGame ?? match.currentSet?.latestGame)?.serverIsPlayer1 ?? false,
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
                isServing: !((match.currentSet?.currentGame ?? match.currentSet?.latestGame)?.serverIsPlayer1 ?? true),
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

                    // Determine tiebreak loser score to show as superscript.
                    // Tennis convention: show the loser's tiebreak score next to the "6"
                    // e.g. "6⁷" (loser showed 6 tiebreak points when they lost 6-7).
                    let tbP1 = set.tiebreakScorePlayer1
                    let tbP2 = set.tiebreakScorePlayer2
                    let tiebreakWasPlayed = tbP1 != nil && tbP2 != nil && !isCurrentSet
                    let myTbScore = isPlayer1 ? tbP1 : tbP2
                    let theirTbScore = isPlayer1 ? tbP2 : tbP1
                    // Show the loser's tiebreak score — if this player lost the tiebreak,
                    // it's their score; if they won, it's the opponent's score.
                    let loserTbScore: Int? = tiebreakWasPlayed
                        ? (won ? theirTbScore : myTbScore)
                        : nil

                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 0) {
                            Text("\(games)")
                                .font(FSTypography.score(28))
                                .foregroundStyle(won ? FSColors.textPrimary : FSColors.textMuted)
                            
                            // Show "PTS" label for super set to disambiguate from games
                            if match.format == .superSet && isCurrentSet {
                                Text("PTS")
                                    .font(FSTypography.label(7))
                                    .tracking(0.5)
                                    .foregroundStyle(FSColors.textMuted.opacity(0.7))
                            }
                        }
                        .frame(minWidth: 32)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isCurrentSet ? FSColors.backgroundElevated : Color.clear)
                        )

                        // Superscript tiebreak score (loser's score, tennis convention)
                        if let loser = loserTbScore {
                            Text("(\(loser))")
                                .font(FSTypography.label(9))
                                .foregroundStyle(FSColors.textMuted)
                                .offset(x: 2, y: -2)
                        }
                    }
                    .accessibilityLabel({
                        var label = "Set \(index + 1): \(games) games"
                        if let loser = loserTbScore {
                            label += ", tiebreak \(won ? (theirTbScore ?? 0) : (myTbScore ?? 0))-\(loser)"
                        }
                        return label
                    }())
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

    // MARK: - Serve Flow Section

    private var serveFlowSection: some View {
        VStack(spacing: 16) {
            // Serve indicator badge
            HStack(spacing: 12) {
                Image(systemName: isFirstServe ? "1.circle.fill" : "2.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isFirstServe ? FSColors.ace : FSColors.fault)
                
                Text(isFirstServe ? "FIRST SERVE" : "SECOND SERVE")
                    .font(FSTypography.label(11))
                    .tracking(2)
                    .foregroundStyle(isFirstServe ? FSColors.ace : FSColors.fault)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill((isFirstServe ? FSColors.ace : FSColors.fault).opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(isFirstServe ? FSColors.ace : FSColors.fault, lineWidth: 1.5)
                    )
            )
            .scaleEffect(showServeIndicator ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showServeIndicator)
            
            // Quick serve recording buttons
            VStack(spacing: 12) {
                Text("SERVE OUTCOME")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)

                HStack(spacing: 10) {
                    serveOutcomeButton(
                        label: "Service\nWinner",
                        icon: "star.fill",
                        color: FSColors.winner
                    ) {
                        recordServeOutcome(made: true, ace: false, serviceWinner: true)
                    }

                    serveOutcomeButton(
                        label: "Ace",
                        icon: "bolt.fill",
                        color: FSColors.ace
                    ) {
                        recordServeOutcome(made: true, ace: true)
                    }

                    serveOutcomeButton(
                        label: "Fault",
                        icon: "xmark.circle.fill",
                        color: FSColors.fault
                    ) {
                        recordServeOutcome(made: false, ace: false)
                    }
                }
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
    
    private func serveOutcomeButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)

                Text(label)
                    .font(FSTypography.label(11))
                    .foregroundStyle(FSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
    
    // MARK: - Live Serve Stats Bar
    
    /// Compact serve % bar displayed below the serve flow section during a live match.
    /// Gives the server real-time first serve % feedback without opening the stats sheet.
    private var liveServeStatsBar: some View {
        let p1Pct = match.firstServePercentagePlayer1
        let p2Pct = match.firstServePercentagePlayer2
        let isP1Serving = (match.currentSet?.currentGame ?? match.currentSet?.latestGame)?.serverIsPlayer1 ?? true
        let serverPct = isP1Serving ? p1Pct : p2Pct
        let serverName = isP1Serving ? (player1?.name ?? "P1") : (player2?.name ?? "P2")
        let hasStat = (isP1Serving ? match.firstServeAttemptsPlayer1 : match.firstServeAttemptsPlayer2) > 0
        
        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(FSColors.textMuted)
                Text("LIVE SERVE %")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)
                Spacer()
            }
            
            if hasStat {
                VStack(spacing: 6) {
                    HStack {
                        Text("\(serverName)")
                            .font(FSTypography.label(10))
                            .foregroundStyle(FSColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.0f%%", serverPct))
                            .font(FSTypography.label(11))
                            .fontWeight(.semibold)
                            .foregroundStyle(serverPct >= 60 ? FSColors.ace : serverPct >= 45 ? FSColors.ballYellow : FSColors.fault)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(FSColors.backgroundElevated)
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: serverPct >= 60 ? [FSColors.ace, FSColors.ace.opacity(0.7)] :
                                                serverPct >= 45 ? [FSColors.ballYellow, FSColors.ballYellow.opacity(0.7)] :
                                                                   [FSColors.fault, FSColors.fault.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(serverPct / 100.0), height: 6)
                                .animation(.easeInOut(duration: 0.4), value: serverPct)
                        }
                    }
                    .frame(height: 6)
                }
            } else {
                HStack {
                    Text("No serves recorded yet")
                        .font(FSTypography.label(10))
                        .foregroundStyle(FSColors.textMuted)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasStat
            ? "\(serverName) first serve: \(String(format: "%.0f", serverPct))%"
            : "No serves recorded yet")
    }
    
    private func recordServeOutcome(made: Bool, ace: Bool, serviceWinner: Bool = false) {
        guard let currentSet = match.currentSet,
              let currentGame = currentSet.currentGame else { return }

        let isServer = currentGame.serverIsPlayer1

        // Capture undo snapshot before any stats are modified
        if ace || serviceWinner || (!made && !isFirstServe) {
            viewModel.prepareUndo()
        }

        // Record the serve in match stats
        let pointWon = ace || serviceWinner
        match.recordServe(forPlayer1: isServer, firstServe: isFirstServe, made: made, pointWon: pointWon ? true : nil)

        if ace {
            // Ace: returner doesn't touch the ball
            viewModel.recordAce(player1: isServer)
            viewModel.awardPoint(toPlayer1: isServer)
            pointAwardedHaptic()
            isFirstServe = true
            showServeIndicator = false
        } else if serviceWinner {
            // Service winner: returner got to it but couldn't return it in
            viewModel.recordWinner(player1: isServer, shotType: nil, contactType: .serve)
            viewModel.awardPoint(toPlayer1: isServer)
            pointAwardedHaptic()
            isFirstServe = true
            showServeIndicator = false
        } else if made {
            // Serve in: point continues (dead path, kept for safety)
            showServeIndicator = false
        } else {
            // Fault
            if isFirstServe {
                // First serve fault -> switch to second serve
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFirstServe = false
                    showServeIndicator = true
                }
            } else {
                // Double fault -> opponent wins point
                viewModel.recordDoubleFault(player1: isServer)
                viewModel.awardPoint(toPlayer1: !isServer)
                pointAwardedHaptic()
                // Reset to first serve for next point
                isFirstServe = true
                showServeIndicator = false
            }
        }
    }

    // MARK: - Current Game Score

    private var currentGameScore: some View {
        VStack(spacing: 16) {
            if let currentSet = match.currentSet, currentSet.isTiebreak(format: match.format) {
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

    /// Returns the appropriate TiebreakType for the given set, accounting for
    /// final-set tiebreak rules when a `finalSetTiebreakType` is configured.
    private func tiebreakType(for set: TennisSet) -> TiebreakType {
        let totalSetsNeeded = match.format.setsToWin * 2 - 1
        let isFinalSet = match.sets.count == totalSetsNeeded
        if isFinalSet, let finalType = match.finalSetTiebreakType {
            return finalType
        }
        return match.regularTiebreakType
    }

    /// Human-readable badge label for the tiebreak type, e.g. "TIEBREAK · 7 PTS"
    /// or "MATCH TIEBREAK · 10 PTS".
    private func tiebreakBadgeLabel(for set: TennisSet) -> String {
        let type = tiebreakType(for: set)
        switch type {
        case .matchTiebreak:
            return "MATCH TIEBREAK · \(type.pointsToWin) PTS"
        case .extended:
            return "TIEBREAK · \(type.pointsToWin) PTS"
        case .regular:
            return "TIEBREAK · \(type.pointsToWin) PTS"
        }
    }

    private func tiebreakScoreDisplay(set: TennisSet) -> some View {
        let tbType = tiebreakType(for: set)
        let badgeLabel = tiebreakBadgeLabel(for: set)

        return VStack(spacing: 16) {
            // Tiebreak badge — shows type and target score
            Text(badgeLabel)
                .font(FSTypography.label(11))
                .tracking(2)
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

            // Dynamic tiebreak rule description using actual match configuration
            Text(tbType.description)
                .font(FSTypography.label(10))
                .foregroundStyle(FSColors.textMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tiebreak: \(player1?.name ?? "Player 1") \(set.tiebreakScorePlayer1 ?? 0), \(player2?.name ?? "Player 2") \(set.tiebreakScorePlayer2 ?? 0). \(tbType.description)")
    }

    private func regularGameScoreDisplay(game: Game) -> some View {
        let style = match.scoringStyle
        let isNoAdDeuce = style == .noAdvantage
            && game.pointsPlayer1 >= 3
            && game.pointsPlayer2 >= 3
            && game.pointsPlayer1 == game.pointsPlayer2

        return VStack(spacing: 16) {
            // Header — flag sudden death in no-ad scoring at deuce
            if isNoAdDeuce {
                VStack(spacing: 4) {
                    Text("CURRENT GAME")
                        .font(FSTypography.label(10))
                        .tracking(2)
                        .foregroundStyle(FSColors.textMuted)
                    Text("SUDDEN DEATH")
                        .font(FSTypography.label(9))
                        .tracking(2)
                        .foregroundStyle(FSColors.fault)
                }
            } else {
                Text("CURRENT GAME")
                    .font(FSTypography.label(10))
                    .tracking(2)
                    .foregroundStyle(FSColors.textMuted)
            }

            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(game.scoreString(forPlayer1: true, scoringStyle: style))
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
                    Text(game.scoreString(forPlayer1: false, scoringStyle: style))
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
        .accessibilityLabel({
            let p1Score = game.scoreString(forPlayer1: true, scoringStyle: style)
            let p2Score = game.scoreString(forPlayer1: false, scoringStyle: style)
            var label = "Current game: \(player1?.name ?? "Player 1") \(p1Score), \(player2?.name ?? "Player 2") \(p2Score)"
            if isNoAdDeuce { label += ". Sudden death — next point wins." }
            return label
        }())
    }

    // MARK: - Full Stats Scoring Buttons

    private var fullStatsScoringButtons: some View {
        VStack(spacing: 16) {
            Text("WHO WON THE POINT?")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 16) {
                scoreButton(
                    name: player1?.name ?? "Player 1",
                    color: FSColors.hardCourt
                ) {
                    shotPickerIsPlayer1 = true
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectResultType
                    }
                }

                scoreButton(
                    name: player2?.name ?? "Player 2",
                    color: FSColors.clay
                ) {
                    shotPickerIsPlayer1 = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectResultType
                    }
                }
            }

            // Undo button
            Button {
                viewModel.undoLastPoint()
                isFirstServe = true
                showServeIndicator = false
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
        }
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
                    pointAwardedHaptic()
                    // Reset serve state for next point
                    isFirstServe = true
                    showServeIndicator = false
                }

                // Player 2 button
                scoreButton(
                    name: player2?.name ?? "Player 2",
                    color: FSColors.clay
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardPoint(toPlayer1: false)
                    }
                    pointAwardedHaptic()
                    // Reset serve state for next point
                    isFirstServe = true
                    showServeIndicator = false
                }
            }

            // Undo button
            Button {
                viewModel.undoLastPoint()
                // Always reset to first serve on undo so the user re-enters the
                // serve state cleanly. This covers the edge case where the undone
                // point ended on a double fault and the view was showing "2nd serve".
                isFirstServe = true
                showServeIndicator = false
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

    // MARK: - Games-Only Scoring

    private var gamesOnlyScoringButtons: some View {
        VStack(spacing: 16) {
            Text("TAP TO AWARD GAME")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 16) {
                gameAwardButton(
                    name: player1?.name ?? "Player 1",
                    color: FSColors.hardCourt
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardGame(toPlayer1: true)
                    }
                }

                gameAwardButton(
                    name: player2?.name ?? "Player 2",
                    color: FSColors.clay
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.awardGame(toPlayer1: false)
                    }
                }
            }

            Button {
                viewModel.undoLastPoint()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Undo Last Game")
                        .font(FSTypography.label(12))
                }
                .foregroundStyle(viewModel.canUndo ? FSColors.textSecondary : FSColors.textMuted.opacity(0.5))
            }
            .disabled(!viewModel.canUndo)
            .padding(.top, 8)
            .accessibilityLabel("Undo last game")
        }
    }

    private func gameAwardButton(name: String, color: Color, action: @escaping () -> Void) -> some View {
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

                Text("GAME")
                    .font(FSTypography.label(9))
                    .tracking(1)
                    .foregroundStyle(color)
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
        .accessibilityLabel("Award game to \(name)")
        .accessibilityHint("Double tap to give \(name) one game")
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
                        viewModel.prepareUndo()
                        viewModel.recordAce(player1: true)
                        viewModel.awardPoint(toPlayer1: true)
                        pointAwardedHaptic()
                    },
                    player2Action: {
                        viewModel.prepareUndo()
                        viewModel.recordAce(player1: false)
                        viewModel.awardPoint(toPlayer1: false)
                        pointAwardedHaptic()
                    }
                )

                quickStatButton(
                    label: "Double Fault",
                    icon: "xmark",
                    color: FSColors.fault,
                    player1Action: {
                        viewModel.prepareUndo()
                        viewModel.recordDoubleFault(player1: true)
                        viewModel.awardPoint(toPlayer1: false)
                        pointAwardedHaptic()
                    },
                    player2Action: {
                        viewModel.prepareUndo()
                        viewModel.recordDoubleFault(player1: false)
                        viewModel.awardPoint(toPlayer1: true)
                        pointAwardedHaptic()
                    }
                )

                quickStatButton(
                    label: "Winner",
                    icon: "star.fill",
                    color: FSColors.winner,
                    player1Action: {
                        showShotPicker(for: .winner, isPlayer1: true)
                    },
                    player2Action: {
                        showShotPicker(for: .winner, isPlayer1: false)
                    }
                )
                
                quickStatButton(
                    label: "Error",
                    icon: "exclamationmark.triangle.fill",
                    color: FSColors.fault,
                    player1Action: {
                        showShotPicker(for: .unforcedError, isPlayer1: true)
                    },
                    player2Action: {
                        showShotPicker(for: .unforcedError, isPlayer1: false)
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

            VStack(spacing: 12) {
                // Match Summary button (primary CTA)
                Button {
                    showingMatchSummary = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Match Summary")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [FSColors.championship, FSColors.championship.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingMatchSummary)
                
                HStack(spacing: 12) {
                    // Share button
                    ShareLink(item: generateShareText()) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FSColors.courtGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                    
                    // Detailed Stats button
                    Button {
                        showingStatsSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Stats")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FSColors.backgroundElevated)
                        .foregroundColor(FSColors.textPrimary)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
            .accessibilityLabel("View match summary and statistics")
            .accessibilityHint("Double tap to view comprehensive match summary")
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Share Functionality
    
    // MARK: - Shot Picker Helpers
    
    private func showShotPicker(for statType: StatType, isPlayer1: Bool) {
        shotPickerStatType = statType
        shotPickerIsPlayer1 = isPlayer1
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedContactType = nil
            shotPickerPhase = .selectContactType
        }
    }

    // MARK: - Result Type Selection

    private var inlineResultTypeSelection: some View {
        let playerName = shotPickerIsPlayer1 ? (player1?.name ?? "Player 1") : (player2?.name ?? "Player 2")

        return VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .hidden
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(FSTypography.label(10))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }

                Spacer()

                Text("\(playerName.uppercased()) WON")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }

            Text("HOW DID THE POINT END?")
                .font(FSTypography.label(9))
                .tracking(1.5)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 12) {
                inlinePickerButton(label: "Winner", icon: "star.fill", color: FSColors.winner) {
                    shotPickerStatType = .winner
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedContactType = nil
                        shotPickerPhase = .selectContactType
                    }
                }

                inlinePickerButton(label: "Forced\nError", icon: "exclamationmark.circle.fill", color: FSColors.ballYellow) {
                    shotPickerStatType = .forcedError
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedContactType = nil
                        shotPickerPhase = .selectContactType
                    }
                }

                inlinePickerButton(label: "Unforced\nError", icon: "exclamationmark.triangle.fill", color: FSColors.fault) {
                    shotPickerStatType = .unforcedError
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedContactType = nil
                        shotPickerPhase = .selectContactType
                    }
                }
            }
        }
    }
    
    // MARK: - Inline Shot Picker

    private var inlineShotPicker: some View {
        VStack(spacing: 16) {
            switch shotPickerPhase {
            case .hidden:
                EmptyView()
            case .selectResultType:
                inlineResultTypeSelection
            case .selectContactType:
                inlineContactTypeSelection
            case .selectShotType:
                inlineShotTypeSelection
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
        .animation(.easeInOut(duration: 0.25), value: shotPickerPhase)
    }

    private var inlineContactTypeSelection: some View {
        let playerName = shotPickerIsPlayer1 ? (player1?.name ?? "Player 1") : (player2?.name ?? "Player 2")
        let statLabel: String = {
            switch shotPickerStatType {
            case .winner: return "WINNER"
            case .forcedError: return "FORCED ERROR"
            case .unforcedError: return "UNFORCED ERROR"
            }
        }()

        return VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectResultType
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(FSTypography.label(10))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }

                Spacer()

                Text("\(playerName.uppercased()) — \(statLabel)")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }

            Text("SHOT TYPE")
                .font(FSTypography.label(9))
                .tracking(1.5)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 12) {
                inlinePickerButton(label: "Ground-\nstroke", icon: "figure.tennis", color: FSColors.courtGreen) {
                    selectedContactType = .groundstroke
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectShotType
                    }
                }

                inlinePickerButton(label: "Volley", icon: "hand.raised.fill", color: FSColors.hardCourt) {
                    selectedContactType = .volley
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectShotType
                    }
                }

                inlinePickerButton(label: "Overhead", icon: "arrow.up.circle.fill", color: .orange) {
                    selectedContactType = .overhead
                    withAnimation(.easeInOut(duration: 0.25)) {
                        shotPickerPhase = .selectShotType
                    }
                }
            }
        }
    }

    private var inlineShotTypeSelection: some View {
        let playerName = shotPickerIsPlayer1 ? (player1?.name ?? "Player 1") : (player2?.name ?? "Player 2")
        let contactLabel = selectedContactType?.rawValue.uppercased() ?? ""
        let statLabel: String = {
            switch shotPickerStatType {
            case .winner: return "WINNER"
            case .forcedError: return "FORCED ERROR"
            case .unforcedError: return "UNFORCED ERROR"
            }
        }()

        return VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedContactType = nil
                        shotPickerPhase = .selectContactType
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(FSTypography.label(10))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }

                Spacer()

                Text("\(playerName.uppercased()) — \(contactLabel) \(statLabel)")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }

            Text("FOREHAND OR BACKHAND?")
                .font(FSTypography.label(9))
                .tracking(1.5)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 12) {
                inlinePickerButton(label: "Forehand", icon: "hand.raised.fill", color: FSColors.ace) {
                    guard let contact = selectedContactType else { return }
                    handleShotSelection(shotType: .forehand, contactType: contact)
                }

                inlinePickerButton(label: "Backhand", icon: "hand.raised.fingers.spread", color: FSColors.clay) {
                    guard let contact = selectedContactType else { return }
                    handleShotSelection(shotType: .backhand, contactType: contact)
                }
            }
        }
    }

    private func inlinePickerButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Text(label)
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
    }

    // MARK: - Shot Selection & Haptics

    private func handleShotSelection(shotType: ShotType, contactType: ContactType) {
        // Capture undo snapshot before any stats are modified
        viewModel.prepareUndo()

        // Auto-record serve as "in" if user didn't explicitly hit Ace/Fault
        // (they went straight to the scoring flow, implying the serve landed)
        // We know who won the point, so we can track serve points won correctly
        if let currentGame = match.currentSet?.currentGame {
            let isServer = currentGame.serverIsPlayer1
            let serverWon = shotPickerIsPlayer1 == isServer
            match.recordServe(forPlayer1: isServer, firstServe: isFirstServe, made: true, pointWon: serverWon)
        }

        // Record the stat with shot details
        switch shotPickerStatType {
        case .winner:
            viewModel.recordWinner(player1: shotPickerIsPlayer1, shotType: shotType, contactType: contactType)
            viewModel.awardPoint(toPlayer1: shotPickerIsPlayer1)
        case .forcedError:
            // Forced error: point winner forced the opponent into an error
            // Record as a forced error on the opponent, point goes to the picker's player
            viewModel.recordForcedError(player1: !shotPickerIsPlayer1, shotType: shotType, contactType: contactType)
            viewModel.awardPoint(toPlayer1: shotPickerIsPlayer1)
        case .unforcedError:
            // Unforced error: opponent made the error, point goes to the picker's player
            viewModel.recordUnforcedError(player1: !shotPickerIsPlayer1, shotType: shotType, contactType: contactType)
            viewModel.awardPoint(toPlayer1: shotPickerIsPlayer1)
        }
        pointAwardedHaptic()
        // Reset serve state for next point
        isFirstServe = true
        showServeIndicator = false
        withAnimation(.easeInOut(duration: 0.25)) {
            shotPickerPhase = .hidden
            selectedContactType = nil
        }
    }

    private func pointAwardedHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
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
        text += "🏆 \(match.format.displayName)\n"
        
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

    /// 0 = match total; 1...N = set number
    @State private var selectedSetFilter: Int = 0
    @State private var appearAnimating = false

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }

    private var completedSetCount: Int {
        match.sets.filter { $0.isComplete }.count
    }

    // Player accent colors
    private let p1Color = FSColors.hardCourt
    private let p2Color = FSColors.clay

    var body: some View {
        NavigationStack {
            ZStack {
                // Mesh gradient background
                FSGradients.meshBackground
                    .ignoresSafeArea()

                // Subtle net pattern overlay
                FSNetPattern(opacity: 0.02)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Editorial header
                        editorialHeader
                            .opacity(appearAnimating ? 1 : 0)
                            .offset(y: appearAnimating ? 0 : 12)

                        // Player name bar
                        playerBar
                            .padding(.top, 20)
                            .opacity(appearAnimating ? 1 : 0)
                            .offset(y: appearAnimating ? 0 : 12)

                        // Set filter chips (hide for single-set formats)
                        if completedSetCount > 1 {
                            setFilterChips
                                .padding(.top, 16)
                                .opacity(appearAnimating ? 1 : 0)
                                .offset(y: appearAnimating ? 0 : 10)
                        }

                        // Points card
                        pointsCard
                            .padding(.top, 24)
                            .opacity(appearAnimating ? 1 : 0)
                            .offset(y: appearAnimating ? 0 : 16)

                        // Serve card (fullStats only)
                        if match.scoringMode == .fullStats {
                            serveCard
                                .padding(.top, 16)
                                .opacity(appearAnimating ? 1 : 0)
                                .offset(y: appearAnimating ? 0 : 16)
                        }

                        // Break points card
                        breakPointsCard
                            .padding(.top, 16)
                            .opacity(appearAnimating ? 1 : 0)
                            .offset(y: appearAnimating ? 0 : 16)

                        // Shot breakdown (fullStats only)
                        if match.scoringMode == .fullStats {
                            shotBreakdownCard
                                .padding(.top, 16)
                                .opacity(appearAnimating ? 1 : 0)
                                .offset(y: appearAnimating ? 0 : 16)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FSColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(FSColors.backgroundElevated))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appearAnimating = true
            }
        }
    }

    // MARK: - Editorial Header

    private var editorialHeader: some View {
        VStack(spacing: 12) {
            CourtLineAccent(width: 40)

            Text("Head to Head")
                .font(FSTypography.headline(28))
                .foregroundStyle(FSColors.textPrimary)

            // Score display
            if !match.scoreString.isEmpty {
                Text(match.scoreString)
                    .font(FSTypography.mono(16))
                    .foregroundStyle(FSColors.championship)
                    .tracking(1)
            }

            // Surface & format badges
            HStack(spacing: 8) {
                badgePill(match.surface.rawValue, icon: match.surface.icon, color: match.surface.themeColor)
                badgePill(match.format.displayName, color: FSColors.textMuted)
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func badgePill(_ text: String, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 8))
            }
            Text(text)
                .font(FSTypography.label(9))
                .tracking(0.5)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 0.5))
        )
    }

    // MARK: - Player Bar

    private var playerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(p1Color)
                    .frame(width: 8, height: 8)
                Text(player1?.name ?? "Player 1")
                    .font(FSTypography.label(13))
                    .foregroundStyle(FSColors.textPrimary)
            }

            Spacer()

            HStack(spacing: 6) {
                Text(player2?.name ?? "Player 2")
                    .font(FSTypography.label(13))
                    .foregroundStyle(FSColors.textPrimary)
                Circle()
                    .fill(p2Color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Set Filter Chips

    private var setFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chipButton(label: "All", tag: 0)
                ForEach(1...max(1, completedSetCount), id: \.self) { setNum in
                    chipButton(label: "Set \(setNum)", tag: setNum)
                }
            }
        }
    }

    private func chipButton(label: String, tag: Int) -> some View {
        let isSelected = selectedSetFilter == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSetFilter = tag
            }
        } label: {
            Text(label)
                .font(FSTypography.label(10))
                .tracking(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? FSColors.championship.opacity(0.2) : FSColors.backgroundCard)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? FSColors.championship.opacity(0.6) : FSColors.lineWhite.opacity(0.08), lineWidth: 1)
                        )
                )
                .foregroundStyle(isSelected ? FSColors.championship : FSColors.textMuted)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Points Card

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(title: "POINTS")

            VStack(spacing: 0) {
                comparisonRow(label: "Total Points Won", p1: match.totalPointsWonPlayer1, p2: match.totalPointsWonPlayer2)
                if match.scoringMode == .fullStats {
                    cardDivider
                    comparisonRow(label: "Winners", p1: match.winnersPlayer1, p2: match.winnersPlayer2)
                    cardDivider
                    comparisonRow(label: "Unforced Errors", p1: match.unforcedErrorsPlayer1, p2: match.unforcedErrorsPlayer2, invertHighlight: true)
                    cardDivider
                    comparisonRow(label: "Aces", p1: match.acesPlayer1, p2: match.acesPlayer2)
                    cardDivider
                    comparisonRow(label: "Double Faults", p1: match.doubleFaultsPlayer1, p2: match.doubleFaultsPlayer2, invertHighlight: true)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Serve Card

    private var serveCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(title: "SERVE")

            VStack(spacing: 0) {
                percentageRow(
                    label: "1st Serve %",
                    p1Pct: match.firstServePercentagePlayer1,
                    p2Pct: match.firstServePercentagePlayer2,
                    p1Detail: "\(match.firstServesMadePlayer1)/\(match.firstServeAttemptsPlayer1)",
                    p2Detail: "\(match.firstServesMadePlayer2)/\(match.firstServeAttemptsPlayer2)"
                )
                cardDivider
                percentageRow(
                    label: "1st Serve Pts Won",
                    p1Pct: match.firstServePointsWonPercentagePlayer1,
                    p2Pct: match.firstServePointsWonPercentagePlayer2,
                    p1Detail: "\(match.pointsWonOnFirstServePlayer1)/\(match.firstServesMadePlayer1)",
                    p2Detail: "\(match.pointsWonOnFirstServePlayer2)/\(match.firstServesMadePlayer2)"
                )
                cardDivider
                percentageRow(
                    label: "2nd Serve %",
                    p1Pct: match.secondServePercentagePlayer1,
                    p2Pct: match.secondServePercentagePlayer2,
                    p1Detail: "\(match.secondServesMadePlayer1)/\(match.secondServeAttemptsPlayer1)",
                    p2Detail: "\(match.secondServesMadePlayer2)/\(match.secondServeAttemptsPlayer2)"
                )
                cardDivider
                percentageRow(
                    label: "2nd Serve Pts Won",
                    p1Pct: match.secondServePointsWonPercentagePlayer1,
                    p2Pct: match.secondServePointsWonPercentagePlayer2,
                    p1Detail: "\(match.pointsWonOnSecondServePlayer1)/\(match.secondServesMadePlayer1)",
                    p2Detail: "\(match.pointsWonOnSecondServePlayer2)/\(match.secondServesMadePlayer2)"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Break Points Card

    private var breakPointsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(title: "BREAK POINTS")

            HStack(alignment: .center) {
                // P1 break points
                VStack(spacing: 4) {
                    Text(breakPointPercentage(won: match.breakPointsWonPlayer1, total: match.breakPointsFacedPlayer2))
                        .font(FSTypography.score(36))
                        .foregroundStyle(match.breakPointsWonPlayer1 > match.breakPointsWonPlayer2 ? p1Color : FSColors.textSecondary)
                    Text("\(match.breakPointsWonPlayer1)/\(match.breakPointsFacedPlayer2)")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textMuted)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(FSColors.lineWhite.opacity(0.08))
                    .frame(width: 1, height: 50)

                // P2 break points
                VStack(spacing: 4) {
                    Text(breakPointPercentage(won: match.breakPointsWonPlayer2, total: match.breakPointsFacedPlayer1))
                        .font(FSTypography.score(36))
                        .foregroundStyle(match.breakPointsWonPlayer2 > match.breakPointsWonPlayer1 ? p2Color : FSColors.textSecondary)
                    Text("\(match.breakPointsWonPlayer2)/\(match.breakPointsFacedPlayer1)")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Shot Breakdown Card

    private var shotBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader(title: "SHOT BREAKDOWN")

            VStack(spacing: 20) {
                shotCategory(title: "Winners", statType: .winner, accentColor: FSColors.winner)

                Rectangle()
                    .fill(FSColors.lineWhite.opacity(0.04))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                shotCategory(title: "Unforced Errors", statType: .unforcedError, accentColor: FSColors.fault)
            }
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func shotCategory(title: String, statType: StatType, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor)
                    .frame(width: 3, height: 12)
                Text(title.uppercased())
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 4) {
                // Groundstrokes group
                shotRow(label: "Groundstrokes", contactType: .groundstroke, shotType: nil, statType: statType, isHeader: true)
                shotRow(label: "Forehand", contactType: .groundstroke, shotType: .forehand, statType: statType, isHeader: false)
                shotRow(label: "Backhand", contactType: .groundstroke, shotType: .backhand, statType: statType, isHeader: false)

                Spacer().frame(height: 6)

                // Volleys group
                shotRow(label: "Volleys", contactType: .volley, shotType: nil, statType: statType, isHeader: true)
                shotRow(label: "Forehand", contactType: .volley, shotType: .forehand, statType: statType, isHeader: false)
                shotRow(label: "Backhand", contactType: .volley, shotType: .backhand, statType: statType, isHeader: false)

                Spacer().frame(height: 6)

                // Overhead
                shotRow(label: "Overheads", contactType: .overhead, shotType: nil, statType: statType, isHeader: true)
            }
            .padding(.horizontal, 20)
        }
    }

    private func breakPointPercentage(won: Int, total: Int) -> String {
        guard total > 0 else { return "0%" }
        let pct = Int(round(Double(won) / Double(total) * 100))
        return "\(pct)%"
    }

    private func shotCount(player: Int, statType: StatType, contactType: ContactType, shotType: ShotType?) -> Int {
        match.shotStatistics.filter {
            $0.playerNumber == player
            && $0.statType == statType
            && (shotType == nil || $0.shotType == shotType)
            && $0.contactType == contactType
            && (selectedSetFilter == 0 || $0.setNumber == selectedSetFilter)
        }.count
    }

    private func shotRow(label: String, contactType: ContactType, shotType: ShotType?, statType: StatType, isHeader: Bool) -> some View {
        let p1 = shotCount(player: 1, statType: statType, contactType: contactType, shotType: shotType)
        let p2 = shotCount(player: 2, statType: statType, contactType: contactType, shotType: shotType)
        let color = isHeader ? FSColors.textPrimary : FSColors.textSecondary

        return ZStack {
            Text(label)
                .font(isHeader ? FSTypography.label(12) : FSTypography.body(12))
                .foregroundStyle(color)

            HStack {
                Text("\(p1)")
                    .font(FSTypography.mono(13))
                    .foregroundStyle(color)
                    .frame(width: 28, alignment: .trailing)

                Spacer()

                Text("\(p2)")
                    .font(FSTypography.mono(13))
                    .foregroundStyle(color)
                    .frame(width: 28, alignment: .leading)
            }
        }
    }

    // MARK: - Shared Components

    private func cardHeader(title: String) -> some View {
        Text(title)
            .font(FSTypography.label(10))
            .tracking(2)
            .foregroundStyle(FSColors.textMuted)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(FSColors.lineWhite.opacity(0.04))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    /// Comparison row with inline bar visualization
    private func comparisonRow(label: String, p1: Int, p2: Int, invertHighlight: Bool = false) -> some View {
        let maxVal = max(p1, p2, 1)
        let p1Leads = invertHighlight ? p1 < p2 : p1 > p2
        let p2Leads = invertHighlight ? p2 < p1 : p2 > p1

        return VStack(spacing: 8) {
            HStack {
                Text("\(p1)")
                    .font(FSTypography.mono(18))
                    .foregroundStyle(p1Leads ? FSColors.textPrimary : FSColors.textSecondary)
                    .frame(width: 36, alignment: .trailing)

                Spacer()

                Text(label)
                    .font(FSTypography.label(10))
                    .tracking(0.5)
                    .foregroundStyle(FSColors.textMuted)

                Spacer()

                Text("\(p2)")
                    .font(FSTypography.mono(18))
                    .foregroundStyle(p2Leads ? FSColors.textPrimary : FSColors.textSecondary)
                    .frame(width: 36, alignment: .leading)
            }

            // Comparison bars
            GeometryReader { geo in
                let totalWidth = geo.size.width - 4 // 2px gap in center
                let halfWidth = totalWidth / 2

                HStack(spacing: 4) {
                    // P1 bar (right-aligned)
                    HStack {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p1Color.opacity(p1Leads ? 0.8 : 0.3))
                            .frame(width: maxVal > 0 ? halfWidth * CGFloat(p1) / CGFloat(maxVal) : 0)
                    }
                    .frame(width: halfWidth)

                    // P2 bar (left-aligned)
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p2Color.opacity(p2Leads ? 0.8 : 0.3))
                            .frame(width: maxVal > 0 ? halfWidth * CGFloat(p2) / CGFloat(maxVal) : 0)
                        Spacer(minLength: 0)
                    }
                    .frame(width: halfWidth)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    /// Percentage row with fraction detail
    private func percentageRow(label: String, p1Pct: Double, p2Pct: Double, p1Detail: String, p2Detail: String) -> some View {
        let p1Leads = p1Pct > p2Pct
        let p2Leads = p2Pct > p1Pct

        return VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", p1Pct))
                        .font(FSTypography.mono(18))
                        .foregroundStyle(p1Leads ? FSColors.textPrimary : FSColors.textSecondary)
                    Text(p1Detail)
                        .font(FSTypography.label(9))
                        .foregroundStyle(FSColors.textMuted.opacity(0.7))
                }
                .frame(width: 56, alignment: .trailing)

                Spacer()

                Text(label)
                    .font(FSTypography.label(10))
                    .tracking(0.5)
                    .foregroundStyle(FSColors.textMuted)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.0f%%", p2Pct))
                        .font(FSTypography.mono(18))
                        .foregroundStyle(p2Leads ? FSColors.textPrimary : FSColors.textSecondary)
                    Text(p2Detail)
                        .font(FSTypography.label(9))
                        .foregroundStyle(FSColors.textMuted.opacity(0.7))
                }
                .frame(width: 56, alignment: .leading)
            }

            // Percentage bars
            GeometryReader { geo in
                let totalWidth = geo.size.width - 4
                let halfWidth = totalWidth / 2

                HStack(spacing: 4) {
                    HStack {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p1Color.opacity(p1Leads ? 0.8 : 0.3))
                            .frame(width: halfWidth * CGFloat(min(p1Pct, 100)) / 100)
                    }
                    .frame(width: halfWidth)

                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p2Color.opacity(p2Leads ? 0.8 : 0.3))
                            .frame(width: halfWidth * CGFloat(min(p2Pct, 100)) / 100)
                        Spacer(minLength: 0)
                    }
                    .frame(width: halfWidth)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func forcedErrorCount(player: Int) -> Int {
        match.shotStatistics.filter { $0.playerNumber == player && $0.statType == .forcedError }.count
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self, configurations: config)

    let player1 = Player(name: "Cam")
    let player2 = Player(name: "Opponent")
    let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)

    let _ = {
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
    }()

    let _ = container.mainContext.insert(match)
    let _ = container.mainContext.insert(player1)
    let _ = container.mainContext.insert(player2)

    NavigationStack {
        LiveMatchView(match: match)
    }
    .modelContainer(container)
}
