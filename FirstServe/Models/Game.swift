//
//  Game.swift
//  FirstServe
//
//  Created by Cici on 1/29/26.
//

import Foundation
import SwiftData

/// Tennis scoring within a game
enum GameScore: String, Codable {
    case love = "0"
    case fifteen = "15"
    case thirty = "30"
    case forty = "40"
    case advantage = "AD"
    case game = "Game"
}

/// Represents a game in a tennis set
@Model
final class Game {
    var id: UUID
    var gameNumber: Int
    var createdAt: Date
    var completedAt: Date?
    
    /// Server (true = player1, false = player2)
    var serverIsPlayer1: Bool
    
    /// Current score
    var pointsPlayer1: Int
    var pointsPlayer2: Int
    
    /// Is the game complete? (requires scoring style for no-ad logic)
    func isComplete(scoringStyle: ScoringStyle) -> Bool {
        // Must have at least 4 points
        guard pointsPlayer1 >= 4 || pointsPlayer2 >= 4 else {
            return false
        }
        
        // No-ad: sudden death at deuce (3-3)
        if scoringStyle == .noAdvantage && pointsPlayer1 >= 3 && pointsPlayer2 >= 3 {
            return pointsPlayer1 != pointsPlayer2
        }
        
        // Advantage: must win by 2 points after deuce
        let diff = abs(pointsPlayer1 - pointsPlayer2)
        return diff >= 2
    }
    
    /// Backward-compatible isComplete (defaults to advantage scoring)
    var isComplete: Bool {
        isComplete(scoringStyle: .advantage)
    }
    
    /// Winner of the game (nil if incomplete)
    var winner: Int? {
        guard isComplete else { return nil }
        return pointsPlayer1 > pointsPlayer2 ? 1 : 2
    }
    
    init(gameNumber: Int, serverIsPlayer1: Bool) {
        self.id = UUID()
        self.gameNumber = gameNumber
        self.createdAt = Date()
        self.serverIsPlayer1 = serverIsPlayer1
        self.pointsPlayer1 = 0
        self.pointsPlayer2 = 0
    }
}

extension Game {
    /// Score for a player as a string
    func scoreString(forPlayer1: Bool, scoringStyle: ScoringStyle = .advantage) -> String {
        let points = forPlayer1 ? pointsPlayer1 : pointsPlayer2
        let opponentPoints = forPlayer1 ? pointsPlayer2 : pointsPlayer1
        
        // Handle deuce and advantage
        if points >= 3 && opponentPoints >= 3 {
            if points == opponentPoints {
                // In no-ad, deuce is the deciding point
                return scoringStyle == .noAdvantage ? "DEUCE" : "40"
            } else if points > opponentPoints {
                return "AD"
            } else {
                return "40"
            }
        }
        
        // Standard scoring
        switch points {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default: return "Game"
        }
    }
    
    /// Award point to a player
    func awardPoint(toPlayer1: Bool, scoringStyle: ScoringStyle = .advantage) {
        if toPlayer1 {
            pointsPlayer1 += 1
        } else {
            pointsPlayer2 += 1
        }
        
        // Check if game is complete
        if isComplete(scoringStyle: scoringStyle) {
            completedAt = Date()
        }
    }
}
