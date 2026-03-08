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
    // Stat counters
    let acesPlayer1: Int
    let acesPlayer2: Int
    let doubleFaultsPlayer1: Int
    let doubleFaultsPlayer2: Int
    let winnersPlayer1: Int
    let winnersPlayer2: Int
    let unforcedErrorsPlayer1: Int
    let unforcedErrorsPlayer2: Int
    let firstServeAttemptsPlayer1: Int
    let firstServesMadePlayer1: Int
    let firstServeAttemptsPlayer2: Int
    let firstServesMadePlayer2: Int
    let pointsWonOnFirstServePlayer1: Int
    let pointsWonOnFirstServePlayer2: Int
    let pointsWonOnSecondServePlayer1: Int
    let pointsWonOnSecondServePlayer2: Int
    let secondServeAttemptsPlayer1: Int
    let secondServesMadePlayer1: Int
    let secondServeAttemptsPlayer2: Int
    let secondServesMadePlayer2: Int
    let breakPointsWonPlayer1: Int
    let breakPointsWonPlayer2: Int
    let breakPointsFacedPlayer1: Int
    let breakPointsFacedPlayer2: Int
    let shotStatisticsCount: Int
}

@Observable
final class MatchViewModel {
    var currentMatch: Match?
    private var modelContext: ModelContext?
    
    /// Stack of point snapshots for undo
    private var undoStack: [PointSnapshot] = []
    private var hasPendingSnapshot = false
    
    init() {}
    
    /// Initialize with context
    func configure(context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Player Management

    /// Look up an existing player by name, or create a new one if none exists
    private func fetchOrCreatePlayer(name: String, context: ModelContext) -> Player {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var descriptor = FetchDescriptor<Player>(
            predicate: #Predicate<Player> { $0.name == trimmed }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let player = Player(name: trimmed)
        context.insert(player)
        return player
    }

    // MARK: - Match Management

    /// Start a new match
    func startNewMatch(
        player1Name: String,
        player2Name: String,
        format: MatchFormat,
        surface: CourtSurface,
        scoringMode: ScoringMode = .fullStats,
        scoringStyle: ScoringStyle = .advantage,
        regularTiebreakType: TiebreakType = .regular,
        finalSetTiebreakType: TiebreakType? = nil,
        player1ServesFirst: Bool = true
    ) {
        guard let context = modelContext else { return }

        let player1 = fetchOrCreatePlayer(name: player1Name, context: context)
        let player2 = fetchOrCreatePlayer(name: player2Name, context: context)

        let match = Match(
            player1: player1,
            player2: player2,
            format: format,
            surface: surface,
            scoringMode: scoringMode,
            scoringStyle: scoringStyle,
            regularTiebreakType: regularTiebreakType,
            finalSetTiebreakType: finalSetTiebreakType
        )

        context.insert(match)
        
        // Start first set
        match.startNewSet()
        
        // Start first game (serve based on selection)
        if let firstSet = match.currentSet {
            firstSet.startNewGame(serverIsPlayer1: player1ServesFirst)
        }
        
        currentMatch = match

        try? context.save()

        // Notify Watch of new active match
        let descriptor = FetchDescriptor<Match>()
        if let allMatches = try? context.fetch(descriptor) {
            WatchConnectivityService.shared.sendActiveMatches(allMatches)
        }
    }
    
    /// End the current match
    func endMatch() {
        guard let match = currentMatch else { return }
        match.completedAt = Date()
        match.updatedAt = Date()
        try? modelContext?.save()
        currentMatch = nil

        // Notify Watch that match list changed
        if let context = modelContext {
            let descriptor = FetchDescriptor<Match>()
            if let allMatches = try? context.fetch(descriptor) {
                WatchConnectivityService.shared.sendActiveMatches(allMatches)
            }
        }
    }
    
    // MARK: - Games-Only Scoring

    /// Award an entire game to a player (for games-only mode)
    func awardGame(toPlayer1: Bool) {
        guard let match = currentMatch,
              let set = match.currentSet else { return }

        // Save snapshot for undo
        if let game = set.currentGame ?? set.latestGame {
            let snapshot = createSnapshot(match: match, set: set, game: game)
            undoStack.append(snapshot)
        }

        // Track who was serving so we can alternate
        let lastServerIsPlayer1 = set.currentGame?.serverIsPlayer1 ?? true

        // Mark current game as complete
        if let game = set.currentGame {
            game.completedAt = Date()
        }

        set.awardGame(toPlayer1: toPlayer1, format: match.format)

        if set.isComplete(format: match.format) {
            if !match.isComplete {
                match.startNewSet()
                // Alternate server for new set
                if let newSet = match.currentSet {
                    newSet.startNewGame(serverIsPlayer1: !lastServerIsPlayer1)
                }
            } else {
                match.completedAt = Date()
            }
        } else {
            // Start next game with alternating server
            set.startNewGame(serverIsPlayer1: !lastServerIsPlayer1)
        }

        match.updatedAt = Date()
        try? modelContext?.save()
        WatchConnectivityService.shared.sendMatchUpdate(match, canUndo: canUndo)
    }

    // MARK: - Point Scoring

    /// Call before recording any stats for a point (ace, winner, etc.)
    /// so that undo can revert both the stats and the point.
    func prepareUndo() {
        guard let match = currentMatch,
              let set = match.currentSet,
              let game = set.currentGame else { return }

        let snapshot = createSnapshot(match: match, set: set, game: game)
        undoStack.append(snapshot)
        hasPendingSnapshot = true
    }

    private func createSnapshot(match: Match, set: TennisSet, game: Game) -> PointSnapshot {
        PointSnapshot(
            pointsPlayer1: game.pointsPlayer1,
            pointsPlayer2: game.pointsPlayer2,
            gamesPlayer1: set.gamesPlayer1,
            gamesPlayer2: set.gamesPlayer2,
            gameCount: set.games.count,
            setCount: match.sets.count,
            serverIsPlayer1: game.serverIsPlayer1,
            matchComplete: match.isComplete,
            tiebreakPointsPlayer1: set.tiebreakScorePlayer1,
            tiebreakPointsPlayer2: set.tiebreakScorePlayer2,
            acesPlayer1: match.acesPlayer1,
            acesPlayer2: match.acesPlayer2,
            doubleFaultsPlayer1: match.doubleFaultsPlayer1,
            doubleFaultsPlayer2: match.doubleFaultsPlayer2,
            winnersPlayer1: match.winnersPlayer1,
            winnersPlayer2: match.winnersPlayer2,
            unforcedErrorsPlayer1: match.unforcedErrorsPlayer1,
            unforcedErrorsPlayer2: match.unforcedErrorsPlayer2,
            firstServeAttemptsPlayer1: match.firstServeAttemptsPlayer1,
            firstServesMadePlayer1: match.firstServesMadePlayer1,
            firstServeAttemptsPlayer2: match.firstServeAttemptsPlayer2,
            firstServesMadePlayer2: match.firstServesMadePlayer2,
            pointsWonOnFirstServePlayer1: match.pointsWonOnFirstServePlayer1,
            pointsWonOnFirstServePlayer2: match.pointsWonOnFirstServePlayer2,
            pointsWonOnSecondServePlayer1: match.pointsWonOnSecondServePlayer1,
            pointsWonOnSecondServePlayer2: match.pointsWonOnSecondServePlayer2,
            secondServeAttemptsPlayer1: match.secondServeAttemptsPlayer1,
            secondServesMadePlayer1: match.secondServesMadePlayer1,
            secondServeAttemptsPlayer2: match.secondServeAttemptsPlayer2,
            secondServesMadePlayer2: match.secondServesMadePlayer2,
            breakPointsWonPlayer1: match.breakPointsWonPlayer1,
            breakPointsWonPlayer2: match.breakPointsWonPlayer2,
            breakPointsFacedPlayer1: match.breakPointsFacedPlayer1,
            breakPointsFacedPlayer2: match.breakPointsFacedPlayer2,
            shotStatisticsCount: match.shotStatistics.count
        )
    }

    /// Award a point to a player
    func awardPoint(toPlayer1: Bool) {
        guard let match = currentMatch,
              let set = match.currentSet,
              let game = set.currentGame else { return }

        // Only create snapshot if prepareUndo() wasn't already called
        if !hasPendingSnapshot {
            let snapshot = createSnapshot(match: match, set: set, game: game)
            undoStack.append(snapshot)
        }
        hasPendingSnapshot = false
        
        // Check if we're in a tiebreak
        if set.isTiebreak(format: match.format) {
            awardTiebreakPoint(toPlayer1: toPlayer1, match: match, set: set, game: game)
        } else {
            awardRegularPoint(toPlayer1: toPlayer1, match: match, set: set, game: game)
        }
        
        match.updatedAt = Date()
        try? modelContext?.save()
        WatchConnectivityService.shared.sendMatchUpdate(match, canUndo: canUndo)
    }

    /// Award point during regular game
    private func awardRegularPoint(toPlayer1: Bool, match: Match, set: TennisSet, game: Game) {
        // Check for break point before awarding (returner is one point from winning)
        let isBreakPoint = isBreakPointSituation(game: game, scoringStyle: match.scoringStyle)

        game.awardPoint(toPlayer1: toPlayer1, scoringStyle: match.scoringStyle)

        // Track break points
        if isBreakPoint {
            let returnerIsPlayer1 = !game.serverIsPlayer1
            // Break point faced by the server
            if game.serverIsPlayer1 {
                match.breakPointsFacedPlayer1 += 1
            } else {
                match.breakPointsFacedPlayer2 += 1
            }
            // Break point converted if returner won the point
            if toPlayer1 == returnerIsPlayer1 {
                if returnerIsPlayer1 {
                    match.breakPointsWonPlayer1 += 1
                } else {
                    match.breakPointsWonPlayer2 += 1
                }
            }
        }
        
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
                // We just reached 6-6 (or 8-8 for super set), start tiebreak
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

        // If sets were added, remove the most recently created ones
        while match.sets.count > snapshot.setCount {
            if let newest = match.sets.max(by: { $0.setNumber < $1.setNumber }) {
                match.sets.removeAll { $0.id == newest.id }
            } else {
                break
            }
        }

        guard let set = match.sortedSets.last else { return }

        // If games were added, remove the most recently created ones
        while set.games.count > snapshot.gameCount {
            if let newest = set.games.max(by: { $0.gameNumber < $1.gameNumber }) {
                set.games.removeAll { $0.id == newest.id }
            } else {
                break
            }
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

        // Restore stat counters
        match.acesPlayer1 = snapshot.acesPlayer1
        match.acesPlayer2 = snapshot.acesPlayer2
        match.doubleFaultsPlayer1 = snapshot.doubleFaultsPlayer1
        match.doubleFaultsPlayer2 = snapshot.doubleFaultsPlayer2
        match.winnersPlayer1 = snapshot.winnersPlayer1
        match.winnersPlayer2 = snapshot.winnersPlayer2
        match.unforcedErrorsPlayer1 = snapshot.unforcedErrorsPlayer1
        match.unforcedErrorsPlayer2 = snapshot.unforcedErrorsPlayer2
        match.firstServeAttemptsPlayer1 = snapshot.firstServeAttemptsPlayer1
        match.firstServesMadePlayer1 = snapshot.firstServesMadePlayer1
        match.firstServeAttemptsPlayer2 = snapshot.firstServeAttemptsPlayer2
        match.firstServesMadePlayer2 = snapshot.firstServesMadePlayer2
        match.pointsWonOnFirstServePlayer1 = snapshot.pointsWonOnFirstServePlayer1
        match.pointsWonOnFirstServePlayer2 = snapshot.pointsWonOnFirstServePlayer2
        match.pointsWonOnSecondServePlayer1 = snapshot.pointsWonOnSecondServePlayer1
        match.pointsWonOnSecondServePlayer2 = snapshot.pointsWonOnSecondServePlayer2
        match.secondServeAttemptsPlayer1 = snapshot.secondServeAttemptsPlayer1
        match.secondServesMadePlayer1 = snapshot.secondServesMadePlayer1
        match.secondServeAttemptsPlayer2 = snapshot.secondServeAttemptsPlayer2
        match.secondServesMadePlayer2 = snapshot.secondServesMadePlayer2
        match.breakPointsWonPlayer1 = snapshot.breakPointsWonPlayer1
        match.breakPointsWonPlayer2 = snapshot.breakPointsWonPlayer2
        match.breakPointsFacedPlayer1 = snapshot.breakPointsFacedPlayer1
        match.breakPointsFacedPlayer2 = snapshot.breakPointsFacedPlayer2

        // Remove any shot statistics added since the snapshot
        while match.shotStatistics.count > snapshot.shotStatisticsCount {
            match.shotStatistics.removeLast()
        }

        match.updatedAt = Date()
        try? modelContext?.save()
        WatchConnectivityService.shared.sendMatchUpdate(match, canUndo: canUndo)
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
    
    func recordForcedError(player1: Bool, shotType: ShotType? = nil, contactType: ContactType? = nil) {
        guard let match = currentMatch else { return }

        if let shotType = shotType, let contactType = contactType {
            match.recordShotStatistic(
                playerNumber: player1 ? 1 : 2,
                statType: .forcedError,
                shotType: shotType,
                contactType: contactType
            )
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
    
    // MARK: - Break Point Detection

    /// Returns true if the returner is one point away from winning the game
    private func isBreakPointSituation(game: Game, scoringStyle: ScoringStyle) -> Bool {
        let serverPoints = game.serverIsPlayer1 ? game.pointsPlayer1 : game.pointsPlayer2
        let returnerPoints = game.serverIsPlayer1 ? game.pointsPlayer2 : game.pointsPlayer1

        // Returner at 40 (3+ points) and server not at 40 yet
        if returnerPoints >= 3 && serverPoints < 3 {
            return true
        }

        // Deuce situations
        if returnerPoints >= 3 && serverPoints >= 3 {
            if scoringStyle == .noAdvantage {
                // No-ad: deuce is always a break point (sudden death, returner can win)
                return returnerPoints == serverPoints
            } else {
                // Advantage: break point if returner has advantage
                return returnerPoints > serverPoints
            }
        }

        return false
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
