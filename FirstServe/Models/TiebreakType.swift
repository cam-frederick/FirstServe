//
//  TiebreakType.swift
//  FirstServe
//
//  Created by Cici on 2/13/26.
//

import Foundation

/// Tiebreak format
enum TiebreakType: String, Codable, CaseIterable {
    case regular = "Regular (7 points)"
    case extended = "Extended (10 points)"
    case matchTiebreak = "Match Tiebreak (10 points)"
    
    var pointsToWin: Int {
        switch self {
        case .regular:
            return 7
        case .extended, .matchTiebreak:
            return 10
        }
    }
    
    var description: String {
        switch self {
        case .regular:
            return "First to 7 points, win by 2"
        case .extended:
            return "First to 10 points, win by 2"
        case .matchTiebreak:
            return "First to 10 points, win by 2 (in lieu of final set)"
        }
    }
}
