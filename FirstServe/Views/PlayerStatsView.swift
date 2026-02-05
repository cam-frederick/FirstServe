//
//  PlayerStatsView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

struct PlayerStatsView: View {
    let player: Player
    @State private var appearAnimation = false

    private var totalAces: Int {
        player.matches.reduce(0) { total, match in
            if match.players.first?.id == player.id {
                return total + match.acesPlayer1
            } else {
                return total + match.acesPlayer2
            }
        }
    }

    private var totalWinners: Int {
        player.matches.reduce(0) { total, match in
            if match.players.first?.id == player.id {
                return total + match.winnersPlayer1
            } else {
                return total + match.winnersPlayer2
            }
        }
    }

    private var totalDoubleFaults: Int {
        player.matches.reduce(0) { total, match in
            if match.players.first?.id == player.id {
                return total + match.doubleFaultsPlayer1
            } else {
                return total + match.doubleFaultsPlayer2
            }
        }
    }

    private var favoriteSurface: CourtSurface? {
        guard !player.matches.isEmpty else { return nil }

        var surfaceCounts: [CourtSurface: Int] = [:]
        for match in player.matches {
            surfaceCounts[match.surface, default: 0] += 1
        }

        return surfaceCounts.max(by: { $0.value < $1.value })?.key
    }

    private var matchesLost: Int {
        player.matchesPlayed - player.matchesWon
    }

    var body: some View {
        ZStack {
            FSGradients.meshBackground
                .ignoresSafeArea()

            FSNetPattern(opacity: 0.02)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Player header
                    headerSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                    // Win/Loss record
                    recordSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                    // Career stats
                    statsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

                    // Match history
                    matchHistorySection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FSColors.hardCourt.opacity(0.15))
                    .frame(width: 100, height: 100)

                Text(player.name.prefix(1).uppercased())
                    .font(FSTypography.display(44))
                    .foregroundStyle(FSColors.hardCourt)
            }

            VStack(spacing: 8) {
                Text(player.name)
                    .font(FSTypography.headline(32))
                    .foregroundStyle(FSColors.textPrimary)

                Text("\(player.matchesPlayed) \(player.matchesPlayed == 1 ? "match" : "matches") played")
                    .font(FSTypography.body(14))
                    .foregroundStyle(FSColors.textSecondary)
            }

            CourtLineAccent(width: 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Record Section

    private var recordSection: some View {
        VStack(spacing: 20) {
            Text("CAREER RECORD")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 0) {
                // Wins
                VStack(spacing: 8) {
                    Text("\(player.matchesWon)")
                        .font(FSTypography.display(56))
                        .foregroundStyle(FSColors.winner)

                    Text("WINS")
                        .font(FSTypography.label(10))
                        .tracking(1.5)
                        .foregroundStyle(FSColors.textMuted)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(FSColors.lineWhite.opacity(0.1))
                    .frame(width: 1, height: 80)

                // Losses
                VStack(spacing: 8) {
                    Text("\(matchesLost)")
                        .font(FSTypography.display(56))
                        .foregroundStyle(FSColors.fault)

                    Text("LOSSES")
                        .font(FSTypography.label(10))
                        .tracking(1.5)
                        .foregroundStyle(FSColors.textMuted)
                }
                .frame(maxWidth: .infinity)
            }

            // Win percentage bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    let winRatio = player.matchesPlayed > 0 ? CGFloat(player.matchesWon) / CGFloat(player.matchesPlayed) : 0.5

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FSColors.fault.opacity(0.3))

                        Capsule()
                            .fill(FSColors.winner)
                            .frame(width: geo.size.width * winRatio)
                    }
                }
                .frame(height: 8)

                Text(String(format: "%.0f%% Win Rate", player.winPercentage))
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.textSecondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CAREER STATISTICS")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 12) {
                statCard(title: "Aces", value: totalAces, icon: "bolt.fill", color: FSColors.ace)
                statCard(title: "Winners", value: totalWinners, icon: "star.fill", color: FSColors.winner)
                statCard(title: "DFs", value: totalDoubleFaults, icon: "xmark", color: FSColors.fault)
            }

            // Favorite surface
            if let surface = favoriteSurface {
                HStack {
                    Text("Favorite Surface")
                        .font(FSTypography.body(14))
                        .foregroundStyle(FSColors.textSecondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: surface.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(surface.themeColor)

                        Text(surface.rawValue)
                            .font(FSTypography.body(14))
                            .fontWeight(.medium)
                            .foregroundStyle(FSColors.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(surface.themeColor.opacity(0.15))
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func statCard(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text("\(value)")
                .font(FSTypography.score(28))
                .foregroundStyle(FSColors.textPrimary)

            Text(title)
                .font(FSTypography.label(10))
                .foregroundStyle(FSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Match History Section

    private var matchHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MATCH HISTORY")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            if player.matches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundStyle(FSColors.textMuted)

                    Text("No matches yet")
                        .font(FSTypography.body(14))
                        .foregroundStyle(FSColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(player.matches.sorted(by: { $0.createdAt > $1.createdAt }).enumerated()), id: \.element.id) { index, match in
                        if index > 0 {
                            Divider()
                                .background(FSColors.lineWhite.opacity(0.06))
                        }
                        matchRow(match)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func matchRow(_ match: Match) -> some View {
        let isPlayer1 = match.players.first?.id == player.id
        let opponent = isPlayer1 ? match.players.last : match.players.first
        let didWin = match.winner?.id == player.id

        return HStack(spacing: 14) {
            // Win/Loss indicator
            ZStack {
                Circle()
                    .fill(didWin ? FSColors.winner.opacity(0.15) : FSColors.fault.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text(didWin ? "W" : "L")
                    .font(FSTypography.label(14))
                    .fontWeight(.bold)
                    .foregroundStyle(didWin ? FSColors.winner : FSColors.fault)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponent?.name ?? "Unknown")")
                    .font(FSTypography.body(15))
                    .fontWeight(.medium)
                    .foregroundStyle(FSColors.textPrimary)

                HStack(spacing: 8) {
                    Text(match.scoreString.isEmpty ? "In Progress" : match.scoreString)
                        .font(FSTypography.mono(12))
                        .foregroundStyle(FSColors.textSecondary)

                    Circle()
                        .fill(FSColors.textMuted)
                        .frame(width: 3, height: 3)

                    HStack(spacing: 4) {
                        Image(systemName: match.surface.icon)
                            .font(.system(size: 9))
                        Text(match.surface.rawValue)
                            .font(FSTypography.label(10))
                    }
                    .foregroundStyle(match.surface.themeColor)
                }
            }

            Spacer()

            // Date
            Text(match.createdAt, style: .date)
                .font(FSTypography.label(10))
                .foregroundStyle(FSColors.textMuted)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Player List View

struct PlayerListView: View {
    @Query(sort: \Player.name) private var players: [Player]
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            FSGradients.meshBackground
                .ignoresSafeArea()

            FSNetPattern(opacity: 0.02)
                .ignoresSafeArea()

            if players.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            NavigationLink {
                                PlayerStatsView(player: player)
                            } label: {
                                PlayerRowCard(player: player)
                            }
                            .buttonStyle(.plain)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: appearAnimation)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(FSColors.textMuted)

            Text("No Players Yet")
                .font(FSTypography.headline(24))
                .foregroundStyle(FSColors.textPrimary)

            Text("Players will appear here after you start a match")
                .font(FSTypography.body(14))
                .foregroundStyle(FSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct PlayerRowCard: View {
    let player: Player

    private var matchesLost: Int {
        player.matchesPlayed - player.matchesWon
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FSColors.hardCourt.opacity(0.15))
                    .frame(width: 50, height: 50)

                Text(player.name.prefix(1).uppercased())
                    .font(FSTypography.headline(20))
                    .foregroundStyle(FSColors.hardCourt)
            }

            // Name and record
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(FSTypography.body(16))
                    .fontWeight(.semibold)
                    .foregroundStyle(FSColors.textPrimary)

                HStack(spacing: 8) {
                    Text("\(player.matchesWon)W - \(matchesLost)L")
                        .font(FSTypography.mono(12))
                        .foregroundStyle(FSColors.textSecondary)

                    if player.matchesPlayed > 0 {
                        Text("•")
                            .foregroundStyle(FSColors.textMuted)

                        Text(String(format: "%.0f%%", player.winPercentage))
                            .font(FSTypography.mono(12))
                            .foregroundStyle(player.winPercentage >= 50 ? FSColors.winner : FSColors.fault)
                    }
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FSColors.textMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        PlayerStatsView(player: Player(name: "John Doe"))
    }
}
