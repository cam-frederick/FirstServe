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

/// Scoring granularity — controls which UI and tracking features are available
enum ScoringMode: String, Codable, CaseIterable {
    case gamesOnly = "Games Only"
    case pointByPoint = "Points"
    case fullStats = "Full Stats"
}

/// Match format (best of 3 or 5 sets, or single set/super set)
enum MatchFormat: String, Codable, CaseIterable {
    case singleSet = "Single Set"
    case superSet = "Super Set (First to 8)"
    case bestOf3 = "Best of 3"
    case bestOf5 = "Best of 5"
    
    var setsToWin: Int {
        switch self {
        case .singleSet, .superSet:
            return 1
        case .bestOf3:
            return 2
        case .bestOf5:
            return 3
        }
    }

    /// Display name for UI — keeps raw values stable for SwiftData schema
    var displayName: String {
        switch self {
        case .superSet: return "Super Set (First to 8)"
        default: return rawValue
        }
    }
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
    
    /// Scoring configuration
    var scoringMode: ScoringMode
    var scoringStyle: ScoringStyle
    var finalSetTiebreakType: TiebreakType?
    var regularTiebreakType: TiebreakType
    
    /// Players (should be exactly 2)
    @Relationship(deleteRule: .nullify)
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
    
    /// Serve tracking
    var firstServeAttemptsPlayer1: Int
    var firstServesMadePlayer1: Int
    var firstServeAttemptsPlayer2: Int
    var firstServesMadePlayer2: Int
    var pointsWonOnFirstServePlayer1: Int
    var pointsWonOnFirstServePlayer2: Int
    var pointsWonOnSecondServePlayer1: Int
    var pointsWonOnSecondServePlayer2: Int
    
    /// Second serve tracking
    var secondServeAttemptsPlayer1: Int
    var secondServesMadePlayer1: Int
    var secondServeAttemptsPlayer2: Int
    var secondServesMadePlayer2: Int

    /// Break point tracking (as returner)
    var breakPointsWonPlayer1: Int
    var breakPointsWonPlayer2: Int
    var breakPointsFacedPlayer1: Int
    var breakPointsFacedPlayer2: Int
    
    /// Detailed shot statistics
    @Relationship(deleteRule: .cascade)
    var shotStatistics: [ShotStatistic]
    
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
        let requiredSets = format.setsToWin
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
    
    init(
        player1: Player,
        player2: Player,
        format: MatchFormat,
        surface: CourtSurface,
        scoringMode: ScoringMode = .fullStats,
        scoringStyle: ScoringStyle = .advantage,
        regularTiebreakType: TiebreakType = .regular,
        finalSetTiebreakType: TiebreakType? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.format = format
        self.surface = surface
        self.scoringMode = scoringMode
        self.scoringStyle = scoringStyle
        self.regularTiebreakType = regularTiebreakType
        self.finalSetTiebreakType = finalSetTiebreakType
        self.players = [player1, player2]
        self.sets = []
        self.shotStatistics = []
        
        self.acesPlayer1 = 0
        self.acesPlayer2 = 0
        self.doubleFaultsPlayer1 = 0
        self.doubleFaultsPlayer2 = 0
        self.winnersPlayer1 = 0
        self.winnersPlayer2 = 0
        self.unforcedErrorsPlayer1 = 0
        self.unforcedErrorsPlayer2 = 0
        
        self.firstServeAttemptsPlayer1 = 0
        self.firstServesMadePlayer1 = 0
        self.firstServeAttemptsPlayer2 = 0
        self.firstServesMadePlayer2 = 0
        self.pointsWonOnFirstServePlayer1 = 0
        self.pointsWonOnFirstServePlayer2 = 0
        self.pointsWonOnSecondServePlayer1 = 0
        self.pointsWonOnSecondServePlayer2 = 0
        
        self.secondServeAttemptsPlayer1 = 0
        self.secondServesMadePlayer1 = 0
        self.secondServeAttemptsPlayer2 = 0
        self.secondServesMadePlayer2 = 0

        self.breakPointsWonPlayer1 = 0
        self.breakPointsWonPlayer2 = 0
        self.breakPointsFacedPlayer1 = 0
        self.breakPointsFacedPlayer2 = 0
    }
    
    /// Human-readable label for the unit shown on the scoreboard
    /// Super set uses "points" semantically; regular formats use "games"
    var scoreUnitLabel: String {
        format == .superSet ? "PTS" : ""
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
    
    // MARK: - Total Points Won

    /// Total points won by player 1 (summed from all games + tiebreaks)
    var totalPointsWonPlayer1: Int {
        var total = 0
        for set in sets {
            for game in set.games {
                total += game.pointsPlayer1
            }
            total += set.tiebreakScorePlayer1 ?? 0
        }
        return total
    }

    /// Total points won by player 2 (summed from all games + tiebreaks)
    var totalPointsWonPlayer2: Int {
        var total = 0
        for set in sets {
            for game in set.games {
                total += game.pointsPlayer2
            }
            total += set.tiebreakScorePlayer2 ?? 0
        }
        return total
    }

    // MARK: - Serve Statistics

    /// First serve percentage for player 1
    var firstServePercentagePlayer1: Double {
        guard firstServeAttemptsPlayer1 > 0 else { return 0.0 }
        return Double(firstServesMadePlayer1) / Double(firstServeAttemptsPlayer1) * 100
    }
    
    /// First serve percentage for player 2
    var firstServePercentagePlayer2: Double {
        guard firstServeAttemptsPlayer2 > 0 else { return 0.0 }
        return Double(firstServesMadePlayer2) / Double(firstServeAttemptsPlayer2) * 100
    }
    
    /// Points won on first serve percentage for player 1
    var firstServePointsWonPercentagePlayer1: Double {
        guard firstServesMadePlayer1 > 0 else { return 0.0 }
        return Double(pointsWonOnFirstServePlayer1) / Double(firstServesMadePlayer1) * 100
    }
    
    /// Points won on first serve percentage for player 2
    var firstServePointsWonPercentagePlayer2: Double {
        guard firstServesMadePlayer2 > 0 else { return 0.0 }
        return Double(pointsWonOnFirstServePlayer2) / Double(firstServesMadePlayer2) * 100
    }
    
    /// Second serve percentage for player 1
    var secondServePercentagePlayer1: Double {
        guard secondServeAttemptsPlayer1 > 0 else { return 0.0 }
        return Double(secondServesMadePlayer1) / Double(secondServeAttemptsPlayer1) * 100
    }
    
    /// Second serve percentage for player 2
    var secondServePercentagePlayer2: Double {
        guard secondServeAttemptsPlayer2 > 0 else { return 0.0 }
        return Double(secondServesMadePlayer2) / Double(secondServeAttemptsPlayer2) * 100
    }
    
    /// Points won on second serve percentage for player 1
    var secondServePointsWonPercentagePlayer1: Double {
        guard secondServesMadePlayer1 > 0 else { return 0.0 }
        return Double(pointsWonOnSecondServePlayer1) / Double(secondServesMadePlayer1) * 100
    }
    
    /// Points won on second serve percentage for player 2
    var secondServePointsWonPercentagePlayer2: Double {
        guard secondServesMadePlayer2 > 0 else { return 0.0 }
        return Double(pointsWonOnSecondServePlayer2) / Double(secondServesMadePlayer2) * 100
    }
    
    /// Record a serve
    func recordServe(forPlayer1: Bool, firstServe: Bool, made: Bool, pointWon: Bool? = nil) {
        if forPlayer1 {
            if firstServe {
                firstServeAttemptsPlayer1 += 1
                if made {
                    firstServesMadePlayer1 += 1
                    if let pointWon = pointWon, pointWon {
                        pointsWonOnFirstServePlayer1 += 1
                    }
                }
            } else {
                // Second serve attempt
                secondServeAttemptsPlayer1 += 1
                if made {
                    secondServesMadePlayer1 += 1
                    if let pointWon = pointWon, pointWon {
                        pointsWonOnSecondServePlayer1 += 1
                    }
                }
            }
        } else {
            if firstServe {
                firstServeAttemptsPlayer2 += 1
                if made {
                    firstServesMadePlayer2 += 1
                    if let pointWon = pointWon, pointWon {
                        pointsWonOnFirstServePlayer2 += 1
                    }
                }
            } else {
                // Second serve attempt
                secondServeAttemptsPlayer2 += 1
                if made {
                    secondServesMadePlayer2 += 1
                    if let pointWon = pointWon, pointWon {
                        pointsWonOnSecondServePlayer2 += 1
                    }
                }
            }
        }
        updatedAt = Date()
    }
    
    /// Record a shot statistic
    func recordShotStatistic(
        playerNumber: Int,
        statType: StatType,
        shotType: ShotType,
        contactType: ContactType
    ) {
        let stat = ShotStatistic(
            playerNumber: playerNumber,
            statType: statType,
            shotType: shotType,
            contactType: contactType,
            setNumber: sets.count,
            matchId: self.id
        )
        shotStatistics.append(stat)
        
        // Update basic counters
        if playerNumber == 1 {
            if statType == .winner {
                winnersPlayer1 += 1
            } else if statType == .unforcedError {
                unforcedErrorsPlayer1 += 1
            }
        } else {
            if statType == .winner {
                winnersPlayer2 += 1
            } else if statType == .unforcedError {
                unforcedErrorsPlayer2 += 1
            }
        }
        
        updatedAt = Date()
    }
    
    /// Get shot statistics for a specific player
    func shotStatistics(forPlayerNumber: Int) -> [ShotStatistic] {
        shotStatistics.filter { $0.playerNumber == forPlayerNumber }
    }
    
    /// Get winners by shot type for a player
    func winners(forPlayerNumber: Int, shotType: ShotType? = nil, contactType: ContactType? = nil) -> Int {
        var filtered = shotStatistics(forPlayerNumber: forPlayerNumber).filter { $0.statType == .winner }
        if let shotType = shotType {
            filtered = filtered.filter { $0.shotType == shotType }
        }
        if let contactType = contactType {
            filtered = filtered.filter { $0.contactType == contactType }
        }
        return filtered.count
    }
    
    /// Get unforced errors by shot type for a player
    func unforcedErrors(forPlayerNumber: Int, shotType: ShotType? = nil, contactType: ContactType? = nil) -> Int {
        var filtered = shotStatistics(forPlayerNumber: forPlayerNumber).filter { $0.statType == .unforcedError }
        if let shotType = shotType {
            filtered = filtered.filter { $0.shotType == shotType }
        }
        if let contactType = contactType {
            filtered = filtered.filter { $0.contactType == contactType }
        }
        return filtered.count
    }
}
