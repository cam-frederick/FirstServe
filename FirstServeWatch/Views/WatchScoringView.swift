//
//  WatchScoringView.swift
//  FirstServe Watch
//
//  Court Nouveau — Scoring on the wrist.
//  Dense, functional, beautiful. Every pixel earns its place.
//

import SwiftUI
import WatchKit

struct WatchScoringView: View {
    let matchId: String
    @Environment(WatchSessionService.self) private var session
    @State private var appear = false
    @State private var scoreFlash = false

    private var match: WatchMatchState? {
        // Prefer selectedMatch; fall back to the match from the active list
        session.selectedMatch ?? session.activeMatches.first(where: { $0.id == matchId })
    }

    var body: some View {
        ZStack {
            WatchColors.backgroundDeep
                .ignoresSafeArea()

            Group {
                if let match {
                    if match.isComplete {
                        matchCompleteView(match)
                    } else {
                        scoringContent(match)
                    }
                } else {
                    loadingView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 3) {
                    WatchLiveDot()
                    Text("LIVE")
                        .font(WatchType.label(7))
                        .tracking(1)
                        .foregroundStyle(WatchColors.ace)
                }
            }
        }
        .onAppear {
            // Populate selectedMatch immediately from cached list
            if session.selectedMatch == nil,
               let cached = session.activeMatches.first(where: { $0.id == matchId }) {
                session.selectedMatch = cached
            }
            withAnimation(.easeOut(duration: 0.4)) { appear = true }
        }
        .onChange(of: session.activeMatches) {
            // Application context updated — sync selectedMatch
            if let updated = session.activeMatches.first(where: { $0.id == matchId }) {
                session.selectedMatch = updated
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(WatchColors.championship)
            Text("CONNECTING")
                .font(WatchType.label(8))
                .tracking(2)
                .foregroundStyle(WatchColors.textMuted)
        }
    }

    // MARK: - Scoring Content

    private func scoringContent(_ match: WatchMatchState) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                // Scoreboard (includes inline game score for point-scoring modes)
                scoreboard(match)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)

                // Scoring buttons
                scoringButtons(match)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: appear)

                // Undo
                if match.canUndo {
                    undoButton
                        .opacity(session.pendingConfirmation ? 0.4 : (appear ? 1 : 0))
                        .disabled(session.pendingConfirmation)
                        .animation(.easeOut(duration: 0.3).delay(0.15), value: appear)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Scoreboard

    private func scoreboard(_ match: WatchMatchState) -> some View {
        let showGameScore = match.scoringMode != "Games Only"
        let isTiebreak = match.isInTiebreak

        return VStack(spacing: 0) {
            // Tiebreak label above scoreboard
            if isTiebreak {
                Text("TIEBREAK")
                    .font(WatchType.label(7))
                    .tracking(1.5)
                    .foregroundStyle(WatchColors.ace)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            }

            playerScoreRow(
                name: match.player1Name,
                sets: match.sets,
                isPlayer1: true,
                isServing: match.currentGameScore?.serverIsPlayer1 == true,
                gameScore: showGameScore ? gameScoreText(match, isPlayer1: true) : nil
            )

            Rectangle()
                .fill(WatchColors.lineWhite.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 8)

            playerScoreRow(
                name: match.player2Name,
                sets: match.sets,
                isPlayer1: false,
                isServing: match.currentGameScore?.serverIsPlayer1 == false,
                gameScore: showGameScore ? gameScoreText(match, isPlayer1: false) : nil
            )
        }
        .scaleEffect(scoreFlash ? 1.02 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTiebreak
                      ? WatchColors.ace.opacity(0.08)
                      : WatchColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isTiebreak
                            ? WatchColors.ace.opacity(0.2)
                            : WatchColors.lineWhite.opacity(0.05),
                            lineWidth: 0.5
                        )
                )
        )
    }

    private func playerScoreRow(name: String, sets: [WatchSetState],
                                isPlayer1: Bool, isServing: Bool,
                                gameScore: String? = nil) -> some View {
        HStack(spacing: 5) {
            WatchServingDot(isServing: isServing)

            Text(name)
                .font(WatchType.label(11))
                .foregroundStyle(WatchColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.offset) { idx, set in
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    let isCurrentSet = idx == sets.count - 1 && !set.isComplete

                    Text("\(games)")
                        .font(WatchType.score(14))
                        .foregroundStyle(isCurrentSet ? WatchColors.textPrimary : WatchColors.textSecondary)
                        .frame(minWidth: 14)
                }

                // Inline game score after a thin divider
                if let gameScore {
                    Rectangle()
                        .fill(WatchColors.lineWhite.opacity(0.15))
                        .frame(width: 0.5, height: 14)

                    Text(gameScore)
                        .font(WatchType.score(14))
                        .fontWeight(.bold)
                        .foregroundStyle(WatchColors.ace)
                        .frame(minWidth: 20)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private func gameScoreText(_ match: WatchMatchState, isPlayer1: Bool) -> String {
        if match.isInTiebreak, let currentSet = match.sets.last {
            let score = isPlayer1 ? (currentSet.tiebreakScorePlayer1 ?? 0) : (currentSet.tiebreakScorePlayer2 ?? 0)
            return "\(score)"
        } else if let gameScore = match.currentGameScore {
            return isPlayer1 ? gameScore.player1Score : gameScore.player2Score
        }
        return "0"
    }

    // MARK: - Scoring Buttons

    private func scoringButtons(_ match: WatchMatchState) -> some View {
        let isGamesOnly = match.scoringMode == "Games Only"
        let pending = session.pendingConfirmation

        return VStack(spacing: 6) {
            Text(isGamesOnly ? "AWARD GAME" : "AWARD POINT")
                .font(WatchType.label(7))
                .tracking(1.5)
                .foregroundStyle(WatchColors.textMuted)

            HStack(spacing: 6) {
                scoreButton(
                    name: match.player1Name,
                    color: WatchColors.hardCourt,
                    disabled: pending
                ) {
                    if isGamesOnly {
                        session.awardGame(matchId: matchId, toPlayer1: true)
                    } else {
                        session.awardPoint(matchId: matchId, toPlayer1: true)
                    }
                    WKInterfaceDevice.current().play(.click)
                    flashScore()
                }

                scoreButton(
                    name: match.player2Name,
                    color: WatchColors.clay,
                    disabled: pending
                ) {
                    if isGamesOnly {
                        session.awardGame(matchId: matchId, toPlayer1: false)
                    } else {
                        session.awardPoint(matchId: matchId, toPlayer1: false)
                    }
                    WKInterfaceDevice.current().play(.click)
                    flashScore()
                }
            }
        }
    }

    private func scoreButton(name: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))

                Text(name)
                    .font(WatchType.label(9))
                    .lineLimit(1)
            }
            .foregroundStyle(WatchColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
            .opacity(disabled ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Undo

    private var undoButton: some View {
        Button {
            session.undo(matchId: matchId)
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 9, weight: .semibold))
                Text("UNDO")
                    .font(WatchType.label(8))
                    .tracking(1)
            }
            .foregroundStyle(WatchColors.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .stroke(WatchColors.textMuted.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Match Complete

    private func matchCompleteView(_ match: WatchMatchState) -> some View {
        VStack(spacing: 10) {
            WatchCourtLine(width: 20)

            Image(systemName: "trophy.fill")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(WatchColors.championship)

            Text("FINAL")
                .font(WatchType.label(9))
                .tracking(3)
                .foregroundStyle(WatchColors.championship)

            WatchCourtLine(width: 20)

            // Final score
            VStack(spacing: 4) {
                finalPlayerRow(name: match.player1Name, sets: match.sets, isPlayer1: true, match: match)

                Rectangle()
                    .fill(WatchColors.lineWhite.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)

                finalPlayerRow(name: match.player2Name, sets: match.sets, isPlayer1: false, match: match)
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(WatchColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(WatchColors.championship.opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: appear)
    }

    private func finalPlayerRow(name: String, sets: [WatchSetState],
                                isPlayer1: Bool, match: WatchMatchState) -> some View {
        let isWinner = determineWinner(match: match, isPlayer1: isPlayer1)
        return HStack(spacing: 5) {
            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(WatchColors.championship)
            }

            Text(name)
                .font(WatchType.label(11))
                .fontWeight(isWinner ? .bold : .regular)
                .foregroundStyle(isWinner ? WatchColors.textPrimary : WatchColors.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    Text("\(games)")
                        .font(WatchType.score(14))
                        .foregroundStyle(isWinner ? WatchColors.textPrimary : WatchColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    // MARK: - Helpers

    private func flashScore() {
        withAnimation(.easeOut(duration: 0.15)) { scoreFlash = true }
        withAnimation(.easeIn(duration: 0.2).delay(0.15)) { scoreFlash = false }
    }

    private func determineWinner(match: WatchMatchState, isPlayer1: Bool) -> Bool {
        let setsWon1 = match.sets.filter { $0.isComplete && $0.gamesPlayer1 > $0.gamesPlayer2 }.count
        let setsWon2 = match.sets.filter { $0.isComplete && $0.gamesPlayer2 > $0.gamesPlayer1 }.count
        return isPlayer1 ? setsWon1 > setsWon2 : setsWon2 > setsWon1
    }
}
