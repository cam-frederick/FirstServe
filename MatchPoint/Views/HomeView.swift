//
//  HomeView.swift
//  MatchPoint
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
            .navigationTitle("MatchPoint")
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

// Placeholder for match detail view (for completed matches)
struct MatchDetailView: View {
    let match: Match
    
    var body: some View {
        VStack {
            Text("Match Details")
                .font(.title)
            Text(match.scoreString)
            // TODO: Add detailed stats view
        }
        .navigationTitle("Match Summary")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
}
