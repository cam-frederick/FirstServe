//
//  ContentView.swift
//  MatchPoint
//
//  Created by Cici on 1/29/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [Match]

    var body: some View {
        NavigationStack {
            List {
                ForEach(matches) { match in
                    NavigationLink {
                        MatchDetailView(match: match)
                    } label: {
                        MatchRowView(match: match)
                    }
                }
                .onDelete(perform: deleteMatches)
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addMatch) {
                        Label("Add Match", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if matches.isEmpty {
                    ContentUnavailableView {
                        Label("No Matches", systemImage: "tennisball")
                    } description: {
                        Text("Tap the + button to start a new match.")
                    }
                }
            }
        }
    }

    private func addMatch() {
        withAnimation {
            let player1 = Player(name: "You")
            let player2 = Player(name: "Opponent")
            let newMatch = Match(
                player1: player1,
                player2: player2,
                format: .bestOf3,
                surface: .hardCourt
            )
            modelContext.insert(newMatch)
        }
    }

    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(matches[index])
            }
        }
    }
}

struct MatchRowView: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(match.players.first?.name ?? "Player 1")
                    .fontWeight(match.winner?.id == match.players.first?.id ? .bold : .regular)
                Text("vs")
                    .foregroundStyle(.secondary)
                Text(match.players.last?.name ?? "Player 2")
                    .fontWeight(match.winner?.id == match.players.last?.id ? .bold : .regular)
            }
            .font(.headline)

            HStack {
                Text(match.scoreString.isEmpty ? "Not started" : match.scoreString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(match.surface.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct MatchDetailView: View {
    let match: Match

    var body: some View {
        Text("Match Detail")
            .navigationTitle("Match")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Match.self, inMemory: true)
}
