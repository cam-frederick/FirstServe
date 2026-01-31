//
//  Match.swift
//  FirstServe
//
//  Created by Cici on 1/29/26.
//

import Foundation
import SwiftData

/// Court surface type
enum CourtSurface: String, Codable, CaseIterable {
    case hardCourt = "Hard Court"
    case clay = "Clay"
    case grass = "Grass"
    case carpet = "Carpet"
}

/// Match format (best of 3 or 5 sets)
enum MatchFormat: String, Codable, CaseIterable {
    case bestOf3 = "Best of 3"
    case bestOf5 = "Best of 5"
}

/// Represents a tennis match
@Model
final class Match {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    /// Match configuration
    var format: MatchFormat
    var surface: CourtSurface
    var location: String?
    var notes: String?
    
    /// Players (should be exactly 2)
    @Relationship(deleteRule: .cascade)
    var players: [Player]
    
    /// Sets in this match
    @Relationship(deleteRule: .cascade)
    var sets: [TennisSet]
    
    /// Stats tracking
    var acesPlayer1: Int
    var acesPlayer2: Int
    var doubleFaultsPlayer1: Int
    var doubleFaultsPlayer2: Int
    var winnersPlayer1: Int
    var winnersPlayer2: Int
    var unforcedErrorsPlayer1: Int
    var unforcedErrorsPlayer2: Int
    
    /// Computed: Winner of the match (nil if incomplete)
    var winner: Player? {
        guard isComplete else { return nil }
        let setsWon = setsWonByPlayer
        let player1Wins = setsWon[0]
        let player2Wins = setsWon[1]
        
        if player1Wins > player2Wins {
            return players.first
        } else if player2Wins > player1Wins {
            return players.last
        }
        return nil
    }
    
    /// Is the match complete?
    var isComplete: Bool {
        let requiredSets = format == .bestOf3 ? 2 : 3
        let setsWon = setsWonByPlayer
        return setsWon.contains(where: { $0 >= requiredSets })
    }
    
    /// Helper: count sets won by each player
    private var setsWonByPlayer: [Int] {
        var p1Wins = 0
        var p2Wins = 0
        
        for set in sets where set.isComplete {
            if set.gamesPlayer1 > set.gamesPlayer2 {
                p1Wins += 1
            } else {
                p2Wins += 1
            }
        }
        
        return [p1Wins, p2Wins]
    }
    
    init(player1: Player, player2: Player, format: MatchFormat, surface: CourtSurface) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.format = format
        self.surface = surface
        self.players = [player1, player2]
        self.sets = []
        
        self.acesPlayer1 = 0
        self.acesPlayer2 = 0
        self.doubleFaultsPlayer1 = 0
        self.doubleFaultsPlayer2 = 0
        self.winnersPlayer1 = 0
        self.winnersPlayer2 = 0
        self.unforcedErrorsPlayer1 = 0
        self.unforcedErrorsPlayer2 = 0
    }
}

extension Match {
    /// Current set (the last incomplete set, or nil)
    var currentSet: TennisSet? {
        sets.last(where: { !$0.isComplete })
    }
    
    /// Score summary string (e.g., "6-4, 3-6, 7-5")
    var scoreString: String {
        sets.map { "\($0.gamesPlayer1)-\($0.gamesPlayer2)" }.joined(separator: ", ")
    }
    
    /// Start a new set
    func startNewSet() {
        let newSet = TennisSet(setNumber: sets.count + 1)
        sets.append(newSet)
        updatedAt = Date()
    }
}
