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
    let tiebreakPointsPlayer1: Int?
    let tiebreakPointsPlayer2: Int?
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
    func startNewMatch(
        player1Name: String,
        player2Name: String,
        format: MatchFormat,
        surface: CourtSurface,
        scoringStyle: ScoringStyle = .advantage,
        regularTiebreakType: TiebreakType = .regular,
        finalSetTiebreakType: TiebreakType? = nil,
        player1ServesFirst: Bool = true
    ) {
        guard let context = modelContext else { return }
        
        let player1 = Player(name: player1Name)
        let player2 = Player(name: player2Name)
        
        let match = Match(
            player1: player1,
            player2: player2,
            format: format,
            surface: surface,
            scoringStyle: scoringStyle,
            regularTiebreakType: regularTiebreakType,
            finalSetTiebreakType: finalSetTiebreakType
        )
        
        context.insert(match)
        context.insert(player1)
        context.insert(player2)
        
        // Start first set
        match.startNewSet()
        
        // Start first game (serve based on selection)
        if let firstSet = match.currentSet {
            firstSet.startNewGame(serverIsPlayer1: player1ServesFirst)
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
            matchComplete: match.isComplete,
            tiebreakPointsPlayer1: set.tiebreakScorePlayer1,
            tiebreakPointsPlayer2: set.tiebreakScorePlayer2
        )
        undoStack.append(snapshot)
        
        // Check if we're in a tiebreak
        if set.isTiebreak(format: match.format) {
            awardTiebreakPoint(toPlayer1: toPlayer1, match: match, set: set, game: game)
        } else {
            awardRegularPoint(toPlayer1: toPlayer1, match: match, set: set, game: game)
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    /// Award point during regular game
    private func awardRegularPoint(toPlayer1: Bool, match: Match, set: TennisSet, game: Game) {
        game.awardPoint(toPlayer1: toPlayer1, scoringStyle: match.scoringStyle)
        
        // If game is complete, award the game
        if game.isComplete(scoringStyle: match.scoringStyle) {
            set.awardGame(toPlayer1: game.winner == 1, format: match.format)
            
            // If set is complete, start new set (if match continues)
            if set.isComplete(format: match.format) {
                if !match.isComplete {
                    match.startNewSet()
                    
                    // Determine who serves first in new set
                    let totalGames = set.games.count
                    let player1ServesFirst = totalGames % 2 == 0
                    
                    if let newSet = match.currentSet {
                        newSet.startNewGame(serverIsPlayer1: player1ServesFirst)
                    }
                } else {
                    // Match completed naturally — stamp completedAt
                    match.completedAt = Date()
                }
            } else if set.isTiebreak(format: match.format) {
                // We just reached 6-6 (or 10-10 for super set), start tiebreak
                // Determine which tiebreak type to use
                let isFinalSet = match.sets.count == (match.format == .bestOf5 ? 5 : 3)
                let tiebreakType = (isFinalSet && match.finalSetTiebreakType != nil) ? match.finalSetTiebreakType! : match.regularTiebreakType
                
                set.startTiebreak()
                // The player who would serve next in rotation serves first in tiebreak
                let nextServerIsPlayer1 = !game.serverIsPlayer1
                set.startNewGame(serverIsPlayer1: nextServerIsPlayer1)
            } else {
                // Start next game (alternate server)
                let nextServerIsPlayer1 = !game.serverIsPlayer1
                set.startNewGame(serverIsPlayer1: nextServerIsPlayer1)
            }
        }
    }
    
    /// Award point during tiebreak
    private func awardTiebreakPoint(toPlayer1: Bool, match: Match, set: TennisSet, game: Game) {
        // Determine which tiebreak type we're using
        let isFinalSet = match.sets.count == (match.format == .bestOf5 ? 5 : 3)
        let tiebreakType = (isFinalSet && match.finalSetTiebreakType != nil) ? match.finalSetTiebreakType! : match.regularTiebreakType
        
        // Use the set's method to award tiebreak point
        set.awardTiebreakPoint(toPlayer1: toPlayer1, tiebreakType: tiebreakType)
        
        let p1Score = set.tiebreakScorePlayer1 ?? 0
        let p2Score = set.tiebreakScorePlayer2 ?? 0
        let totalPoints = p1Score + p2Score
        
        // Check if tiebreak is won (set already handles this and awards the game)
        let tiebreakWon = set.isTiebreakComplete(tiebreakType: tiebreakType)
        
        if tiebreakWon {
            // Start new set if match continues
            if !match.isComplete {
                match.startNewSet()
                
                // The player who served first in the tiebreak serves first in the new set
                // (opposite of whoever served the last point before tiebreak)
                if let newSet = match.currentSet {
                    let tiebreakFirstServer = game.serverIsPlayer1
                    newSet.startNewGame(serverIsPlayer1: !tiebreakFirstServer)
                }
            } else {
                // Match completed via tiebreak — stamp completedAt
                match.completedAt = Date()
            }
        } else {
            // Handle serve rotation in tiebreak
            // First point: Player A serves
            // Points 2-3: Player B serves
            // Points 4-5: Player A serves
            // etc. (alternate every 2 points after first)
            
            if totalPoints == 1 {
                // After first point, switch server
                game.serverIsPlayer1 = !game.serverIsPlayer1
            } else if totalPoints > 1 && (totalPoints - 1) % 2 == 0 {
                // After every 2 points (starting from point 2), switch server
                game.serverIsPlayer1 = !game.serverIsPlayer1
            }
            
            // Also switch ends every 6 points (optional, UI can handle this)
        }
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
        
        // Restore tiebreak scores
        set.tiebreakScorePlayer1 = snapshot.tiebreakPointsPlayer1
        set.tiebreakScorePlayer2 = snapshot.tiebreakPointsPlayer2
        
        // Restore game point counts
        if let game = set.games.last {
            game.pointsPlayer1 = snapshot.pointsPlayer1
            game.pointsPlayer2 = snapshot.pointsPlayer2
            game.serverIsPlayer1 = snapshot.serverIsPlayer1
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
    
    func recordWinner(player1: Bool, shotType: ShotType? = nil, contactType: ContactType? = nil) {
        guard let match = currentMatch else { return }
        
        // If shot details provided, use detailed tracking
        if let shotType = shotType, let contactType = contactType {
            match.recordShotStatistic(
                playerNumber: player1 ? 1 : 2,
                statType: .winner,
                shotType: shotType,
                contactType: contactType
            )
        } else {
            // Fallback to basic tracking
            if player1 {
                match.winnersPlayer1 += 1
            } else {
                match.winnersPlayer2 += 1
            }
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func recordUnforcedError(player1: Bool, shotType: ShotType? = nil, contactType: ContactType? = nil) {
        guard let match = currentMatch else { return }
        
        // If shot details provided, use detailed tracking
        if let shotType = shotType, let contactType = contactType {
            match.recordShotStatistic(
                playerNumber: player1 ? 1 : 2,
                statType: .unforcedError,
                shotType: shotType,
                contactType: contactType
            )
        } else {
            // Fallback to basic tracking
            if player1 {
                match.unforcedErrorsPlayer1 += 1
            } else {
                match.unforcedErrorsPlayer2 += 1
            }
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
    }
    
    /// Record a serve
    func recordServe(player1: Bool, firstServe: Bool, made: Bool, pointWon: Bool? = nil) {
        guard let match = currentMatch else { return }
        match.recordServe(forPlayer1: player1, firstServe: firstServe, made: made, pointWon: pointWon)
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
    
    /// Is the current set in a tiebreak?
    var isInTiebreak: Bool {
        guard let match = currentMatch, let set = match.currentSet else { return false }
        return set.isTiebreak(format: match.format)
    }
    
    /// Tiebreak score for player 1 (nil if not in tiebreak)
    var tiebreakScorePlayer1: Int? {
        currentMatch?.currentSet?.tiebreakScorePlayer1
    }
    
    /// Tiebreak score for player 2 (nil if not in tiebreak)
    var tiebreakScorePlayer2: Int? {
        currentMatch?.currentSet?.tiebreakScorePlayer2
    }
    
    // MARK: - Serve Statistics Helpers
    
    var firstServePercentagePlayer1: Double {
        currentMatch?.firstServePercentagePlayer1 ?? 0.0
    }
    
    var firstServePercentagePlayer2: Double {
        currentMatch?.firstServePercentagePlayer2 ?? 0.0
    }
    
    var firstServePointsWonPercentagePlayer1: Double {
        currentMatch?.firstServePointsWonPercentagePlayer1 ?? 0.0
    }
    
    var firstServePointsWonPercentagePlayer2: Double {
        currentMatch?.firstServePointsWonPercentagePlayer2 ?? 0.0
    }
}
