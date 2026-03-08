//
//  WatchMatchState.swift
//  FirstServe
//
//  Lightweight Codable structs for Watch ↔ iPhone communication.
//  Shared by both the iOS and watchOS targets.
//

import Foundation

/// Full match state sent from iPhone to Watch
struct WatchMatchState: Codable, Identifiable, Equatable {
    var id: String
    var player1Name: String
    var player2Name: String
    var scoringMode: String
    var format: String
    var sets: [WatchSetState]
    var currentGameScore: WatchGameScore?
    var isInTiebreak: Bool
    var isComplete: Bool
    var canUndo: Bool
}

/// Score state for a single set
struct WatchSetState: Codable, Equatable {
    var gamesPlayer1: Int
    var gamesPlayer2: Int
    var tiebreakScorePlayer1: Int?
    var tiebreakScorePlayer2: Int?
    var isComplete: Bool
}

/// Current game score (nil for gamesOnly mode)
struct WatchGameScore: Codable, Equatable {
    var player1Score: String
    var player2Score: String
    var serverIsPlayer1: Bool
}
