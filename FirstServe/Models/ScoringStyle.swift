//
//  ScoringStyle.swift
//  FirstServe
//
//  Created by Cici on 2/13/26.
//

import Foundation

/// Deuce scoring style
enum ScoringStyle: String, Codable, CaseIterable {
    case advantage = "Ad Scoring"
    case noAdvantage = "No-Ad (Sudden Death)"
    
    var description: String {
        switch self {
        case .advantage:
            return "Traditional advantage scoring at deuce"
        case .noAdvantage:
            return "Sudden death point at deuce (receiver's choice)"
        }
    }
}
