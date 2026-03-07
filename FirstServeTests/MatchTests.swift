//
//  MatchTests.swift
//  FirstServeTests
//
//  Unit tests for Match model and match-level scoring logic
//

import XCTest
import SwiftData

final class MatchTests: XCTestCase {
    
    // MARK: - Match Initialization
    
    func test_newMatch_hasCorrectInitialState() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        XCTAssertEqual(match.players.count, 2)
        XCTAssertEqual(match.players.first?.name, "Alice")
        XCTAssertEqual(match.players.last?.name, "Bob")
        XCTAssertEqual(match.format, .bestOf3)
        XCTAssertEqual(match.surface, .hardCourt)
        XCTAssertEqual(match.sets.count, 0)
        XCTAssertFalse(match.isComplete)
        XCTAssertNil(match.winner)
        XCTAssertNil(match.completedAt)
    }
    
    func test_newMatch_statsInitializedToZero() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .clay)
        
        XCTAssertEqual(match.acesPlayer1, 0)
        XCTAssertEqual(match.acesPlayer2, 0)
        XCTAssertEqual(match.doubleFaultsPlayer1, 0)
        XCTAssertEqual(match.doubleFaultsPlayer2, 0)
        XCTAssertEqual(match.winnersPlayer1, 0)
        XCTAssertEqual(match.winnersPlayer2, 0)
        XCTAssertEqual(match.unforcedErrorsPlayer1, 0)
        XCTAssertEqual(match.unforcedErrorsPlayer2, 0)
        
        // Serve fields
        XCTAssertEqual(match.firstServeAttemptsPlayer1, 0)
        XCTAssertEqual(match.firstServesMadePlayer1, 0)
        XCTAssertEqual(match.firstServeAttemptsPlayer2, 0)
        XCTAssertEqual(match.firstServesMadePlayer2, 0)
        XCTAssertEqual(match.secondServeAttemptsPlayer1, 0)
        XCTAssertEqual(match.secondServesMadePlayer1, 0)
        XCTAssertEqual(match.secondServeAttemptsPlayer2, 0)
        XCTAssertEqual(match.secondServesMadePlayer2, 0)
    }
    
    func test_matchFormat_bestOf3() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .grass)
        
        XCTAssertEqual(match.format, .bestOf3)
    }
    
    func test_matchFormat_bestOf5() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .carpet)
        
        XCTAssertEqual(match.format, .bestOf5)
    }
    
    // MARK: - Set Management
    
    func test_startNewSet_addsSetToMatch() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        
        XCTAssertEqual(match.sets.count, 1)
        XCTAssertEqual(match.sets.first?.setNumber, 1)
    }
    
    func test_startNewSet_setsHaveSequentialNumbers() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        match.startNewSet()
        match.startNewSet()
        
        XCTAssertEqual(match.sets.count, 3)
        XCTAssertEqual(match.sets[0].setNumber, 1)
        XCTAssertEqual(match.sets[1].setNumber, 2)
        XCTAssertEqual(match.sets[2].setNumber, 3)
    }
    
    func test_currentSet_returnsLastIncompleteSet() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        
        XCTAssertNotNil(match.currentSet)
        XCTAssertEqual(match.currentSet?.setNumber, 1)
    }
    
    func test_currentSet_nilWhenNoSets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        XCTAssertNil(match.currentSet)
    }
    
    func test_currentSet_nilWhenAllSetsComplete() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        let set = match.sets.first!
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 4
        
        XCTAssertNil(match.currentSet)
    }
    
    // MARK: - Match Completion (Best of 3)
    
    func test_bestOf3_player1Wins2Sets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 1 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 6
        match.sets[1].gamesPlayer2 = 3
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    func test_bestOf3_player2Wins2Sets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: Player 2 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 4
        match.sets[0].gamesPlayer2 = 6
        
        // Set 2: Player 2 wins 6-2
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 2
        match.sets[1].gamesPlayer2 = 6
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Bob")
    }
    
    func test_bestOf3_notCompleteAfter1Set() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        XCTAssertFalse(match.isComplete)
        XCTAssertNil(match.winner)
    }
    
    func test_bestOf3_notCompleteWhenSetsSplit1_1() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 2 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 3
        match.sets[1].gamesPlayer2 = 6
        
        XCTAssertFalse(match.isComplete)
        XCTAssertNil(match.winner)
    }
    
    func test_bestOf3_decidingThirdSet() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 2 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 3
        match.sets[1].gamesPlayer2 = 6
        
        // Set 3: Player 1 wins 7-5
        match.startNewSet()
        match.sets[2].gamesPlayer1 = 7
        match.sets[2].gamesPlayer2 = 5
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    // MARK: - Match Completion (Best of 5)
    
    func test_bestOf5_player1Wins3StraightSets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .grass)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 1 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 6
        match.sets[1].gamesPlayer2 = 3
        
        // Set 3: Player 1 wins 6-2
        match.startNewSet()
        match.sets[2].gamesPlayer1 = 6
        match.sets[2].gamesPlayer2 = 2
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    func test_bestOf5_player2Wins3SetsTo2() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .clay)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 2 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 3
        match.sets[1].gamesPlayer2 = 6
        
        // Set 3: Player 1 wins 6-2
        match.startNewSet()
        match.sets[2].gamesPlayer1 = 6
        match.sets[2].gamesPlayer2 = 2
        
        // Set 4: Player 2 wins 7-5
        match.startNewSet()
        match.sets[3].gamesPlayer1 = 5
        match.sets[3].gamesPlayer2 = 7
        
        // Set 5: Player 2 wins 6-4
        match.startNewSet()
        match.sets[4].gamesPlayer1 = 4
        match.sets[4].gamesPlayer2 = 6
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Bob")
    }
    
    func test_bestOf5_notCompleteAfter2Sets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .hardCourt)
        
        // Set 1: Player 1 wins 6-4
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        // Set 2: Player 1 wins 6-3
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 6
        match.sets[1].gamesPlayer2 = 3
        
        XCTAssertFalse(match.isComplete)
        XCTAssertNil(match.winner)
    }
    
    // MARK: - Score String
    
    func test_scoreString_empty_whenNoSets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        XCTAssertEqual(match.scoreString, "")
    }
    
    func test_scoreString_singleSet() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        XCTAssertEqual(match.scoreString, "6-4")
    }
    
    func test_scoreString_multipleSets() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.startNewSet()
        match.sets[0].gamesPlayer1 = 6
        match.sets[0].gamesPlayer2 = 4
        
        match.startNewSet()
        match.sets[1].gamesPlayer1 = 3
        match.sets[1].gamesPlayer2 = 6
        
        match.startNewSet()
        match.sets[2].gamesPlayer1 = 7
        match.sets[2].gamesPlayer2 = 5
        
        XCTAssertEqual(match.scoreString, "6-4, 3-6, 7-5")
    }
    
    // MARK: - Court Surface
    
    func test_courtSurface_allTypes() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        
        let hardCourtMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        XCTAssertEqual(hardCourtMatch.surface, .hardCourt)
        
        let clayMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .clay)
        XCTAssertEqual(clayMatch.surface, .clay)
        
        let grassMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .grass)
        XCTAssertEqual(grassMatch.surface, .grass)
        
        let carpetMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .carpet)
        XCTAssertEqual(carpetMatch.surface, .carpet)
    }
    
    // MARK: - Match Metadata
    
    func test_matchMetadata_location() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.location = "Wimbledon Centre Court"
        XCTAssertEqual(match.location, "Wimbledon Centre Court")
    }
    
    func test_matchMetadata_notes() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.notes = "Great rally in the third set"
        XCTAssertEqual(match.notes, "Great rally in the third set")
    }
    
    // MARK: - Stats Tracking
    
    func test_matchStats_acesTracking() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.acesPlayer1 = 5
        match.acesPlayer2 = 3
        
        XCTAssertEqual(match.acesPlayer1, 5)
        XCTAssertEqual(match.acesPlayer2, 3)
    }
    
    func test_matchStats_doubleFaultsTracking() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.doubleFaultsPlayer1 = 2
        match.doubleFaultsPlayer2 = 4
        
        XCTAssertEqual(match.doubleFaultsPlayer1, 2)
        XCTAssertEqual(match.doubleFaultsPlayer2, 4)
    }
    
    func test_matchStats_winnersTracking() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.winnersPlayer1 = 15
        match.winnersPlayer2 = 12
        
        XCTAssertEqual(match.winnersPlayer1, 15)
        XCTAssertEqual(match.winnersPlayer2, 12)
    }
    
    func test_matchStats_unforcedErrorsTracking() {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        match.unforcedErrorsPlayer1 = 8
        match.unforcedErrorsPlayer2 = 10
        
        XCTAssertEqual(match.unforcedErrorsPlayer1, 8)
        XCTAssertEqual(match.unforcedErrorsPlayer2, 10)
    }
}
