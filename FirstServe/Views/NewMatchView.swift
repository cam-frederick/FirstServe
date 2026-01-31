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
    @State private var location = ""
    
    @State private var viewModel = MatchViewModel()
    @State private var navigateToMatch = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    TextField("Your Name", text: $player1Name)
                        .textContentType(.name)
                    
                    TextField("Opponent Name", text: $player2Name)
                        .textContentType(.name)
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
                }
            }
            .navigationDestination(isPresented: $navigateToMatch) {
                if let match = viewModel.currentMatch {
                    LiveMatchView(match: match)
                }
            }
        }
    }
    
    private var canStartMatch: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func startMatch() {
        viewModel.configure(context: modelContext)
        viewModel.startNewMatch(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            surface: selectedSurface
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
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
}
