//
//  Player.swift
//  MatchPoint
//
//  Created by Cici on 1/29/26.
//

import Foundation
import SwiftData

/// Represents a tennis player
@Model
final class Player {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    /// Relationship: matches where this player participated
    @Relationship(deleteRule: .nullify, inverse: \Match.players)
    var matches: [Match]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.matches = []
    }
}

extension Player {
    /// Total matches played
    var matchesPlayed: Int {
        matches.count
    }
    
    /// Matches won
    var matchesWon: Int {
        matches.filter { $0.winner?.id == self.id }.count
    }
    
    /// Win percentage
    var winPercentage: Double {
        guard matchesPlayed > 0 else { return 0 }
        return Double(matchesWon) / Double(matchesPlayed) * 100
    }
}
