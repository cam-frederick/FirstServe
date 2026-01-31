//
//  MatchViewModel.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import Foundation
import SwiftData

/// Snapshot of a single point for undo support
private struct PointSnapshot {
    let pointsPlayer1: Int
    let pointsPlayer2: Int
    let gamesPlayer1: Int
    let gamesPlayer2: Int
    let gameCount: Int
    let setCount: Int
    let serverIsPlayer1: Bool
    let matchComplete: Bool
}

@Observable
final class MatchViewModel {
    var currentMatch: Match?
    private var modelContext: ModelContext?
    
    /// Stack of point snapshots for undo
    private var undoStack: [PointSnapshot] = []
    
    init() {}
    
    /// Initialize with context
    func configure(context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Match Management
    
    /// Start a new match
    func startNewMatch(player1Name: String, player2Name: String, format: MatchFormat, surface: CourtSurface) {
        guard let context = modelContext else { return }
        
        let player1 = Player(name: player1Name)
        let player2 = Player(name: player2Name)
        
        let match = Match(player1: player1, player2: player2, format: format, surface: surface)
        
        context.insert(match)
        context.insert(player1)
        context.insert(player2)
        
        // Start first set
        match.startNewSet()
        
        // Start first game (player 1 serves)
        if let firstSet = match.currentSet {
            firstSet.startNewGame(serverIsPlayer1: true)
        }
        
        currentMatch = match
        
        try? context.save()
    }
    
    /// End the current match
    func endMatch() {
        guard let match = currentMatch else { return }
        match.completedAt = Date()
        match.updatedAt = Date()
        try? modelContext?.save()
        currentMatch = nil
    }
    
    // MARK: - Scoring
    
    /// Award a point to a player
    func awardPoint(toPlayer1: Bool) {
        guard let match = currentMatch,
              let set = match.currentSet,
              let game = set.currentGame else { return }
        
        // Snapshot current state before awarding point (for undo)
        let snapshot = PointSnapshot(
            pointsPlayer1: game.pointsPlayer1,
            pointsPlayer2: game.pointsPlayer2,
            gamesPlayer1: set.gamesPlayer1,
            gamesPlayer2: set.gamesPlayer2,
            gameCount: set.games.count,
            setCount: match.sets.count,
            serverIsPlayer1: game.serverIsPlayer1,
            matchComplete: match.isComplete
        )
        undoStack.append(snapshot)
        
        game.awardPoint(toPlayer1: toPlayer1)
        
        // If game is complete, award the game
        if game.isComplete {
            set.awardGame(toPlayer1: game.winner == 1)
            
            // If set is complete, start new set (if match continues)
            if set.isComplete {
                if !match.isComplete {
                    match.startNewSet()
                    
                    // Determine who serves first in new set
                    let totalGames = set.games.count
                    let player1ServesFirst = totalGames % 2 == 0
                    
                    if let newSet = match.currentSet {
                        newSet.startNewGame(serverIsPlayer1: player1ServesFirst)
                    }
                }
            } else {
                // Start next game (alternate server)
                let nextServerIsPlayer1 = !game.serverIsPlayer1
                set.startNewGame(serverIsPlayer1: nextServerIsPlayer1)
            }
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    /// Whether undo is available
    var canUndo: Bool {
        !undoStack.isEmpty && !(currentMatch?.isComplete ?? true)
    }
    
    /// Undo the last awarded point
    func undoLastPoint() {
        guard let match = currentMatch,
              let snapshot = undoStack.last else { return }
        
        undoStack.removeLast()
        
        // If sets were added, remove them back to snapshot state
        while match.sets.count > snapshot.setCount {
            match.sets.removeLast()
        }
        
        guard let set = match.sets.last else { return }
        
        // If games were added, remove them back to snapshot state
        while set.games.count > snapshot.gameCount {
            set.games.removeLast()
        }
        
        // Restore set game counts
        set.gamesPlayer1 = snapshot.gamesPlayer1
        set.gamesPlayer2 = snapshot.gamesPlayer2
        set.completedAt = nil  // Un-complete the set if it was completed
        
        // Restore game point counts
        if let game = set.games.last {
            game.pointsPlayer1 = snapshot.pointsPlayer1
            game.pointsPlayer2 = snapshot.pointsPlayer2
            game.completedAt = nil  // Un-complete the game if it was completed
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    // MARK: - Stats
    
    func recordAce(player1: Bool) {
        guard let match = currentMatch else { return }
        if player1 {
            match.acesPlayer1 += 1
        } else {
            match.acesPlayer2 += 1
        }
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func recordDoubleFault(player1: Bool) {
        guard let match = currentMatch else { return }
        if player1 {
            match.doubleFaultsPlayer1 += 1
        } else {
            match.doubleFaultsPlayer2 += 1
        }
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func recordWinner(player1: Bool) {
        guard let match = currentMatch else { return }
        if player1 {
            match.winnersPlayer1 += 1
        } else {
            match.winnersPlayer2 += 1
        }
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func recordUnforcedError(player1: Bool) {
        guard let match = currentMatch else { return }
        if player1 {
            match.unforcedErrorsPlayer1 += 1
        } else {
            match.unforcedErrorsPlayer2 += 1
        }
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    // MARK: - Helpers
    
    var player1Name: String {
        currentMatch?.players.first?.name ?? "Player 1"
    }
    
    var player2Name: String {
        currentMatch?.players.last?.name ?? "Player 2"
    }
    
    var currentSetNumber: Int {
        currentMatch?.sets.count ?? 0
    }
    
    var matchIsComplete: Bool {
        currentMatch?.isComplete ?? false
    }
}
