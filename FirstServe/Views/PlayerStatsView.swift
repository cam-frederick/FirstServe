//
//  PlayerStatsView.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData

struct PlayerStatsView: View {
    let player: Player
    
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
    
    private var favoriteSurface: String {
        guard !player.matches.isEmpty else { return "N/A" }
        
        var surfaceCounts: [CourtSurface: Int] = [:]
        for match in player.matches {
            surfaceCounts[match.surface, default: 0] += 1
        }
        
        let favorite = surfaceCounts.max(by: { $0.value < $1.value })
        return favorite?.key.rawValue ?? "N/A"
    }
    
    private var matchesLost: Int {
        player.matchesPlayed - player.matchesWon
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Player header
                headerSection
                
                // Win/Loss record
                recordSection
                
                // Career stats
                statsSection
                
                // Match history
                matchHistorySection
            }
            .padding()
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text(player.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(player.matchesPlayed) matches played")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Win/Loss Record
    
    private var recordSection: some View {
        VStack(spacing: 12) {
            Text("Record")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 32) {
                VStack {
                    Text("\(player.matchesWon)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Wins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("-")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)
                
                VStack {
                    Text("\(matchesLost)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.red)
                    Text("Losses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(String(format: "%.0f%% Win Rate", player.winPercentage))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Career Stats
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Career Stats")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            HStack {
                statCard(title: "Aces", value: totalAces, icon: "bolt.fill", color: .orange)
                statCard(title: "Winners", value: totalWinners, icon: "star.fill", color: .purple)
            }
            
            HStack {
                Text("Favorite Surface")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Label(favoriteSurface, systemImage: "sportscourt")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statCard(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Match History
    
    private var matchHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match History")
                .font(.headline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            if player.matches.isEmpty {
                Text("No matches yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(player.matches.sorted(by: { $0.createdAt > $1.createdAt })) { match in
                    matchRow(match)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func matchRow(_ match: Match) -> some View {
        let isPlayer1 = match.players.first?.id == player.id
        let opponent = isPlayer1 ? match.players.last : match.players.first
        let didWin = match.winner?.id == player.id
        
        return HStack {
            // Win/Loss indicator
            Image(systemName: didWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(didWin ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponent?.name ?? "Unknown")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(match.scoreString.isEmpty ? "In Progress" : match.scoreString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(match.surface.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(didWin ? "W" : "L")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(didWin ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Player List View

struct PlayerListView: View {
    @Query(sort: \Player.name) private var players: [Player]
    
    var body: some View {
        List(players) { player in
            NavigationLink {
                PlayerStatsView(player: player)
            } label: {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(player.name)
                            .font(.headline)
                        
                        Text("\(player.matchesWon) - \(player.matchesPlayed - player.matchesWon)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", player.winPercentage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Players")
    }
}

#Preview {
    NavigationStack {
        PlayerStatsView(player: Player(name: "John Doe"))
    }
}
