//
//  ShotStatistic.swift
//  FirstServe
//
//  Created by Cici on 2/13/26.
//

import Foundation
import SwiftData

/// Type of statistical event
enum StatType: String, Codable, CaseIterable {
    case winner = "Winner"
    case unforcedError = "Unforced Error"
}

/// Type of shot (forehand/backhand)
enum ShotType: String, Codable, CaseIterable {
    case forehand = "Forehand"
    case backhand = "Backhand"
}

/// Type of contact
enum ContactType: String, Codable, CaseIterable {
    case groundstroke = "Groundstroke"
    case volley = "Volley"
    case overhead = "Overhead"
    case serve = "Serve"
}

/// Detailed shot-by-shot statistic tracking
@Model
final class ShotStatistic {
    var id: UUID
    var timestamp: Date
    
    /// Which player (1 or 2)
    var playerNumber: Int
    
    /// Type of stat (winner vs error)
    var statType: StatType
    
    /// Shot type (FH/BH)
    var shotType: ShotType
    
    /// Contact type (GS/V/OH/S)
    var contactType: ContactType
    
    /// Optional: which set this occurred in
    var setNumber: Int?
    
    /// Relationship to parent match
    var matchId: UUID
    
    init(
        playerNumber: Int,
        statType: StatType,
        shotType: ShotType,
        contactType: ContactType,
        setNumber: Int? = nil,
        matchId: UUID
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.playerNumber = playerNumber
        self.statType = statType
        self.shotType = shotType
        self.contactType = contactType
        self.setNumber = setNumber
        self.matchId = matchId
    }
}

extension ShotStatistic {
    /// Human-readable description
    var description: String {
        "\(shotType.rawValue) \(contactType.rawValue) \(statType.rawValue)"
    }
}
