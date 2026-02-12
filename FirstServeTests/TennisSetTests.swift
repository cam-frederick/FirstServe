//
//  TennisSetTests.swift
//  FirstServeTests
//
//  Unit tests for TennisSet model and set-level scoring logic
//

import XCTest
import SwiftData

final class TennisSetTests: XCTestCase {
    
    // MARK: - Set Initialization
    
    func test_newSet_hasCorrectInitialState() {
        let set = TennisSet(setNumber: 1)
        
        XCTAssertEqual(set.setNumber, 1)
        XCTAssertEqual(set.gamesPlayer1, 0)
        XCTAssertEqual(set.gamesPlayer2, 0)
        XCTAssertEqual(set.games.count, 0)
        XCTAssertFalse(set.isComplete)
        XCTAssertFalse(set.isTiebreak)
        XCTAssertNil(set.tiebreakScorePlayer1)
        XCTAssertNil(set.tiebreakScorePlayer2)
        XCTAssertNil(set.completedAt)
    }
    
    func test_newSet_withDifferentSetNumbers() {
        let set1 = TennisSet(setNumber: 1)
        let set2 = TennisSet(setNumber: 2)
        let set3 = TennisSet(setNumber: 3)
        
        XCTAssertEqual(set1.setNumber, 1)
        XCTAssertEqual(set2.setNumber, 2)
        XCTAssertEqual(set3.setNumber, 3)
    }
    
    // MARK: - Game Management
    
    func test_startNewGame_addsGameToSet() {
        let set = TennisSet(setNumber: 1)
        set.startNewGame(serverIsPlayer1: true)
        
        XCTAssertEqual(set.games.count, 1)
        XCTAssertEqual(set.games.first?.gameNumber, 1)
        XCTAssertTrue(set.games.first?.serverIsPlayer1 ?? false)
    }
    
    func test_startNewGame_multipleGames() {
        let set = TennisSet(setNumber: 1)
        set.startNewGame(serverIsPlayer1: true)
        set.startNewGame(serverIsPlayer1: false)
        set.startNewGame(serverIsPlayer1: true)
        
        XCTAssertEqual(set.games.count, 3)
        XCTAssertEqual(set.games[0].gameNumber, 1)
        XCTAssertEqual(set.games[1].gameNumber, 2)
        XCTAssertEqual(set.games[2].gameNumber, 3)
    }
    
    func test_startNewGame_alternatingServer() {
        let set = TennisSet(setNumber: 1)
        set.startNewGame(serverIsPlayer1: true)
        set.startNewGame(serverIsPlayer1: false)
        
        XCTAssertTrue(set.games[0].serverIsPlayer1)
        XCTAssertFalse(set.games[1].serverIsPlayer1)
    }
    
    func test_currentGame_returnsLastIncompleteGame() {
        let set = TennisSet(setNumber: 1)
        set.startNewGame(serverIsPlayer1: true)
        
        XCTAssertNotNil(set.currentGame)
        XCTAssertEqual(set.currentGame?.gameNumber, 1)
    }
    
    func test_currentGame_nilWhenNoGames() {
        let set = TennisSet(setNumber: 1)
        
        XCTAssertNil(set.currentGame)
    }
    
    func test_currentGame_nilWhenAllGamesComplete() {
        let set = TennisSet(setNumber: 1)
        set.startNewGame(serverIsPlayer1: true)
        let game = set.games.first!
        game.pointsPlayer1 = 4  // Game won by player 1
        
        XCTAssertNil(set.currentGame)
    }
    
    // MARK: - Award Game
    
    func test_awardGame_incrementsPlayer1Score() {
        let set = TennisSet(setNumber: 1)
        set.awardGame(toPlayer1: true)
        
        XCTAssertEqual(set.gamesPlayer1, 1)
        XCTAssertEqual(set.gamesPlayer2, 0)
    }
    
    func test_awardGame_incrementsPlayer2Score() {
        let set = TennisSet(setNumber: 1)
        set.awardGame(toPlayer1: false)
        
        XCTAssertEqual(set.gamesPlayer1, 0)
        XCTAssertEqual(set.gamesPlayer2, 1)
    }
    
    func test_awardGame_multipleGames() {
        let set = TennisSet(setNumber: 1)
        set.awardGame(toPlayer1: true)
        set.awardGame(toPlayer1: true)
        set.awardGame(toPlayer1: false)
        set.awardGame(toPlayer1: true)
        
        XCTAssertEqual(set.gamesPlayer1, 3)
        XCTAssertEqual(set.gamesPlayer2, 1)
    }
    
    // MARK: - Set Completion (Standard)
    
    func test_setComplete_player1Wins6_0() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 0
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_player1Wins6_4() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 4
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_player2Wins6_3() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 3
        set.gamesPlayer2 = 6
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_player1Wins6_2() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 2
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_player2Wins6_1() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 1
        set.gamesPlayer2 = 6
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setNotComplete_6_5_needsTwoGameLead() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 5
        
        XCTAssertFalse(set.isComplete)
    }
    
    func test_setNotComplete_5_6_needsTwoGameLead() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 6
        
        XCTAssertFalse(set.isComplete)
    }
    
    func test_setComplete_7_5_withTwoGameLead() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 5
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_5_7_withTwoGameLead() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 7
        
        XCTAssertTrue(set.isComplete)
    }
    
    // MARK: - Tiebreak
    
    func test_isTiebreak_trueAt6_6() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 6
        
        XCTAssertTrue(set.isTiebreak)
    }
    
    func test_isTiebreak_falseBelow6_6() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 6
        
        XCTAssertFalse(set.isTiebreak)
    }
    
    func test_isTiebreak_falseAfterTiebreak() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 6
        
        XCTAssertFalse(set.isTiebreak)
    }
    
    func test_setComplete_player1WinsTiebreak7_6() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 6
        set.tiebreakScorePlayer1 = 7
        set.tiebreakScorePlayer2 = 5
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_player2WinsTiebreak6_7() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 7
        set.tiebreakScorePlayer1 = 5
        set.tiebreakScorePlayer2 = 7
        
        XCTAssertTrue(set.isComplete)
    }
    
    // MARK: - Set Completion Timestamp
    
    func test_awardGame_setsCompletedAt_whenSetEnds() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 4
        
        XCTAssertNil(set.completedAt)
        
        set.awardGame(toPlayer1: true) // Now 6-4, set complete
        
        XCTAssertNotNil(set.completedAt)
    }
    
    func test_awardGame_doesNotSetCompletedAt_whenSetOngoing() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 3
        set.gamesPlayer2 = 2
        
        set.awardGame(toPlayer1: true) // Now 4-2, still ongoing
        
        XCTAssertNil(set.completedAt)
    }
    
    // MARK: - Edge Cases
    
    func test_setNotComplete_5_5() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 5
        
        XCTAssertFalse(set.isComplete)
    }
    
    func test_setNotComplete_4_4() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 4
        set.gamesPlayer2 = 4
        
        XCTAssertFalse(set.isComplete)
    }
    
    func test_setNotComplete_0_0() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 0
        set.gamesPlayer2 = 0
        
        XCTAssertFalse(set.isComplete)
    }
    
    func test_setComplete_8_6_afterExtendedPlay() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 8
        set.gamesPlayer2 = 6
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setComplete_6_8_afterExtendedPlay() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 8
        
        XCTAssertTrue(set.isComplete)
    }
    
    func test_setNotComplete_7_7_impossibleButTestLogic() {
        // Note: 7-7 shouldn't happen in real tennis (tiebreak at 6-6),
        // but testing the logic that requires 2-game lead
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 7
        
        XCTAssertFalse(set.isComplete)
    }
    
    // MARK: - Tiebreak Scoring
    
    func test_tiebreakScores_canBeSet() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 6
        set.tiebreakScorePlayer1 = 7
        set.tiebreakScorePlayer2 = 5
        
        XCTAssertEqual(set.tiebreakScorePlayer1, 7)
        XCTAssertEqual(set.tiebreakScorePlayer2, 5)
    }
    
    func test_tiebreakScores_initiallyNil() {
        let set = TennisSet(setNumber: 1)
        
        XCTAssertNil(set.tiebreakScorePlayer1)
        XCTAssertNil(set.tiebreakScorePlayer2)
    }
    
    func test_tiebreakScores_player1WinsCloseTiebreak() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 6
        set.tiebreakScorePlayer1 = 10
        set.tiebreakScorePlayer2 = 8
        
        XCTAssertEqual(set.tiebreakScorePlayer1, 10)
        XCTAssertEqual(set.tiebreakScorePlayer2, 8)
        XCTAssertTrue(set.isComplete)
    }
    
    func test_tiebreakScores_player2WinsDominantTiebreak() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 7
        set.tiebreakScorePlayer1 = 2
        set.tiebreakScorePlayer2 = 7
        
        XCTAssertEqual(set.tiebreakScorePlayer1, 2)
        XCTAssertEqual(set.tiebreakScorePlayer2, 7)
        XCTAssertTrue(set.isComplete)
    }
    
    // MARK: - Set Number
    
    func test_setNumber_canBeAnyInteger() {
        let set1 = TennisSet(setNumber: 1)
        let set5 = TennisSet(setNumber: 5)
        let set10 = TennisSet(setNumber: 10)
        
        XCTAssertEqual(set1.setNumber, 1)
        XCTAssertEqual(set5.setNumber, 5)
        XCTAssertEqual(set10.setNumber, 10)
    }
}
