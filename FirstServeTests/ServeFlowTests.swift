//
//  ServeFlowTests.swift
//  FirstServeTests
//
//  Tests for serve flow and state transitions
//  Created by Cici on 2/14/26.
//

import XCTest
import SwiftData
@testable import FirstServe

@MainActor
final class ServeFlowTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var match: Match!
    var player1: Player!
    var player2: Player!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self, configurations: config)
        modelContext = modelContainer.mainContext
        
        player1 = Player(name: "Player 1")
        player2 = Player(name: "Player 2")
        match = Match(player1: player1, player2: player2, format: .singleSet, surface: .hardCourt)
        
        modelContext.insert(match)
        modelContext.insert(player1)
        modelContext.insert(player2)
        
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        match = nil
        player1 = nil
        player2 = nil
    }
    
    // MARK: - First Serve Tests
    
    func testFirstServeAce() throws {
        // Given: Match is ready, player 1 is serving
        XCTAssertEqual(match.acesPlayer1, 0)
        
        // When: Player 1 hits an ace on first serve
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        // Then: First serve stats are updated
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.firstServesMadePlayer1, 1)
        XCTAssertEqual(match.firstServePercentagePlayer1, 100.0)
    }
    
    func testFirstServeFault() throws {
        // Given: Match is ready
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 0)
        
        // When: Player 1 misses first serve
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        
        // Then: First serve attempt is recorded, but not made
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.firstServesMadePlayer1, 0)
        XCTAssertEqual(match.firstServePercentagePlayer1, 0.0)
    }
    
    func testFirstServeIn() throws {
        // Given: Match is ready
        // When: Player 1 makes first serve
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: false)
        
        // Then: Stats are updated correctly
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.firstServesMadePlayer1, 1)
        XCTAssertEqual(match.firstServePercentagePlayer1, 100.0)
    }
    
    // MARK: - Second Serve Tests
    
    func testSecondServeIn() throws {
        // Given: First serve was a fault
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        
        // When: Second serve is made
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        
        // Then: Only first serve stats change
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.firstServesMadePlayer1, 0)
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.secondServesMadePlayer1, 1)
    }
    
    func testDoubleFault() throws {
        // Given: First serve was a fault
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        
        // When: Second serve is also a fault
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        
        // Then: Double fault is recorded
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 1)
        XCTAssertEqual(match.secondServesMadePlayer1, 0)
    }
    
    // MARK: - Serve Percentage Tests
    
    func testFirstServePercentageCalculation() throws {
        // Given: Multiple serves
        match.recordServe(forPlayer1: true, firstServe: true, made: true)  // 1/1 = 100%
        match.recordServe(forPlayer1: true, firstServe: true, made: false) // 1/2 = 50%
        match.recordServe(forPlayer1: true, firstServe: true, made: true)  // 2/3 = 66.67%
        match.recordServe(forPlayer1: true, firstServe: true, made: true)  // 3/4 = 75%
        
        // Then: Percentage is calculated correctly
        XCTAssertEqual(match.firstServePercentagePlayer1, 75.0)
    }
    
    func testFirstServePointsWonPercentage() throws {
        // Given: Multiple first serves made
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)  // 1/1 = 100%
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: false) // 1/2 = 50%
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)  // 2/3 = 66.67%
        
        // Then: Points won percentage is calculated correctly
        XCTAssertEqual(match.firstServePercentagePlayer1, 100.0) // All made
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 2)
        XCTAssertEqual(match.firstServePointsWonPercentagePlayer1, 66.67, accuracy: 0.01)
    }
    
    func testZeroFirstServesHandled() throws {
        // Given: No serves recorded
        // When: Checking percentages
        // Then: Should return 0 instead of dividing by zero
        XCTAssertEqual(match.firstServePercentagePlayer1, 0.0)
        XCTAssertEqual(match.firstServePointsWonPercentagePlayer1, 0.0)
    }
    
    // MARK: - Player 2 Serve Tests
    
    func testPlayer2ServeStats() throws {
        // Given: Player 2 is serving
        // When: Recording serves for player 2
        match.recordServe(forPlayer1: false, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: false, firstServe: true, made: false)
        match.recordServe(forPlayer1: false, firstServe: false, made: true, pointWon: false)
        
        // Then: Player 2 stats are updated
        XCTAssertEqual(match.firstServeAttemptsPlayer2, 2)
        XCTAssertEqual(match.firstServesMadePlayer2, 1)
        XCTAssertEqual(match.firstServePercentagePlayer2, 50.0)
        XCTAssertEqual(match.secondServeAttemptsPlayer2, 1)
        XCTAssertEqual(match.secondServesMadePlayer2, 1)
    }
    
    // MARK: - Mixed Serve Scenarios
    
    func testAlternatingServers() throws {
        // Given: Both players are serving in alternating games
        // When: Recording serves for both players
        // Player 1 game 1
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: false)
        
        // Player 2 game 2
        match.recordServe(forPlayer1: false, firstServe: true, made: false)
        match.recordServe(forPlayer1: false, firstServe: false, made: true, pointWon: true)
        
        // Then: Both players have independent stats
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.firstServesMadePlayer1, 2)
        XCTAssertEqual(match.firstServePercentagePlayer1, 100.0)
        
        XCTAssertEqual(match.firstServeAttemptsPlayer2, 1)
        XCTAssertEqual(match.firstServesMadePlayer2, 0)
        XCTAssertEqual(match.firstServePercentagePlayer2, 0.0)
        XCTAssertEqual(match.secondServeAttemptsPlayer2, 1)
        XCTAssertEqual(match.secondServesMadePlayer2, 1)
    }
    
    func testRealisticServeGame() throws {
        // Given: A realistic service game scenario
        // When: Simulating a complete service game
        
        // Point 1: Ace (15-0)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        // Point 2: First serve in, rally, point won (30-0)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        // Point 3: Fault, second serve in, point lost (30-15)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        match.recordServe(forPlayer1: true, firstServe: false, made: true, pointWon: false)
        
        // Point 4: First serve in, point won (40-15)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        // Point 5: Fault, fault (double fault) (40-30)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        match.recordServe(forPlayer1: true, firstServe: false, made: false)
        
        // Point 6: First serve in, point won (Game)
        match.recordServe(forPlayer1: true, firstServe: true, made: true, pointWon: true)
        
        // Then: Stats are correct
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 6)
        XCTAssertEqual(match.firstServesMadePlayer1, 4)
        XCTAssertEqual(match.firstServePercentagePlayer1, 66.67, accuracy: 0.01)
        
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 2)
        XCTAssertEqual(match.secondServesMadePlayer1, 1)
        
        XCTAssertEqual(match.pointsWonOnFirstServePlayer1, 4)
        XCTAssertEqual(match.firstServePointsWonPercentagePlayer1, 100.0) // 4/4
    }
}
