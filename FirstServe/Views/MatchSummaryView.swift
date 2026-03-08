//
//  MatchSummaryView.swift
//  FirstServe
//
//  Comprehensive post-match summary with visual stats
//  Created by Cici on 2/14/26.
//

import SwiftUI
import Charts
import SwiftData

struct MatchSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let match: Match
    @State private var showingStats = false

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FSColors.backgroundDeep
                    .ignoresSafeArea()
                
                FSNetPattern(opacity: 0.02)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Winner celebration
                        winnerSection
                        
                        // Match info card
                        matchInfoCard
                        
                        // Score progression timeline
                        scoreProgressionSection
                        
                        // Visual stats charts
                        visualStatsSection
                        
                        // Share button
                        shareSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Match Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showingStats = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 12))
                            Text("Stats")
                                .font(FSTypography.label(12))
                        }
                        .foregroundStyle(FSColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(FSColors.backgroundCard)
                                .overlay(
                                    Capsule()
                                        .stroke(FSColors.lineWhite.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(FSTypography.label(14))
                            .foregroundStyle(FSColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsView(match: match)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Winner Section
    
    private var winnerSection: some View {
        VStack(spacing: 20) {
            // Trophy icon
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
            
            // Winner name and score
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
                    .font(FSTypography.score(32))
                    .foregroundStyle(FSColors.textSecondary)
                    .padding(.top, 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.winner?.name ?? "Unknown") wins! Final score: \(match.scoreString)")
    }
    
    // MARK: - Match Info Card
    
    private var matchInfoCard: some View {
        VStack(spacing: 16) {
            // Surface and format badges
            HStack(spacing: 12) {
                // Surface badge
                HStack(spacing: 6) {
                    Image(systemName: match.surface.icon)
                        .font(.system(size: 12))
                    Text(match.surface.rawValue)
                        .font(FSTypography.label(10))
                        .tracking(0.5)
                }
                .foregroundStyle(match.surface.themeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(match.surface.themeColor.opacity(0.15))
                )
                
                // Format badge
                Text(match.format.displayName)
                    .font(FSTypography.label(10))
                    .tracking(0.5)
                    .foregroundStyle(FSColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(FSColors.backgroundElevated)
                    )
                
                Spacer()
            }
            
            Divider().background(FSColors.lineWhite.opacity(0.06))
            
            // Match duration
            if let completedAt = match.completedAt {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FSColors.textMuted)
                    
                    Text("Duration")
                        .font(FSTypography.body(14))
                        .foregroundStyle(FSColors.textSecondary)
                    
                    Spacer()
                    
                    Text(formatDuration(from: match.createdAt, to: completedAt))
                        .font(FSTypography.body(14))
                        .fontWeight(.medium)
                        .foregroundStyle(FSColors.textPrimary)
                }
            }
            
            // Location if available
            if let location = match.location {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FSColors.textMuted)
                    
                    Text("Location")
                        .font(FSTypography.body(14))
                        .foregroundStyle(FSColors.textSecondary)
                    
                    Spacer()
                    
                    Text(location)
                        .font(FSTypography.body(14))
                        .fontWeight(.medium)
                        .foregroundStyle(FSColors.textPrimary)
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
    
    // MARK: - Score Progression
    
    private var scoreProgressionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCORE PROGRESSION")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
            
            VStack(spacing: 12) {
                ForEach(Array(match.sets.enumerated()), id: \.offset) { index, set in
                    setProgressionRow(setNumber: index + 1, set: set)
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
    }
    
    private func setProgressionRow(setNumber: Int, set: TennisSet) -> some View {
        HStack {
            // Set number
            Text("Set \(setNumber)")
                .font(FSTypography.label(11))
                .foregroundStyle(FSColors.textMuted)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Player 1 score
            Text("\(set.gamesPlayer1)")
                .font(FSTypography.score(24))
                .foregroundStyle(set.gamesPlayer1 > set.gamesPlayer2 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 50)
            
            // Separator
            Text("–")
                .font(FSTypography.score(20))
                .foregroundStyle(FSColors.textMuted)
            
            // Player 2 score
            Text("\(set.gamesPlayer2)")
                .font(FSTypography.score(24))
                .foregroundStyle(set.gamesPlayer2 > set.gamesPlayer1 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 50)
            
            Spacer()
            
            // Tiebreak indicator if applicable
            if set.tiebreakScorePlayer1 != nil {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text("TB")
                        .font(FSTypography.label(8))
                }
                .foregroundStyle(FSColors.ace)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(FSColors.ace.opacity(0.15))
                )
            }
        }
    }
    
    // MARK: - Visual Stats Section
    
    private var visualStatsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MATCH STATISTICS")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
            
            // Total points won
            totalPointsCard

            // Serve percentage donut chart
            servePercentageChart
            
            // Winners vs Errors comparison
            winnersErrorsChart
            
            // Shot type breakdown
            shotTypeBreakdownChart
        }
    }
    
    private var servePercentageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("First Serve %")
                .font(FSTypography.body(15))
                .fontWeight(.semibold)
                .foregroundStyle(FSColors.textPrimary)
            
            HStack(spacing: 32) {
                // Player 1
                VStack(spacing: 12) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(FSColors.lineWhite.opacity(0.1), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: match.firstServePercentagePlayer1 / 100)
                            .stroke(FSColors.hardCourt, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: match.firstServePercentagePlayer1)
                        
                        // Percentage text
                        Text(String(format: "%.0f%%", match.firstServePercentagePlayer1))
                            .font(FSTypography.score(20))
                            .foregroundStyle(FSColors.textPrimary)
                    }
                    
                    Text(player1?.name ?? "P1")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }
                
                // Player 2
                VStack(spacing: 12) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(FSColors.lineWhite.opacity(0.1), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: match.firstServePercentagePlayer2 / 100)
                            .stroke(FSColors.clay, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: match.firstServePercentagePlayer2)
                        
                        // Percentage text
                        Text(String(format: "%.0f%%", match.firstServePercentagePlayer2))
                            .font(FSTypography.score(20))
                            .foregroundStyle(FSColors.textPrimary)
                    }
                    
                    Text(player2?.name ?? "P2")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
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
    
    private var totalPointsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Points Won")
                .font(FSTypography.body(15))
                .fontWeight(.semibold)
                .foregroundStyle(FSColors.textPrimary)

            HStack(spacing: 32) {
                // Player 1
                VStack(spacing: 8) {
                    Text("\(match.totalPointsWonPlayer1)")
                        .font(FSTypography.score(36))
                        .foregroundStyle(match.totalPointsWonPlayer1 >= match.totalPointsWonPlayer2 ? FSColors.textPrimary : FSColors.textSecondary)

                    Text(player1?.name ?? "P1")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }

                // Player 2
                VStack(spacing: 8) {
                    Text("\(match.totalPointsWonPlayer2)")
                        .font(FSTypography.score(36))
                        .foregroundStyle(match.totalPointsWonPlayer2 >= match.totalPointsWonPlayer1 ? FSColors.textPrimary : FSColors.textSecondary)

                    Text(player2?.name ?? "P2")
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
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

    private var winnersErrorsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Winners vs Unforced Errors")
                .font(FSTypography.body(15))
                .fontWeight(.semibold)
                .foregroundStyle(FSColors.textPrimary)
            
            VStack(spacing: 20) {
                // Player 1
                playerStatBar(
                    name: player1?.name ?? "P1",
                    winners: match.winnersPlayer1,
                    errors: match.unforcedErrorsPlayer1,
                    color: FSColors.hardCourt
                )
                
                // Player 2
                playerStatBar(
                    name: player2?.name ?? "P2",
                    winners: match.winnersPlayer2,
                    errors: match.unforcedErrorsPlayer2,
                    color: FSColors.clay
                )
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
    
    private func playerStatBar(name: String, winners: Int, errors: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(FSTypography.label(11))
                .foregroundStyle(FSColors.textSecondary)
            
            // Winners bar
            HStack(spacing: 8) {
                Text("W")
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.winner)
                    .frame(width: 20)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(FSColors.winner)
                            .frame(width: barWidth(value: winners, max: max(match.winnersPlayer1 + match.winnersPlayer2, 1), totalWidth: geometry.size.width - 60))
                            .animation(.easeInOut(duration: 0.8), value: winners)
                        
                        Spacer()
                    }
                }
                .frame(height: 20)
                .background(FSColors.lineWhite.opacity(0.05))
                .cornerRadius(4)
                
                Text("\(winners)")
                    .font(FSTypography.body(13))
                    .foregroundStyle(FSColors.textPrimary)
                    .frame(width: 30, alignment: .trailing)
            }
            
            // Errors bar
            HStack(spacing: 8) {
                Text("E")
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.fault)
                    .frame(width: 20)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(FSColors.fault)
                            .frame(width: barWidth(value: errors, max: max(match.unforcedErrorsPlayer1 + match.unforcedErrorsPlayer2, 1), totalWidth: geometry.size.width - 60))
                            .animation(.easeInOut(duration: 0.8), value: errors)
                        
                        Spacer()
                    }
                }
                .frame(height: 20)
                .background(FSColors.lineWhite.opacity(0.05))
                .cornerRadius(4)
                
                Text("\(errors)")
                    .font(FSTypography.body(13))
                    .foregroundStyle(FSColors.textPrimary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
    
    private func barWidth(value: Int, max: Int, totalWidth: CGFloat) -> CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(value) / CGFloat(max) * totalWidth
    }
    
    private var shotTypeBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shot Type Breakdown")
                .font(FSTypography.body(15))
                .fontWeight(.semibold)
                .foregroundStyle(FSColors.textPrimary)
            
            VStack(spacing: 16) {
                // Winners breakdown
                shotCategoryBreakdown(title: "Winners", statType: .winner, color: FSColors.winner)
                
                Divider().background(FSColors.lineWhite.opacity(0.06))
                
                // Errors breakdown
                shotCategoryBreakdown(title: "Unforced Errors", statType: .unforcedError, color: FSColors.fault)
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
    
    private func shotCategoryBreakdown(title: String, statType: StatType, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title.uppercased())
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(color)
            }
            
            HStack(spacing: 12) {
                shotTypeColumn(
                    playerName: player1?.name ?? "P1",
                    statType: statType,
                    playerNumber: 1,
                    color: FSColors.hardCourt.opacity(0.7)
                )
                
                shotTypeColumn(
                    playerName: player2?.name ?? "P2",
                    statType: statType,
                    playerNumber: 2,
                    color: FSColors.clay.opacity(0.7)
                )
            }
        }
    }
    
    private func shotTypeColumn(playerName: String, statType: StatType, playerNumber: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(playerName)
                .font(FSTypography.label(10))
                .foregroundStyle(FSColors.textSecondary)
            
            VStack(alignment: .leading, spacing: 6) {
                shotTypeRow(label: "FH GS", shotType: .forehand, contactType: .groundstroke, statType: statType, playerNumber: playerNumber)
                shotTypeRow(label: "BH GS", shotType: .backhand, contactType: .groundstroke, statType: statType, playerNumber: playerNumber)
                shotTypeRow(label: "FH V", shotType: .forehand, contactType: .volley, statType: statType, playerNumber: playerNumber)
                shotTypeRow(label: "BH V", shotType: .backhand, contactType: .volley, statType: statType, playerNumber: playerNumber)
                shotTypeRow(label: "OH", shotType: .forehand, contactType: .overhead, statType: statType, playerNumber: playerNumber)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    private func shotTypeRow(label: String, shotType: ShotType, contactType: ContactType, statType: StatType, playerNumber: Int) -> some View {
        let count = match.shotStatistics.filter {
            $0.playerNumber == playerNumber && $0.statType == statType && $0.shotType == shotType && $0.contactType == contactType
        }.count
        
        return HStack {
            Text(label)
                .font(FSTypography.label(9))
                .foregroundStyle(FSColors.textMuted)
                .frame(width: 45, alignment: .leading)
            
            Text("\(count)")
                .font(FSTypography.body(13))
                .fontWeight(.medium)
                .foregroundStyle(count > 0 ? FSColors.textPrimary : FSColors.textMuted.opacity(0.5))
        }
    }
    
    // MARK: - Share Section
    
    private var shareSection: some View {
        ShareLink(item: generateShareText()) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Share Match Summary")
                    .font(FSTypography.body(16))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [FSColors.championship, FSColors.championship.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    private func generateShareText() -> String {
        var text = "🎾 FirstServe Match Summary\n\n"
        
        if let winner = match.winner {
            text += "\(winner.name) defeats "
            if let loser = match.players.first(where: { $0.id != winner.id }) {
                text += "\(loser.name)\n"
            }
        }
        
        text += "\(match.scoreString)\n\n"
        text += "📍 \(match.surface.rawValue) | \(match.format.displayName)\n"
        
        if let completedAt = match.completedAt {
            text += "⏱️ \(formatDuration(from: match.createdAt, to: completedAt))\n\n"
        }
        
        text += "Key Stats:\n"
        text += "Aces: \(match.acesPlayer1) - \(match.acesPlayer2)\n"
        text += "Winners: \(match.winnersPlayer1) - \(match.winnersPlayer2)\n"
        text += "Errors: \(match.unforcedErrorsPlayer1) - \(match.unforcedErrorsPlayer2)\n"
        text += "1st Serve: \(String(format: "%.0f%%", match.firstServePercentagePlayer1)) - \(String(format: "%.0f%%", match.firstServePercentagePlayer2))\n\n"
        
        text += "#FirstServe #Tennis"
        
        return text
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self, configurations: config)
    
    let player1 = Player(name: "Cam")
    let player2 = Player(name: "Opponent")
    let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
    
    // Simulate a completed match
    let _ = {
        match.startNewSet()
        match.completedAt = Date()
        match.acesPlayer1 = 5
        match.acesPlayer2 = 3
        match.winnersPlayer1 = 12
        match.winnersPlayer2 = 8
        match.unforcedErrorsPlayer1 = 7
        match.unforcedErrorsPlayer2 = 11
        container.mainContext.insert(match)
        container.mainContext.insert(player1)
        container.mainContext.insert(player2)
    }()

    MatchSummaryView(match: match)
        .modelContainer(container)
}
