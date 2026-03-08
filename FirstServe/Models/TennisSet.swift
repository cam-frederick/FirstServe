//
//  TennisSet.swift
//  FirstServe
//
//  Created by Cici on 1/29/26.
//

import Foundation
import SwiftData

/// Represents a set in a tennis match
@Model
final class TennisSet {
    var id: UUID
    var setNumber: Int
    var createdAt: Date
    var completedAt: Date?
    
    /// Games won by each player
    var gamesPlayer1: Int
    var gamesPlayer2: Int
    
    /// Tiebreak score (if applicable)
    var tiebreakScorePlayer1: Int?
    var tiebreakScorePlayer2: Int?
    
    /// Games in this set
    @Relationship(deleteRule: .cascade)
    var games: [Game]
    
    /// Is the set complete?
    func isComplete(format: MatchFormat? = nil) -> Bool {
        // Super set: first to 8 games, win by 2
        if let format = format, format == .superSet {
            if gamesPlayer1 >= 8 && gamesPlayer1 - gamesPlayer2 >= 2 {
                return true
            }
            if gamesPlayer2 >= 8 && gamesPlayer2 - gamesPlayer1 >= 2 {
                return true
            }
            // Super set tiebreak at 8-8
            if gamesPlayer1 == 9 || gamesPlayer2 == 9 {
                return true
            }
            return false
        }
        
        // Standard: first to 6 games with 2-game lead
        if gamesPlayer1 >= 6 && gamesPlayer1 - gamesPlayer2 >= 2 {
            return true
        }
        if gamesPlayer2 >= 6 && gamesPlayer2 - gamesPlayer1 >= 2 {
            return true
        }
        
        // Tiebreak at 6-6
        if gamesPlayer1 == 7 || gamesPlayer2 == 7 {
            return true
        }
        
        return false
    }
    
    /// Backward-compatible isComplete
    var isComplete: Bool {
        isComplete(format: nil)
    }
    
    /// Backward-compatible isTiebreak (standard 6-6 check, no super set awareness)
    var isTiebreak: Bool {
        isTiebreak(format: nil)
    }
    
    /// Is a tiebreak in progress?
    func isTiebreak(format: MatchFormat? = nil) -> Bool {
        if let format = format, format == .superSet {
            return gamesPlayer1 == 8 && gamesPlayer2 == 8
        }
        return gamesPlayer1 == 6 && gamesPlayer2 == 6
    }
    
    /// Check if tiebreak is complete
    func isTiebreakComplete(tiebreakType: TiebreakType) -> Bool {
        guard let p1Score = tiebreakScorePlayer1, let p2Score = tiebreakScorePlayer2 else {
            return false
        }
        
        let pointsToWin = tiebreakType.pointsToWin
        
        // Must reach required points and win by 2
        if p1Score >= pointsToWin && p1Score - p2Score >= 2 {
            return true
        }
        if p2Score >= pointsToWin && p2Score - p1Score >= 2 {
            return true
        }
        
        return false
    }
    
    init(setNumber: Int) {
        self.id = UUID()
        self.setNumber = setNumber
        self.createdAt = Date()
        self.gamesPlayer1 = 0
        self.gamesPlayer2 = 0
        self.games = []
    }
}

extension TennisSet {
    /// Games sorted by creation order (SwiftData relationships are unordered)
    var sortedGames: [Game] {
        games.sorted { $0.gameNumber < $1.gameNumber }
    }

    /// Current game (the last incomplete game, or nil)
    var currentGame: Game? {
        sortedGames.last(where: { !$0.isComplete })
    }

    /// Most recently created game (regardless of completion state)
    var latestGame: Game? {
        sortedGames.last
    }
    
    /// Start a new game
    func startNewGame(serverIsPlayer1: Bool) {
        let newGame = Game(gameNumber: games.count + 1, serverIsPlayer1: serverIsPlayer1)
        games.append(newGame)
    }
    
    /// Award game to a player
    func awardGame(toPlayer1: Bool, format: MatchFormat? = nil) {
        if toPlayer1 {
            gamesPlayer1 += 1
        } else {
            gamesPlayer2 += 1
        }
        
        // Check if set is complete
        if isComplete(format: format) {
            completedAt = Date()
        }
    }
    
    /// Start a tiebreak
    func startTiebreak() {
        tiebreakScorePlayer1 = 0
        tiebreakScorePlayer2 = 0
    }
    
    /// Award tiebreak point
    func awardTiebreakPoint(toPlayer1: Bool, tiebreakType: TiebreakType) {
        if toPlayer1 {
            tiebreakScorePlayer1 = (tiebreakScorePlayer1 ?? 0) + 1
        } else {
            tiebreakScorePlayer2 = (tiebreakScorePlayer2 ?? 0) + 1
        }
        
        // Check if tiebreak is complete
        if isTiebreakComplete(tiebreakType: tiebreakType) {
            // Award the game to the tiebreak winner
            if (tiebreakScorePlayer1 ?? 0) > (tiebreakScorePlayer2 ?? 0) {
                gamesPlayer1 += 1
            } else {
                gamesPlayer2 += 1
            }
            completedAt = Date()
        }
    }
}
