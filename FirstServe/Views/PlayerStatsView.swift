//
//  PlayerStatsView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

struct PlayerStatsView: View {
    @Environment(\.dismiss) private var dismiss
    let player: Player
    @State private var appearAnimation = false
    @State private var selectedMatch: Match?

    /// Only completed matches for this player
    private var completedMatches: [Match] {
        player.matches.filter { $0.isComplete }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var completedMatchCount: Int { completedMatches.count }

    private var matchesWon: Int {
        completedMatches.filter { $0.winner?.id == player.id }.count
    }

    private var matchesLost: Int {
        completedMatchCount - matchesWon
    }

    private var winPercentage: Double {
        guard completedMatchCount > 0 else { return 0 }
        return Double(matchesWon) / Double(completedMatchCount) * 100
    }

    // MARK: - Aggregate Helpers

    private func isPlayer1(in match: Match) -> Bool {
        match.players.first?.id == player.id
    }

    private func careerTotal(_ p1KeyPath: KeyPath<Match, Int>, _ p2KeyPath: KeyPath<Match, Int>) -> Int {
        completedMatches.reduce(0) { total, match in
            total + (isPlayer1(in: match) ? match[keyPath: p1KeyPath] : match[keyPath: p2KeyPath])
        }
    }

    private func careerPercentage(made p1Made: KeyPath<Match, Int>, _ p2Made: KeyPath<Match, Int>,
                                   total p1Total: KeyPath<Match, Int>, _ p2Total: KeyPath<Match, Int>) -> (pct: Double, made: Int, total: Int) {
        var totalMade = 0
        var totalAttempts = 0
        for match in completedMatches {
            if isPlayer1(in: match) {
                totalMade += match[keyPath: p1Made]
                totalAttempts += match[keyPath: p1Total]
            } else {
                totalMade += match[keyPath: p2Made]
                totalAttempts += match[keyPath: p2Total]
            }
        }
        let pct = totalAttempts > 0 ? Double(totalMade) / Double(totalAttempts) * 100 : 0
        return (pct, totalMade, totalAttempts)
    }

    // Stat totals
    private var totalAces: Int { careerTotal(\.acesPlayer1, \.acesPlayer2) }
    private var totalDoubleFaults: Int { careerTotal(\.doubleFaultsPlayer1, \.doubleFaultsPlayer2) }
    private var totalWinners: Int { careerTotal(\.winnersPlayer1, \.winnersPlayer2) }
    private var totalUnforcedErrors: Int { careerTotal(\.unforcedErrorsPlayer1, \.unforcedErrorsPlayer2) }
    private var totalBreakPointsWon: Int { careerTotal(\.breakPointsWonPlayer1, \.breakPointsWonPlayer2) }
    /// Break point opportunities = break points faced by the opponent (when this player was returning)
    private var totalBreakPointOpportunities: Int { careerTotal(\.breakPointsFacedPlayer2, \.breakPointsFacedPlayer1) }

    private var firstServeStats: (pct: Double, made: Int, total: Int) {
        careerPercentage(made: \.firstServesMadePlayer1, \.firstServesMadePlayer2,
                         total: \.firstServeAttemptsPlayer1, \.firstServeAttemptsPlayer2)
    }

    private var firstServePtsWon: (pct: Double, made: Int, total: Int) {
        careerPercentage(made: \.pointsWonOnFirstServePlayer1, \.pointsWonOnFirstServePlayer2,
                         total: \.firstServesMadePlayer1, \.firstServesMadePlayer2)
    }

    private var secondServeStats: (pct: Double, made: Int, total: Int) {
        careerPercentage(made: \.secondServesMadePlayer1, \.secondServesMadePlayer2,
                         total: \.secondServeAttemptsPlayer1, \.secondServeAttemptsPlayer2)
    }

    private var secondServePtsWon: (pct: Double, made: Int, total: Int) {
        careerPercentage(made: \.pointsWonOnSecondServePlayer1, \.pointsWonOnSecondServePlayer2,
                         total: \.secondServesMadePlayer1, \.secondServesMadePlayer2)
    }

    private var favoriteSurface: CourtSurface? {
        guard !completedMatches.isEmpty else { return nil }
        var surfaceCounts: [CourtSurface: Int] = [:]
        for match in completedMatches {
            surfaceCounts[match.surface, default: 0] += 1
        }
        return surfaceCounts.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        ZStack {
            FSGradients.meshBackground
                .ignoresSafeArea()

            FSNetPattern(opacity: 0.02)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                    recordSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                    pointsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)

                    serveSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Players")
                            .font(FSTypography.label(13))
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
        .sheet(item: $selectedMatch) { match in
            NavigationStack {
                MatchDetailView(match: match)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
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

                Text("\(completedMatchCount) \(completedMatchCount == 1 ? "match" : "matches") completed")
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
                VStack(spacing: 8) {
                    Text("\(matchesWon)")
                        .font(FSTypography.display(56))
                        .foregroundStyle(FSColors.winner)
                    Text("WINS")
                        .font(FSTypography.label(10))
                        .tracking(1.5)
                        .foregroundStyle(FSColors.textMuted)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(FSColors.lineWhite.opacity(0.1))
                    .frame(width: 1, height: 80)

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

            VStack(spacing: 8) {
                GeometryReader { geo in
                    let winRatio = completedMatchCount > 0 ? CGFloat(matchesWon) / CGFloat(completedMatchCount) : 0.5

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FSColors.fault.opacity(0.3))
                        Capsule()
                            .fill(FSColors.winner)
                            .frame(width: geo.size.width * winRatio)
                    }
                }
                .frame(height: 8)

                Text(String(format: "%.0f%% Win Rate", winPercentage))
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.textSecondary)
            }

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
                        Capsule().fill(surface.themeColor.opacity(0.15))
                    )
                }
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

    // MARK: - Points Section

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CAREER STATISTICS")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                careerStatRow(label: "Aces", value: totalAces, icon: "bolt.fill", color: FSColors.ace)
                careerDivider
                careerStatRow(label: "Double Faults", value: totalDoubleFaults, icon: "xmark", color: FSColors.fault)
                careerDivider
                careerStatRow(label: "Winners", value: totalWinners, icon: "star.fill", color: FSColors.winner)
                careerDivider
                careerStatRow(label: "Unforced Errors", value: totalUnforcedErrors, icon: "exclamationmark.triangle.fill", color: FSColors.fault)
                careerDivider
                breakPointRow
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

    private func careerStatRow(label: String, value: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(FSTypography.label(11))
                .foregroundStyle(FSColors.textSecondary)

            Spacer()

            Text("\(value)")
                .font(FSTypography.mono(18))
                .foregroundStyle(FSColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var breakPointRow: some View {
        HStack {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 12))
                .foregroundStyle(FSColors.championship)
                .frame(width: 24)

            Text("Break Points Won")
                .font(FSTypography.label(11))
                .foregroundStyle(FSColors.textSecondary)

            Spacer()

            Text("\(totalBreakPointsWon)/\(totalBreakPointOpportunities)")
                .font(FSTypography.mono(18))
                .foregroundStyle(FSColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var careerDivider: some View {
        Rectangle()
            .fill(FSColors.lineWhite.opacity(0.04))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    // MARK: - Serve Section

    private var serveSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SERVE")
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                servePercentageRow(label: "1st Serve %", stats: firstServeStats)
                careerDivider
                servePercentageRow(label: "1st Serve Pts Won", stats: firstServePtsWon)
                careerDivider
                servePercentageRow(label: "2nd Serve %", stats: secondServeStats)
                careerDivider
                servePercentageRow(label: "2nd Serve Pts Won", stats: secondServePtsWon)
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

    private func servePercentageRow(label: String, stats: (pct: Double, made: Int, total: Int)) -> some View {
        HStack {
            Text(label)
                .font(FSTypography.label(11))
                .foregroundStyle(FSColors.textSecondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", stats.pct))
                    .font(FSTypography.mono(18))
                    .foregroundStyle(FSColors.textPrimary)

                if stats.total > 0 {
                    Text("\(stats.made)/\(stats.total)")
                        .font(FSTypography.label(9))
                        .foregroundStyle(FSColors.textMuted)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Match History Section

    private var matchHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MATCH HISTORY")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            if completedMatches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundStyle(FSColors.textMuted)

                    Text("No completed matches yet")
                        .font(FSTypography.body(14))
                        .foregroundStyle(FSColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(completedMatches.enumerated()), id: \.element.id) { index, match in
                        if index > 0 {
                            Divider()
                                .background(FSColors.lineWhite.opacity(0.06))
                        }
                        Button {
                            selectedMatch = match
                        } label: {
                            matchRow(match)
                        }
                        .buttonStyle(.plain)
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
        let didWin = match.winner?.id == player.id
        let opponent = isPlayer1(in: match) ? match.players.last : match.players.first

        return HStack(spacing: 14) {
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
                    Text(match.scoreString)
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

            HStack(spacing: 8) {
                Text(match.createdAt, style: .date)
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.textMuted)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(FSColors.textMuted)
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Player List View

struct PlayerListView: View {
    @Environment(\.dismiss) private var dismiss
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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
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
            }
        }
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

    private var completedCount: Int {
        player.matches.filter { $0.isComplete }.count
    }

    private var wins: Int {
        player.matches.filter { $0.isComplete && $0.winner?.id == player.id }.count
    }

    private var losses: Int {
        completedCount - wins
    }

    private var winPct: Double {
        guard completedCount > 0 else { return 0 }
        return Double(wins) / Double(completedCount) * 100
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
                    Text("\(wins)W - \(losses)L")
                        .font(FSTypography.mono(12))
                        .foregroundStyle(FSColors.textSecondary)

                    if completedCount > 0 {
                        Text("•")
                            .foregroundStyle(FSColors.textMuted)

                        Text(String(format: "%.0f%%", winPct))
                            .font(FSTypography.mono(12))
                            .foregroundStyle(winPct >= 50 ? FSColors.winner : FSColors.fault)
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
