//
//  LiveMatchView.swift
//  MatchPoint
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData

struct LiveMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let match: Match
    @State private var viewModel = MatchViewModel()
    @State private var showingEndMatchAlert = false
    @State private var showingStatsSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Match header
            matchHeader
            
            Divider()
            
            // Score display
            ScrollView {
                VStack(spacing: 24) {
                    scoreBoard
                    
                    if !match.isComplete {
                        currentGameScore
                        
                        Divider()
                        
                        scoringButtons
                        
                        statsButtons
                    } else {
                        matchCompleteView
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !match.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Match") {
                        showingEndMatchAlert = true
                    }
                }
            }
        }
        .alert("End Match Early?", isPresented: $showingEndMatchAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Match", role: .destructive) {
                viewModel.endMatch()
                dismiss()
            }
        } message: {
            Text("This match is not complete. Are you sure you want to end it?")
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsView(match: match)
        }
        .onAppear {
            viewModel.configure(context: modelContext)
            viewModel.currentMatch = match
        }
    }
    
    // MARK: - View Components
    
    private var matchHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label(match.surface.rawValue, systemImage: "sportscourt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(match.format.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    private var scoreBoard: some View {
        VStack(spacing: 12) {
            // Player 1
            playerScoreLine(
                name: match.players.first?.name ?? "Player 1",
                isPlayer1: true,
                isServing: match.currentSet?.currentGame?.serverIsPlayer1 ?? false,
                isWinner: match.winner?.id == match.players.first?.id
            )
            
            Divider()
            
            // Player 2
            playerScoreLine(
                name: match.players.last?.name ?? "Player 2",
                isPlayer1: false,
                isServing: !(match.currentSet?.currentGame?.serverIsPlayer1 ?? true),
                isWinner: match.winner?.id == match.players.last?.id
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func playerScoreLine(name: String, isPlayer1: Bool, isServing: Bool, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            // Name + server indicator
            HStack(spacing: 8) {
                if isServing && !match.isComplete {
                    Image(systemName: "tennis.racket")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                
                Text(name)
                    .font(.headline)
                    .fontWeight(isWinner ? .bold : .regular)
                    .foregroundStyle(isWinner ? .green : .primary)
                
                if isWinner {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Set scores
            HStack(spacing: 12) {
                ForEach(match.sets.indices, id: \.self) { index in
                    let set = match.sets[index]
                    let games = isPlayer1 ? set.gamesPlayer1 : set.gamesPlayer2
                    
                    Text("\(games)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                }
            }
        }
    }
    
    private var currentGameScore: some View {
        VStack(spacing: 8) {
            Text("Current Game")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let game = match.currentSet?.currentGame {
                HStack(spacing: 40) {
                    VStack {
                        Text(game.scoreString(forPlayer1: true))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text(match.players.first?.name ?? "P1")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("-")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    
                    VStack {
                        Text(game.scoreString(forPlayer1: false))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text(match.players.last?.name ?? "P2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var scoringButtons: some View {
        VStack(spacing: 16) {
            Text("Tap to Award Point")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 20) {
                Button {
                    viewModel.awardPoint(toPlayer1: true)
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                        Text(match.players.first?.name ?? "Player 1")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
                }
                
                Button {
                    viewModel.awardPoint(toPlayer1: false)
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                        Text(match.players.last?.name ?? "Player 2")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var statsButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingStatsSheet = true
            } label: {
                Label("View Stats", systemImage: "chart.bar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Quick stat buttons (Ace, Double Fault, etc.)
            HStack(spacing: 12) {
                Menu {
                    Button("Player 1 Ace") {
                        viewModel.recordAce(player1: true)
                        viewModel.awardPoint(toPlayer1: true)
                    }
                    Button("Player 2 Ace") {
                        viewModel.recordAce(player1: false)
                        viewModel.awardPoint(toPlayer1: false)
                    }
                } label: {
                    Label("Ace", systemImage: "bolt.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Menu {
                    Button("Player 1 DF") {
                        viewModel.recordDoubleFault(player1: true)
                        viewModel.awardPoint(toPlayer1: false)
                    }
                    Button("Player 2 DF") {
                        viewModel.recordDoubleFault(player1: false)
                        viewModel.awardPoint(toPlayer1: true)
                    }
                } label: {
                    Label("Double Fault", systemImage: "exclamationmark.2")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Menu {
                    Button("Player 1 Winner") {
                        viewModel.recordWinner(player1: true)
                        viewModel.awardPoint(toPlayer1: true)
                    }
                    Button("Player 2 Winner") {
                        viewModel.recordWinner(player1: false)
                        viewModel.awardPoint(toPlayer1: false)
                    }
                } label: {
                    Label("Winner", systemImage: "star.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var matchCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            if let winner = match.winner {
                Text("\(winner.name) Wins!")
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("Match Complete")
                    .font(.title)
            }
            
            Text("Final Score: \(match.scoreString)")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button {
                showingStatsSheet = true
            } label: {
                Label("View Full Stats", systemImage: "chart.bar.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding(.vertical, 40)
    }
}

// Stats view sheet
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    let match: Match
    
    var body: some View {
        NavigationStack {
            List {
                Section("Match Info") {
                    LabeledContent("Format", value: match.format.rawValue)
                    LabeledContent("Surface", value: match.surface.rawValue)
                    if let location = match.location {
                        LabeledContent("Location", value: location)
                    }
                }
                
                Section("Score") {
                    LabeledContent("Sets", value: match.scoreString)
                }
                
                Section(match.players.first?.name ?? "Player 1") {
                    LabeledContent("Aces", value: "\(match.acesPlayer1)")
                    LabeledContent("Double Faults", value: "\(match.doubleFaultsPlayer1)")
                    LabeledContent("Winners", value: "\(match.winnersPlayer1)")
                    LabeledContent("Unforced Errors", value: "\(match.unforcedErrorsPlayer1)")
                }
                
                Section(match.players.last?.name ?? "Player 2") {
                    LabeledContent("Aces", value: "\(match.acesPlayer2)")
                    LabeledContent("Double Faults", value: "\(match.doubleFaultsPlayer2)")
                    LabeledContent("Winners", value: "\(match.winnersPlayer2)")
                    LabeledContent("Unforced Errors", value: "\(match.unforcedErrorsPlayer2)")
                }
            }
            .navigationTitle("Match Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, configurations: config)
    
    let player1 = Player(name: "Cam")
    let player2 = Player(name: "Opponent")
    let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
    match.startNewSet()
    match.currentSet?.startNewGame(serverIsPlayer1: true)
    
    container.mainContext.insert(match)
    container.mainContext.insert(player1)
    container.mainContext.insert(player2)
    
    return NavigationStack {
        LiveMatchView(match: match)
    }
    .modelContainer(container)
}
