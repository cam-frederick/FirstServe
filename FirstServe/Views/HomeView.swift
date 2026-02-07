//
//  HomeView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.createdAt, order: .reverse) private var matches: [Match]
    @Query private var players: [Player]
    @State private var showingNewMatch = false
    @State private var showingPlayerList = false
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Mesh gradient background
                FSGradients.meshBackground
                    .ignoresSafeArea()

                // Subtle net pattern overlay
                FSNetPattern(opacity: 0.02)
                    .ignoresSafeArea()

                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.bottom, 32)

                        if matches.isEmpty {
                            emptyState
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            matchesSection
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !players.isEmpty {
                        Button {
                            showingPlayerList = true
                        } label: {
                            Image(systemName: "person.2")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FSColors.textSecondary)
                        }
                        .accessibilityLabel("View players")
                        .accessibilityHint("Double tap to view and manage players")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewMatch = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(FSColors.textPrimary)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(FSColors.courtGreen)
                            )
                    }
                    .accessibilityLabel("New match")
                    .accessibilityHint("Double tap to start a new match")
                }
            }
            .sheet(isPresented: $showingNewMatch) {
                NewMatchView()
            }
            .navigationDestination(isPresented: $showingPlayerList) {
                PlayerListView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FIRSTSERVE")
                        .font(FSTypography.label(11))
                        .tracking(4)
                        .foregroundStyle(FSColors.textMuted)

                    Text("Your\nMatches")
                        .font(FSTypography.headline(38))
                        .foregroundStyle(FSColors.textPrimary)
                        .lineSpacing(4)
                }

                Spacer()

                // Stats pill
                if !matches.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(matches.count)")
                            .font(FSTypography.score(32))
                            .foregroundStyle(FSColors.championship)

                        Text(matches.count == 1 ? "MATCH" : "MATCHES")
                            .font(FSTypography.label(10))
                            .tracking(2)
                            .foregroundStyle(FSColors.textMuted)
                    }
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(matches.count) \(matches.count == 1 ? "match" : "matches") recorded")
                }
            }

            CourtLineAccent(width: 80)
                .opacity(appearAnimation ? 1 : 0)
                .offset(x: appearAnimation ? 0 : -20)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 60)

            // Decorative court element
            ZStack {
                // Court baseline
                RoundedRectangle(cornerRadius: 4)
                    .fill(FSColors.lineWhite.opacity(0.1))
                    .frame(width: 200, height: 120)
                    .overlay(
                        // Service box lines
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(FSColors.lineWhite.opacity(0.15))
                                .frame(height: 1)
                            Spacer()
                            Rectangle()
                                .fill(FSColors.lineWhite.opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 30)
                    )
                    .overlay(
                        // Center line
                        Rectangle()
                            .fill(FSColors.lineWhite.opacity(0.15))
                            .frame(width: 1)
                    )

                // Tennis ball
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FSColors.ballYellow, FSColors.ballYellow.opacity(0.7)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: FSColors.ballYellow.opacity(0.3), radius: 15)
                    .offset(x: 50, y: -30)
            }
            .opacity(appearAnimation ? 1 : 0)
            .scaleEffect(appearAnimation ? 1 : 0.8)

            VStack(spacing: 12) {
                Text("No Matches Yet")
                    .font(FSTypography.headline(24))
                    .foregroundStyle(FSColors.textPrimary)

                Text("Start tracking your tennis journey")
                    .font(FSTypography.body(15))
                    .foregroundStyle(FSColors.textSecondary)
            }

            Button {
                showingNewMatch = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New Match")
                }
            }
            .buttonStyle(FSPrimaryButtonStyle())
            .padding(.top, 8)
            .accessibilityLabel("Start new match")
            .accessibilityHint("Double tap to create your first tennis match")

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Matches Section

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Active matches
            let activeMatches = matches.filter { !$0.isComplete }
            if !activeMatches.isEmpty {
                sectionHeader(title: "IN PROGRESS", count: activeMatches.count, color: FSColors.ace)

                ForEach(Array(activeMatches.enumerated()), id: \.element.id) { index, match in
                    NavigationLink {
                        LiveMatchView(match: match)
                    } label: {
                        MatchCard(match: match, isActive: true)
                    }
                    .buttonStyle(.plain)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: appearAnimation)
                }
            }

            // Completed matches
            let completedMatches = matches.filter { $0.isComplete }
            if !completedMatches.isEmpty {
                sectionHeader(title: "COMPLETED", count: completedMatches.count, color: FSColors.textMuted)
                    .padding(.top, activeMatches.isEmpty ? 0 : 16)

                ForEach(Array(completedMatches.enumerated()), id: \.element.id) { index, match in
                    NavigationLink {
                        MatchDetailView(match: match)
                    } label: {
                        MatchCard(match: match, isActive: false)
                    }
                    .buttonStyle(.plain)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(Double(index + activeMatches.count) * 0.08), value: appearAnimation)
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(color)

            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text("\(count)")
                .font(FSTypography.mono(12))
                .foregroundStyle(color.opacity(0.7))

            Spacer()
        }
    }

    private func deleteMatches(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(matches[index])
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: Match
    let isActive: Bool

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }
    
    private var accessibilityLabel: String {
        var label = ""
        if isActive {
            label += "Live match. "
        } else if let winner = match.winner {
            label += "\(winner.name) won. "
        }
        
        label += "\(player1?.name ?? "Player 1") vs \(player2?.name ?? "Player 2"). "
        
        if !match.scoreString.isEmpty {
            label += "Score: \(match.scoreString). "
        }
        
        label += "Played on \(match.surface.rawValue)"
        
        return label
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: 16) {
                // Players & Score
                VStack(alignment: .leading, spacing: 12) {
                    playerRow(
                        name: player1?.name ?? "Player 1",
                        isWinner: match.winner?.id == player1?.id,
                        isServing: !match.isComplete && (match.currentSet?.currentGame?.serverIsPlayer1 ?? false)
                    )

                    playerRow(
                        name: player2?.name ?? "Player 2",
                        isWinner: match.winner?.id == player2?.id,
                        isServing: !match.isComplete && !(match.currentSet?.currentGame?.serverIsPlayer1 ?? true)
                    )
                }

                Spacer()

                // Set scores
                if !match.scoreString.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(match.sets.indices, id: \.self) { index in
                            setScoreColumn(set: match.sets[index])
                        }
                    }
                }

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FSColors.textMuted)
            }
            .padding(20)

            // Footer with surface and status
            HStack {
                // Surface badge
                HStack(spacing: 6) {
                    Image(systemName: match.surface.icon)
                        .font(.system(size: 10))
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

                Spacer()

                // Status
                if isActive {
                    HStack(spacing: 6) {
                        PulsingDot(color: FSColors.ace)
                        Text("LIVE")
                            .font(FSTypography.label(10))
                            .tracking(1)
                            .foregroundStyle(FSColors.ace)
                    }
                } else if let winner = match.winner {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(FSColors.championship)
                        Text(winner.name)
                            .font(FSTypography.label(10))
                            .foregroundStyle(FSColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(FSColors.backgroundDeep.opacity(0.5))
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FSColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isActive ? FSColors.ace.opacity(0.3) : FSColors.lineWhite.opacity(0.06),
                            lineWidth: isActive ? 1.5 : 1
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to \(isActive ? "continue" : "view details of") this match")
    }

    private func playerRow(name: String, isWinner: Bool, isServing: Bool) -> some View {
        HStack(spacing: 10) {
            ServingIndicator(isServing: isServing)

            Text(name)
                .font(FSTypography.body(16))
                .fontWeight(isWinner ? .bold : .regular)
                .foregroundStyle(isWinner ? FSColors.championship : FSColors.textPrimary)

            if isWinner {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FSColors.championship)
            }
        }
    }

    private func setScoreColumn(set: TennisSet) -> some View {
        VStack(spacing: 4) {
            Text("\(set.gamesPlayer1)")
                .font(FSTypography.score(22))
                .foregroundStyle(
                    set.gamesPlayer1 > set.gamesPlayer2 ? FSColors.textPrimary : FSColors.textSecondary
                )

            Text("\(set.gamesPlayer2)")
                .font(FSTypography.score(22))
                .foregroundStyle(
                    set.gamesPlayer2 > set.gamesPlayer1 ? FSColors.textPrimary : FSColors.textSecondary
                )
        }
        .frame(minWidth: 28)
    }
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    let match: Match
    @State private var appearAnimation = false

    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }

    private var duration: String? {
        guard let completedAt = match.completedAt else { return nil }
        let interval = completedAt.timeIntervalSince(match.createdAt)
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    var body: some View {
        ZStack {
            FSGradients.meshBackground
                .ignoresSafeArea()

            FSNetPattern(opacity: 0.02)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Winner celebration
                    winnerSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 30)

                    // Score breakdown
                    scoreSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                    // Statistics
                    statsSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

                    // Match info
                    infoSection
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: generateShareText()) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(FSColors.textPrimary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
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
        if let dur = duration {
            text += "⏱️ \(dur)\n"
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

    // MARK: - Winner Section

    private var winnerSection: some View {
        VStack(spacing: 20) {
            // Trophy with glow
            ZStack {
                Circle()
                    .fill(FSColors.championship.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(FSColors.championship.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FSColors.championship, FSColors.championship.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: FSColors.championship.opacity(0.4), radius: 30)

            VStack(spacing: 8) {
                if let winner = match.winner {
                    Text(winner.name)
                        .font(FSTypography.headline(32))
                        .foregroundStyle(FSColors.textPrimary)

                    Text("CHAMPION")
                        .font(FSTypography.label(12))
                        .tracking(4)
                        .foregroundStyle(FSColors.championship)
                }

                Text(match.scoreString)
                    .font(FSTypography.score(24))
                    .foregroundStyle(FSColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SET BY SET")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("")
                        .frame(width: 100, alignment: .leading)

                    ForEach(match.sets.indices, id: \.self) { index in
                        Text("S\(index + 1)")
                            .font(FSTypography.label(10))
                            .foregroundStyle(FSColors.textMuted)
                            .frame(width: 40)
                    }

                    Spacer()
                }

                // Player 1
                HStack {
                    HStack(spacing: 8) {
                        if match.winner?.id == player1?.id {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(FSColors.championship)
                        }
                        Text(player1?.name ?? "P1")
                            .font(FSTypography.body(15))
                            .fontWeight(match.winner?.id == player1?.id ? .bold : .regular)
                            .foregroundStyle(FSColors.textPrimary)
                    }
                    .frame(width: 100, alignment: .leading)

                    ForEach(match.sets.indices, id: \.self) { index in
                        let set = match.sets[index]
                        let won = set.gamesPlayer1 > set.gamesPlayer2
                        Text("\(set.gamesPlayer1)")
                            .font(FSTypography.score(20))
                            .foregroundStyle(won ? FSColors.winner : FSColors.textSecondary)
                            .frame(width: 40)
                    }

                    Spacer()
                }

                Divider()
                    .background(FSColors.textMuted.opacity(0.2))

                // Player 2
                HStack {
                    HStack(spacing: 8) {
                        if match.winner?.id == player2?.id {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(FSColors.championship)
                        }
                        Text(player2?.name ?? "P2")
                            .font(FSTypography.body(15))
                            .fontWeight(match.winner?.id == player2?.id ? .bold : .regular)
                            .foregroundStyle(FSColors.textPrimary)
                    }
                    .frame(width: 100, alignment: .leading)

                    ForEach(match.sets.indices, id: \.self) { index in
                        let set = match.sets[index]
                        let won = set.gamesPlayer2 > set.gamesPlayer1
                        Text("\(set.gamesPlayer2)")
                            .font(FSTypography.score(20))
                            .foregroundStyle(won ? FSColors.winner : FSColors.textSecondary)
                            .frame(width: 40)
                    }

                    Spacer()
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
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STATISTICS")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            VStack(spacing: 16) {
                statComparisonRow(label: "Aces", p1: match.acesPlayer1, p2: match.acesPlayer2, icon: "bolt.fill", color: FSColors.ace)
                statComparisonRow(label: "Double Faults", p1: match.doubleFaultsPlayer1, p2: match.doubleFaultsPlayer2, icon: "xmark", color: FSColors.fault)
                statComparisonRow(label: "Winners", p1: match.winnersPlayer1, p2: match.winnersPlayer2, icon: "star.fill", color: FSColors.winner)
                statComparisonRow(label: "Unforced Errors", p1: match.unforcedErrorsPlayer1, p2: match.unforcedErrorsPlayer2, icon: "exclamationmark.triangle.fill", color: FSColors.textMuted)
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
    }

    private func statComparisonRow(label: String, p1: Int, p2: Int, icon: String, color: Color) -> some View {
        HStack {
            Text("\(p1)")
                .font(FSTypography.score(22))
                .foregroundStyle(p1 > p2 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 40, alignment: .trailing)

            // Progress bar
            GeometryReader { geo in
                let total = max(p1 + p2, 1)
                let p1Ratio = CGFloat(p1) / CGFloat(total)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FSColors.backgroundElevated)

                    Capsule()
                        .fill(color.opacity(0.6))
                        .frame(width: geo.size.width * p1Ratio)
                }
            }
            .frame(height: 6)

            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(label)
                    .font(FSTypography.label(9))
                    .foregroundStyle(FSColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 80)

            // Progress bar
            GeometryReader { geo in
                let total = max(p1 + p2, 1)
                let p2Ratio = CGFloat(p2) / CGFloat(total)

                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(FSColors.backgroundElevated)

                    Capsule()
                        .fill(color.opacity(0.6))
                        .frame(width: geo.size.width * p2Ratio)
                }
            }
            .frame(height: 6)

            Text("\(p2)")
                .font(FSTypography.score(22))
                .foregroundStyle(p2 > p1 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 40, alignment: .leading)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MATCH INFO")
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)

            HStack(spacing: 12) {
                infoChip(icon: match.surface.icon, label: match.surface.rawValue, color: match.surface.themeColor)
                infoChip(icon: "flag.checkered", label: match.format.rawValue, color: FSColors.textSecondary)

                if let dur = duration {
                    infoChip(icon: "clock", label: dur, color: FSColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    private func infoChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(FSTypography.label(11))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
}
