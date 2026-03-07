//
//  ServeStatisticsTests.swift
//  FirstServeTests
//
//  Created by Cici on 2/13/26.
//

import XCTest
@testable import FirstServe

final class ServeStatisticsTests: XCTestCase {
    
    var player1: Player!
    var player2: Player!
    var match: Match!
    
    override func setUp() {
        super.setUp()
        player1 = Player(name: "Player 1")
        player2 = Player(name: "Player 2")
        match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
    }
    
    override func tearDown() {
        player1 = nil
        player2 = nil
        match = nil
        super.tearDown()
    }
    
    // MARK: - First Serve Tracking
    
    func testFirstServeAttempts() {
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 3)
        XCTAssertEqual(match.firstServesMadePlayer1, 2)
    }
    
    func testFirstServePercentage() {
        // Player 1: 3 out of 4 first serves in
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        
        XCTAssertEqual(match.firstServePercentagePlayer1, 75.0, accuracy: 0.01)
    }
    
    func testFirstServePercentageZeroAttempts() {
        XCTAssertEqual(match.firstServePercentagePlayer1, 0.0)
        XCTAssertEqual(match.firstServePercentagePlayer2, 0.0)
    }
    
    // MARK: - Points Won on Serve
    
    func testPointsWonOnFirstServe() {
        // Made first serve, won point
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 1)
        
        // Made first serve, lost point
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: false)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 1)
        
        // Missed first serve (no point won tracking)
        match.recordServe(forPlayer1: true, firstServe: true, made: false, pointWon: false)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 1)
    }
    
    func testPointsWonOnSecondServe() {
        // Second serve made, won point
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
        
        // Second serve made, lost point
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
    }
    
    func testFirstServePointsWonPercentage() {
        // 2 first serves made, won both points
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        XCTAssertEqual(match.firstServePointsWonPercentagePlayer1, 100.0, accuracy: 0.01)
        
        // Add one more where point was lost
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: false)
        
        XCTAssertEqual(match.firstServePointsWonPercentagePlayer1, 66.67, accuracy: 0.01)
    }
    
    // MARK: - Both Players
    
    func testBothPlayersServeTracking() {
        // Player 1 serves
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        
        // Player 2 serves
        match.recordServe(forPlayer1: false, firstServe: true, made: true, pointWon: false)
        match.recordServe(forPlayer1: false, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: false, firstServe: true, made: true, pointWon: true)
        
        // Verify Player 1
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.firstServesMadePlayer1, 1)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 1)
        
        // Verify Player 2
        XCTAssertEqual(match.firstServeAttemptsPlayer2, 3)
        XCTAssertEqual(match.firstServesMadePlayer2, 3)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer2, 2)
    }
    
    // MARK: - Edge Cases
    
    func testServeTrackingWithoutPointOutcome() {
        // Can record serve without specifying point outcome
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.firstServesMadePlayer1, 1)
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 0)
    }
    
    // MARK: - Second Serve Tracking
    
    func testSecondServeAttemptsAreTracked() {
        // First serve fault → second serve attempts
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: false, made: false) // double fault
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 3)
        XCTAssertEqual(match.secondServesMadePlayer1, 2)
        // First serve fields should be untouched
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 0)
    }
    
    func testSecondServePercentageCalculated() {
        // 2 out of 3 second serves made
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        
        XCTAssertEqual(match.secondServePercentagePlayer1, 66.67, accuracy: 0.01)
    }
    
    func testSecondServePercentageZeroWhenNoAttempts() {
        XCTAssertEqual(match.secondServePercentagePlayer1, 0.0)
        XCTAssertEqual(match.secondServePercentagePlayer2, 0.0)
    }
    
    func testPointsWonOnSecondServeTracked() {
        // Made second serve, won point
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
        
        // Made second serve, lost point
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
        
        // Double fault — no point won
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
    }
    
    func testSecondServePointsWonPercentage() {
        // 3 second serves made, won 2 points
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        
        XCTAssertEqual(match.secondServePointsWonPercentagePlayer1, 66.67, accuracy: 0.01)
    }
    
    func testBothPlayersSecondServeTracking() {
        // Player 1 second serves
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        
        // Player 2 second serves
        match.recordServe(forPlayer1: false, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: false, firstServe: false, made: true, pointWon: true)
        match.recordServe(forPlayer1: false, firstServe: false, made: true, pointWon: false)
        
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.secondServesMadePlayer1, 1)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer1, 1)
        
        XCTAssertEqual(match.secondServeAttemptsPlayer2, 3)
        XCTAssertEqual(match.secondServesMadePlayer2, 3)
        XCTAssertEqual(match.pointsWonOnSecondServePlayer2, 2)
    }
    
    func testFirstAndSecondServeFieldsAreIndependent() {
        // First serve
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        
        // Second serve
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.firstServesMadePlayer1, 1)
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.secondServesMadePlayer1, 1)
    }
    
    // MARK: - New Match Initialization
    
    func testNewMatchHasZeroSecondServeFields() {
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 0)
        XCTAssertEqual(match.secondServesMadePlayer1, 0)
        XCTAssertEqual(match.secondServeAttemptsPlayer2, 0)
        XCTAssertEqual(match.secondServesMadePlayer2, 0)
    }
    
    // MARK: - scoreUnitLabel
    
    func testScoreUnitLabelForSuperSet() {
        let player1 = Player(name: "A")
        let player2 = Player(name: "B")
        let superSetMatch = Match(player1: player1, player2: player2, format: .superSet, surface: .hardCourt)
        XCTAssertEqual(superSetMatch.scoreUnitLabel, "PTS")
    }
    
    func testScoreUnitLabelForRegularFormats() {
        let player1 = Player(name: "A")
        let player2 = Player(name: "B")
        
        let bestOf3 = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        XCTAssertEqual(bestOf3.scoreUnitLabel, "")
        
        let singleSet = Match(player1: player1, player2: player2, format: .singleSet, surface: .clay)
        XCTAssertEqual(singleSet.scoreUnitLabel, "")
        
        let bestOf5 = Match(player1: player1, player2: player2, format: .bestOf5, surface: .grass)
        XCTAssertEqual(bestOf5.scoreUnitLabel, "")
    }
}
