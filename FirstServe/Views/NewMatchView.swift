//
//  NewMatchView.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData

struct NewMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var player1Name = ""
    @State private var player2Name = ""
    @State private var selectedSurface: CourtSurface = .hardCourt
    @State private var selectedFormat: MatchFormat = .bestOf3
    @State private var selectedScoringStyle: ScoringStyle = .advantage
    @State private var selectedRegularTiebreakType: TiebreakType = .regular
    @State private var useFinalSetTiebreak = false
    @State private var selectedFinalSetTiebreakType: TiebreakType = .matchTiebreak
    @State private var location = ""
    @State private var player1ServesFirst = true
    
    @State private var viewModel = MatchViewModel()
    @State private var navigateToMatch = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    TextField("Your Name", text: $player1Name)
                        .textContentType(.name)
                        .accessibilityIdentifier("player1NameField")
                    
                    TextField("Opponent Name", text: $player2Name)
                        .textContentType(.name)
                        .accessibilityIdentifier("player2NameField")
                }
                
                if bothPlayersEntered {
                    Section("First Serve") {
                        Picker("Who serves first?", selection: $player1ServesFirst) {
                            Text(player1Name.trimmingCharacters(in: .whitespaces))
                                .tag(true)
                            Text(player2Name.trimmingCharacters(in: .whitespaces))
                                .tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section("Match Details") {
                    Picker("Surface", selection: $selectedSurface) {
                        ForEach(CourtSurface.allCases, id: \.self) { surface in
                            Text(surface.rawValue).tag(surface)
                        }
                    }
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(MatchFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    
                    TextField("Location (optional)", text: $location)
                        .textContentType(.location)
                }
                
                Section("Scoring Rules") {
                    Picker("Deuce Scoring", selection: $selectedScoringStyle) {
                        ForEach(ScoringStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    
                    Picker("Regular Tiebreak", selection: $selectedRegularTiebreakType) {
                        Text("7 Points").tag(TiebreakType.regular)
                        Text("10 Points").tag(TiebreakType.extended)
                    }
                    
                    if selectedFormat == .bestOf3 || selectedFormat == .bestOf5 {
                        Toggle("Use Match Tiebreak for Final Set", isOn: $useFinalSetTiebreak)
                        
                        if useFinalSetTiebreak {
                            Text("First to 10 points, win by 2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startMatch()
                    }
                    .disabled(!canStartMatch)
                    .accessibilityIdentifier("startMatchButton")
                }
            }
            .navigationDestination(isPresented: $navigateToMatch) {
                if let match = viewModel.currentMatch {
                    LiveMatchView(match: match)
                }
            }
        }
    }
    
    private var bothPlayersEntered: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var canStartMatch: Bool {
        bothPlayersEntered
    }
    
    private func startMatch() {
        viewModel.configure(context: modelContext)
        viewModel.startNewMatch(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            surface: selectedSurface,
            scoringStyle: selectedScoringStyle,
            regularTiebreakType: selectedRegularTiebreakType,
            finalSetTiebreakType: useFinalSetTiebreak ? selectedFinalSetTiebreakType : nil,
            player1ServesFirst: player1ServesFirst
        )
        
        // Set location if provided
        if !location.isEmpty {
            viewModel.currentMatch?.location = location.trimmingCharacters(in: .whitespaces)
            try? modelContext.save()
        }
        
        navigateToMatch = true
        dismiss()
    }
}

#Preview {
    NewMatchView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self])
}
