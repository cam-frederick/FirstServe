//
//  HomeView.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.createdAt, order: .reverse) private var matches: [Match]
    @State private var showingNewMatch = false
    
    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    emptyState
                } else {
                    matchList
                }
            }
            .navigationTitle("FirstServe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewMatch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMatch) {
                NewMatchView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tennis.racket")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("No Matches Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to start your first match")
                .foregroundStyle(.secondary)
            
            Button("Start New Match") {
                showingNewMatch = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }
    
    private var matchList: some View {
        List {
            ForEach(matches) { match in
                NavigationLink {
                    if match.isComplete {
                        MatchDetailView(match: match)
                    } else {
                        LiveMatchView(match: match)
                    }
                } label: {
                    MatchRowView(match: match)
                }
            }
            .onDelete(perform: deleteMatches)
        }
    }
    
    private func deleteMatches(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(matches[index])
        }
    }
}

struct MatchRowView: View {
    let match: Match
    
    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(player1?.name ?? "Player 1")
                    .fontWeight(match.winner?.id == player1?.id ? .bold : .regular)
                
                Spacer()
                
                if !match.scoreString.isEmpty {
                    Text(match.scoreString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text(player2?.name ?? "Player 2")
                    .fontWeight(match.winner?.id == player2?.id ? .bold : .regular)
                
                Spacer()
            }
            
            HStack {
                Label(match.surface.rawValue, systemImage: "sportscourt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if match.isComplete {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("In Progress", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Full match summary for completed matches
struct MatchDetailView: View {
    let match: Match
    
    private var player1: Player? { match.players.first }
    private var player2: Player? { match.players.last }
    
    private var duration: String? {
        guard let completedAt = match.completedAt else { return nil }
        let interval = completedAt.timeIntervalSince(match.createdAt)
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Winner banner
                winnerBanner
                
                // Set-by-set scores
                setScoresSection
                
                // Stats comparison
                statsSection
                
                // Match info
                infoSection
            }
            .padding()
        }
        .navigationTitle("Match Summary")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Winner Banner
    
    private var winnerBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            
            if let winner = match.winner {
                Text("\(winner.name) Wins!")
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("Match Complete")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text("Final: \(match.scoreString)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Set-by-Set Scores
    
    private var setScoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            ForEach(match.sets.enumerated().map({ $0 }), id: \.offset) { index, set in
                setRow(index: index, set: set)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func setRow(index: Int, set: TennisSet) -> some View {
        let p1Won = set.gamesPlayer1 > set.gamesPlayer2
        let p2Won = set.gamesPlayer2 > set.gamesPlayer1
        
        return HStack {
            Text("Set \(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            Text(player1?.name ?? "P1")
                .font(.subheadline)
                .fontWeight(p1Won ? .bold : .regular)
                .foregroundStyle(p1Won ? .green : .primary)
                .frame(width: 60, alignment: .trailing)
            
            Text("\(set.gamesPlayer1) - \(set.gamesPlayer2)")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(width: 60)
            
            Text(player2?.name ?? "P2")
                .font(.subheadline)
                .fontWeight(p2Won ? .bold : .regular)
                .foregroundStyle(p2Won ? .green : .primary)
                .frame(width: 60, alignment: .leading)
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Stats Comparison
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            statRow(label: "Aces", p1: match.acesPlayer1, p2: match.acesPlayer2)
            statRow(label: "Double Faults", p1: match.doubleFaultsPlayer1, p2: match.doubleFaultsPlayer2)
            statRow(label: "Winners", p1: match.winnersPlayer1, p2: match.winnersPlayer2)
            statRow(label: "Unforced Errors", p1: match.unforcedErrorsPlayer1, p2: match.unforcedErrorsPlayer2)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statRow(label: String, p1: Int, p2: Int) -> some View {
        HStack {
            Text("\(p1)")
                .font(.headline)
                .fontWeight(p1 > p2 ? .bold : .regular)
                .foregroundStyle(p1 > p2 ? .blue : .primary)
                .frame(width: 40, alignment: .trailing)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("\(p2)")
                .font(.headline)
                .fontWeight(p2 > p1 ? .bold : .regular)
                .foregroundStyle(p2 > p1 ? .blue : .primary)
                .frame(width: 40, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Match Info
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Info")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            infoRow(label: "Format", value: match.format.rawValue)
            infoRow(label: "Surface", value: match.surface.rawValue)
            
            if let location = match.location {
                infoRow(label: "Location", value: location)
            }
            
            if let dur = duration {
                infoRow(label: "Duration", value: dur)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
}
