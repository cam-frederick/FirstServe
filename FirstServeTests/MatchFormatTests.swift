//
//  MatchFormatTests.swift
//  FirstServeTests
//
//  Created by Cici on 2/13/26.
//

import XCTest
@testable import FirstServe

final class MatchFormatTests: XCTestCase {
    
    // MARK: - Single Set Tests
    
    func testSingleSetFormat() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(player1: player1, player2: player2, format: .singleSet, surface: .hardCourt)
        
        XCTAssertEqual(match.format.setsToWin, 1)
        XCTAssertFalse(match.isComplete)
        
        // Simulate winning a set (6-0)
        match.startNewSet()
        let set = match.currentSet!
        for _ in 0..<6 {
            set.gamesPlayer1 += 1
        }
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Player 1")
    }
    
    // MARK: - Super Set Tests
    
    func testSuperSetFormat() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(player1: player1, player2: player2, format: .superSet, surface: .hardCourt)
        
        XCTAssertEqual(match.format.setsToWin, 1)
        
        match.startNewSet()
        let set = match.currentSet!
        
        // Super set requires first to 8 games, win by 2
        for _ in 0..<8 {
            set.gamesPlayer1 += 1
        }
        for _ in 0..<6 {
            set.gamesPlayer2 += 1
        }
        
        XCTAssertTrue(set.isComplete(format: .superSet))
        XCTAssertTrue(match.isComplete)
    }
    
    func testSuperSetTiebreak() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(player1: player1, player2: player2, format: .superSet, surface: .hardCourt)
        
        match.startNewSet()
        let set = match.currentSet!
        
        // Simulate 8-8 (requires tiebreak)
        set.gamesPlayer1 = 8
        set.gamesPlayer2 = 8
        
        XCTAssertTrue(set.isTiebreak(format: .superSet))
        XCTAssertFalse(set.isComplete(format: .superSet))
    }
    
    // MARK: - No-Ad Scoring Tests
    
    func testNoAdScoring() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(
            player1: player1,
            player2: player2,
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .noAdvantage
        )
        
        XCTAssertEqual(match.scoringStyle, .noAdvantage)
        
        match.startNewSet()
        let set = match.currentSet!
        set.startNewGame(serverIsPlayer1: true)
        let game = set.currentGame!
        
        // Simulate deuce (3-3)
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 3
        
        // In no-ad, deuce is not complete yet (next point wins)
        XCTAssertFalse(game.isComplete(scoringStyle: .noAdvantage))
        
        // Award one more point to player 1
        game.pointsPlayer1 = 4
        
        // Now game should be complete (no advantage needed)
        XCTAssertTrue(game.isComplete(scoringStyle: .noAdvantage))
        XCTAssertEqual(game.winner, 1)
    }
    
    func testAdvantageScoring() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(
            player1: player1,
            player2: player2,
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage
        )
        
        match.startNewSet()
        let set = match.currentSet!
        set.startNewGame(serverIsPlayer1: true)
        let game = set.currentGame!
        
        // Simulate deuce (3-3)
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 3
        XCTAssertFalse(game.isComplete(scoringStyle: .advantage))
        
        // Award advantage to player 1
        game.pointsPlayer1 = 4
        XCTAssertFalse(game.isComplete(scoringStyle: .advantage))
        
        // Player 2 brings it back to deuce
        game.pointsPlayer2 = 4
        XCTAssertFalse(game.isComplete(scoringStyle: .advantage))
        
        // Player 1 wins by 2
        game.pointsPlayer1 = 5
        game.pointsPlayer2 = 3
        XCTAssertTrue(game.isComplete(scoringStyle: .advantage))
    }
    
    // MARK: - Extended Tiebreak Tests
    
    func testExtendedTiebreak() {
        let tiebreak = TiebreakType.extended
        XCTAssertEqual(tiebreak.pointsToWin, 10)
    }
    
    func testTiebreakCompletion() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(
            player1: player1,
            player2: player2,
            format: .bestOf3,
            surface: .hardCourt,
            regularTiebreakType: .extended
        )
        
        match.startNewSet()
        let set = match.currentSet!
        
        // Simulate 6-6
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 6
        set.startTiebreak()
        
        // Extended tiebreak to 10 points
        set.tiebreakScorePlayer1 = 10
        set.tiebreakScorePlayer2 = 8
        
        XCTAssertTrue(set.isTiebreakComplete(tiebreakType: .extended))
    }
    
    func testTiebreakMustWinBy2() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(
            player1: player1,
            player2: player2,
            format: .bestOf3,
            surface: .hardCourt,
            regularTiebreakType: .extended
        )
        
        match.startNewSet()
        let set = match.currentSet!
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 6
        set.startTiebreak()
        
        // 10-9 is not enough
        set.tiebreakScorePlayer1 = 10
        set.tiebreakScorePlayer2 = 9
        XCTAssertFalse(set.isTiebreakComplete(tiebreakType: .extended))
        
        // 11-9 wins
        set.tiebreakScorePlayer1 = 11
        XCTAssertTrue(set.isTiebreakComplete(tiebreakType: .extended))
    }
    
    // MARK: - Match Tiebreak Tests
    
    func testMatchTiebreakInFinalSet() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let match = Match(
            player1: player1,
            player2: player2,
            format: .bestOf3,
            surface: .hardCourt,
            regularTiebreakType: .regular,
            finalSetTiebreakType: .matchTiebreak
        )
        
        XCTAssertNotNil(match.finalSetTiebreakType)
        XCTAssertEqual(match.finalSetTiebreakType, .matchTiebreak)
        XCTAssertEqual(match.finalSetTiebreakType?.pointsToWin, 10)
    }
}
