//
//  TennisSet.swift
//  MatchPoint
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
    var isComplete: Bool {
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
    
    /// Is a tiebreak in progress?
    var isTiebreak: Bool {
        gamesPlayer1 == 6 && gamesPlayer2 == 6
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
    /// Current game (the last incomplete game, or nil)
    var currentGame: Game? {
        games.last(where: { !$0.isComplete })
    }
    
    /// Start a new game
    func startNewGame(serverIsPlayer1: Bool) {
        let newGame = Game(gameNumber: games.count + 1, serverIsPlayer1: serverIsPlayer1)
        games.append(newGame)
    }
    
    /// Award game to a player
    func awardGame(toPlayer1: Bool) {
        if toPlayer1 {
            gamesPlayer1 += 1
        } else {
            gamesPlayer2 += 1
        }
        
        // Check if set is complete
        if isComplete {
            completedAt = Date()
        }
    }
}
