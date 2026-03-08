//
//  WatchMatchListView.swift
//  FirstServe Watch
//
//  Court Nouveau — Match selection on the wrist.
//  Dark editorial card layout with live pulse indicators.
//

import SwiftUI

struct WatchMatchListView: View {
    @Environment(WatchSessionService.self) private var session
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ZStack {
                WatchColors.backgroundDeep
                    .ignoresSafeArea()

                Group {
                    if session.activeMatches.isEmpty {
                        emptyState
                    } else {
                        matchList
                    }
                }
            }
            .navigationTitle {
                HStack(spacing: 4) {
                    Image(systemName: "tennisball.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(WatchColors.ballYellow)
                    Text("FIRSTSERVE")
                        .font(WatchType.label(9))
                        .tracking(1.5)
                        .foregroundStyle(WatchColors.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    // MARK: - Match List

    private var matchList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(session.activeMatches.enumerated()), id: \.element.id) { index, match in
                    NavigationLink {
                        WatchScoringView(matchId: match.id)
                            .onAppear { session.selectMatch(match.id) }
                    } label: {
                        WatchMatchCard(match: match)
                    }
                    .buttonStyle(.plain)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.08),
                        value: appear
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            WatchCourtLine(width: 24)

            Image(systemName: "tennisball")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(WatchColors.textMuted)
                .opacity(appear ? 1 : 0.3)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: appear)

            VStack(spacing: 4) {
                Text("NO MATCHES")
                    .font(WatchType.label(10))
                    .tracking(2)
                    .foregroundStyle(WatchColors.textSecondary)

                Text("Start on iPhone")
                    .font(WatchType.label(8))
                    .foregroundStyle(WatchColors.textMuted)
            }

            WatchCourtLine(width: 24)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: appear)
    }
}

// MARK: - Match Card

struct WatchMatchCard: View {
    let match: WatchMatchState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Live badge row
            HStack(spacing: 4) {
                WatchLiveDot()

                Text("LIVE")
                    .font(WatchType.label(7))
                    .tracking(1.5)
                    .foregroundStyle(WatchColors.ace)

                Spacer()

                Text(match.scoringMode == "Games Only" ? "GAMES" : "POINTS")
                    .font(WatchType.label(7))
                    .tracking(1)
                    .foregroundStyle(WatchColors.textMuted)
            }

            // Player rows with set scores
            VStack(spacing: 3) {
                playerRow(
                    name: match.player1Name,
                    sets: match.sets,
                    isPlayer1: true,
                    isServing: match.currentGameScore?.serverIsPlayer1 == true
                )

                Rectangle()
                    .fill(WatchColors.lineWhite.opacity(0.06))
                    .frame(height: 0.5)

                playerRow(
                    name: match.player2Name,
                    sets: match.sets,
                    isPlayer1: false,
                    isServing: match.currentGameScore?.serverIsPlayer1 == false
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(WatchColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(WatchColors.lineWhite.opacity(0.05), lineWidth: 0.5)
                )
        )
    }

    private func playerRow(name: String, sets: [WatchSetState],
                           isPlayer1: Bool, isServing: Bool) -> some View {
        HStack(spacing: 4) {
            WatchServingDot(isServing: isServing)

            Text(name)
                .font(WatchType.label(11))
                .foregroundStyle(WatchColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                ForEach(Array(sets.enumerated()), id: \.offset) { idx, set in
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    let isCurrentSet = idx == sets.count - 1 && !set.isComplete
                    Text("\(games)")
                        .font(WatchType.mono(12))
                        .fontWeight(.bold)
                        .foregroundStyle(isCurrentSet ? WatchColors.textPrimary : WatchColors.textSecondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
