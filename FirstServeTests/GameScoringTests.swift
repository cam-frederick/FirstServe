//
//  GameScoringTests.swift
//  FirstServeTests
//
//  Unit tests for tennis scoring logic

import XCTest
import SwiftData

// MARK: - Game Score Tests

final class GameScoringTests: XCTestCase {
    
    // MARK: - Basic Point Progression
    
    func test_freshGame_scoreIs0_0() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        XCTAssertEqual(game.pointsPlayer1, 0)
        XCTAssertEqual(game.pointsPlayer2, 0)
        XCTAssertFalse(game.isComplete)
        XCTAssertNil(game.winner)
    }
    
    func test_scoreString_loveToForty() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        
        XCTAssertEqual(game.scoreString(forPlayer1: true), "0")
        
        game.awardPoint(toPlayer1: true) // 15-0
        XCTAssertEqual(game.scoreString(forPlayer1: true), "15")
        XCTAssertEqual(game.scoreString(forPlayer1: false), "0")
        
        game.awardPoint(toPlayer1: true) // 30-0
        XCTAssertEqual(game.scoreString(forPlayer1: true), "30")
        
        game.awardPoint(toPlayer1: true) // 40-0
        XCTAssertEqual(game.scoreString(forPlayer1: true), "40")
    }
    
    // MARK: - Game Completion
    
    func test_straightGameWin_player1Wins4Points() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.awardPoint(toPlayer1: true)  // 15-0
        game.awardPoint(toPlayer1: true)  // 30-0
        game.awardPoint(toPlayer1: true)  // 40-0
        game.awardPoint(toPlayer1: true)  // Game P1
        
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.winner, 1)
    }
    
    func test_straightGameWin_player2Wins4Points() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.awardPoint(toPlayer1: false) // 0-15
        game.awardPoint(toPlayer1: false) // 0-30
        game.awardPoint(toPlayer1: false) // 0-40
        game.awardPoint(toPlayer1: false) // Game P2
        
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.winner, 2)
    }
    
    // MARK: - Deuce & Advantage
    
    func test_deuce_scoreShows40_40() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        // Reach 40-40 (3 points each)
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 3
        
        XCTAssertFalse(game.isComplete)
        XCTAssertEqual(game.scoreString(forPlayer1: true), "40")
        XCTAssertEqual(game.scoreString(forPlayer1: false), "40")
    }
    
    func test_advantage_showsAD() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.pointsPlayer1 = 4  // AD-40
        game.pointsPlayer2 = 3
        
        XCTAssertFalse(game.isComplete)
        XCTAssertEqual(game.scoreString(forPlayer1: true), "AD")
        XCTAssertEqual(game.scoreString(forPlayer1: false), "40")
    }
    
    func test_advantage_backToDeuce() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.pointsPlayer1 = 4  // AD-40
        game.pointsPlayer2 = 3
        
        game.awardPoint(toPlayer1: false) // Back to deuce (4-4)
        XCTAssertFalse(game.isComplete)
        XCTAssertEqual(game.scoreString(forPlayer1: true), "40")
        XCTAssertEqual(game.scoreString(forPlayer1: false), "40")
    }
    
    func test_advantage_convertToGameWin() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.pointsPlayer1 = 4  // AD-40
        game.pointsPlayer2 = 3
        
        game.awardPoint(toPlayer1: true) // Win (5-3)
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.winner, 1)
    }
    
    func test_extendedDeuce_multipleRounds() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        // Deuce at 3-3
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 3
        
        game.awardPoint(toPlayer1: true)  // AD P1 (4-3)
        game.awardPoint(toPlayer1: false) // Deuce (4-4)
        game.awardPoint(toPlayer1: false) // AD P2 (4-5)
        game.awardPoint(toPlayer1: true)  // Deuce (5-5)
        game.awardPoint(toPlayer1: true)  // AD P1 (6-5)
        game.awardPoint(toPlayer1: true)  // Game P1 (7-5)
        
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.winner, 1)
    }
    
    // MARK: - Edge Cases
    
    func test_game_notCompleteAt3Points() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 0
        XCTAssertFalse(game.isComplete)
    }
    
    func test_game_notCompleteAt4_3() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        game.pointsPlayer1 = 4
        game.pointsPlayer2 = 3
        XCTAssertFalse(game.isComplete) // Need win by 2
    }
    
    func test_completedAt_setOnGameWin() {
        let game = Game(gameNumber: 1, serverIsPlayer1: true)
        XCTAssertNil(game.completedAt)
        
        game.pointsPlayer1 = 3
        game.pointsPlayer2 = 0
        game.awardPoint(toPlayer1: true) // 4-0, game over
        
        XCTAssertNotNil(game.completedAt)
    }
}

// MARK: - Set Scoring Tests

final class SetScoringTests: XCTestCase {
    
    func test_freshSet_scoresAreZero() {
        let set = TennisSet(setNumber: 1)
        XCTAssertEqual(set.gamesPlayer1, 0)
        XCTAssertEqual(set.gamesPlayer2, 0)
        XCTAssertFalse(set.isComplete)
        XCTAssertFalse(set.isTiebreak)
    }
    
    func test_set_completeAt6_4() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 4
        XCTAssertTrue(set.isComplete)
    }
    
    func test_set_completeAt6_3() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 3
        XCTAssertTrue(set.isComplete)
    }
    
    func test_set_notCompleteAt6_5() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 5
        XCTAssertFalse(set.isComplete) // Need 2-game lead or tiebreak
    }
    
    func test_set_completeAt7_5() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 5
        XCTAssertTrue(set.isComplete)
    }
    
    func test_set_tiebreakAt6_6() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 6
        set.gamesPlayer2 = 6
        XCTAssertTrue(set.isTiebreak)
        XCTAssertFalse(set.isComplete) // Not complete until tiebreak is won
    }
    
    func test_set_completeAt7_6_tiebreakWon() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 7
        set.gamesPlayer2 = 6
        // 7-6 means tiebreak was won by player 1
        XCTAssertTrue(set.isComplete)
    }
    
    func test_awardGame_incrementsCorrectly() {
        let set = TennisSet(setNumber: 1)
        set.awardGame(toPlayer1: true)
        XCTAssertEqual(set.gamesPlayer1, 1)
        XCTAssertEqual(set.gamesPlayer2, 0)
        
        set.awardGame(toPlayer1: false)
        XCTAssertEqual(set.gamesPlayer1, 1)
        XCTAssertEqual(set.gamesPlayer2, 1)
    }
    
    func test_awardGame_setsCompletedAt() {
        let set = TennisSet(setNumber: 1)
        set.gamesPlayer1 = 5
        set.gamesPlayer2 = 3
        XCTAssertNil(set.completedAt)
        
        set.awardGame(toPlayer1: true) // 6-3, set complete
        XCTAssertNotNil(set.completedAt)
    }
    
    func test_startNewGame_appendsGame() {
        let set = TennisSet(setNumber: 1)
        XCTAssertEqual(set.games.count, 0)
        
        set.startNewGame(serverIsPlayer1: true)
        XCTAssertEqual(set.games.count, 1)
        XCTAssertTrue(set.games[0].serverIsPlayer1)
        
        set.startNewGame(serverIsPlayer1: false)
        XCTAssertEqual(set.games.count, 2)
        XCTAssertFalse(set.games[1].serverIsPlayer1)
    }
    
    func test_currentGame_returnsLastIncompleteGame() {
        let set = TennisSet(setNumber: 1)
        XCTAssertNil(set.currentGame)
        
        set.startNewGame(serverIsPlayer1: true)
        XCTAssertNotNil(set.currentGame)
        XCTAssertEqual(set.currentGame?.gameNumber, 1)
        
        // Complete the game
        set.currentGame?.pointsPlayer1 = 4
        set.currentGame?.pointsPlayer2 = 0
        // Game is now complete
        
        set.startNewGame(serverIsPlayer1: false)
        XCTAssertEqual(set.currentGame?.gameNumber, 2)
    }
}

// MARK: - Match Level Tests

final class MatchScoringTests: XCTestCase {
    
    func test_match_notCompleteInitially() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        XCTAssertFalse(match.isComplete)
        XCTAssertNil(match.winner)
    }
    
    func test_match_bestOf3_completeAfter2Sets() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        // Simulate 2 completed sets won by player 1
        let set1 = TennisSet(setNumber: 1)
        set1.gamesPlayer1 = 6
        set1.gamesPlayer2 = 3
        set1.completedAt = Date()
        match.sets.append(set1)
        
        XCTAssertFalse(match.isComplete) // Only 1 set
        
        let set2 = TennisSet(setNumber: 2)
        set2.gamesPlayer1 = 6
        set2.gamesPlayer2 = 4
        set2.completedAt = Date()
        match.sets.append(set2)
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    func test_match_bestOf3_player2Wins() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        let set1 = TennisSet(setNumber: 1)
        set1.gamesPlayer1 = 3
        set1.gamesPlayer2 = 6
        set1.completedAt = Date()
        match.sets.append(set1)
        
        let set2 = TennisSet(setNumber: 2)
        set2.gamesPlayer1 = 2
        set2.gamesPlayer2 = 6
        set2.completedAt = Date()
        match.sets.append(set2)
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Bob")
    }
    
    func test_match_bestOf3_goesTo3Sets() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        // Set 1: P1 wins
        let set1 = TennisSet(setNumber: 1)
        set1.gamesPlayer1 = 6
        set1.gamesPlayer2 = 4
        set1.completedAt = Date()
        match.sets.append(set1)
        
        // Set 2: P2 wins
        let set2 = TennisSet(setNumber: 2)
        set2.gamesPlayer1 = 3
        set2.gamesPlayer2 = 6
        set2.completedAt = Date()
        match.sets.append(set2)
        
        XCTAssertFalse(match.isComplete) // 1-1 in sets
        
        // Set 3: P1 wins
        let set3 = TennisSet(setNumber: 3)
        set3.gamesPlayer1 = 7
        set3.gamesPlayer2 = 5
        set3.completedAt = Date()
        match.sets.append(set3)
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    func test_match_bestOf5_requires3Sets() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf5, surface: .hardCourt)
        
        // 2 sets won by P1
        for i in 1...2 {
            let set = TennisSet(setNumber: i)
            set.gamesPlayer1 = 6
            set.gamesPlayer2 = 3
            set.completedAt = Date()
            match.sets.append(set)
        }
        
        XCTAssertFalse(match.isComplete) // Only 2 of 3 needed
        
        // 3rd set won by P1
        let set3 = TennisSet(setNumber: 3)
        set3.gamesPlayer1 = 6
        set3.gamesPlayer2 = 2
        set3.completedAt = Date()
        match.sets.append(set3)
        
        XCTAssertTrue(match.isComplete)
        XCTAssertEqual(match.winner?.name, "Alice")
    }
    
    func test_match_scoreString() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        let set1 = TennisSet(setNumber: 1)
        set1.gamesPlayer1 = 6
        set1.gamesPlayer2 = 4
        match.sets.append(set1)
        
        let set2 = TennisSet(setNumber: 2)
        set2.gamesPlayer1 = 3
        set2.gamesPlayer2 = 6
        match.sets.append(set2)
        
        XCTAssertEqual(match.scoreString, "6-4, 3-6")
    }
    
    func test_match_currentSet_returnsLastIncomplete() {
        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        XCTAssertNil(match.currentSet)
        
        match.startNewSet()
        XCTAssertEqual(match.currentSet?.setNumber, 1)
        XCTAssertEqual(match.sets.count, 1)
    }
}

// MARK: - MatchViewModel Integration Tests (with in-memory SwiftData)

@MainActor
final class MatchViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: MatchViewModel!
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Match.self, Player.self, TennisSet.self, Game.self, configurations: config)
        context = container.mainContext
        viewModel = MatchViewModel()
        viewModel.configure(context: context)
    }
    
    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Match Creation
    
    func test_startNewMatch_createsMatchWithPlayers() {
        viewModel.startNewMatch(
            player1Name: "Cam",
            player2Name: "Jake",
            format: .bestOf3,
            surface: .hardCourt,
            player1ServesFirst: true
        )
        
        XCTAssertNotNil(viewModel.currentMatch)
        XCTAssertEqual(viewModel.currentMatch?.players.count, 2)
        // SwiftData @Relationship doesn't guarantee insertion order on read-back
        let names = Set(viewModel.currentMatch?.players.map { $0.name } ?? [])
        XCTAssertTrue(names.contains("Cam"))
        XCTAssertTrue(names.contains("Jake"))
        XCTAssertEqual(viewModel.currentMatch?.format, .bestOf3)
        XCTAssertEqual(viewModel.currentMatch?.surface, .hardCourt)
    }
    
    func test_startNewMatch_startsFirstSet() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        XCTAssertEqual(viewModel.currentMatch?.sets.count, 1)
        XCTAssertNotNil(viewModel.currentMatch?.currentSet)
    }
    
    func test_startNewMatch_startsFirstGame() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt, player1ServesFirst: true)
        
        XCTAssertNotNil(viewModel.currentMatch?.currentSet?.currentGame)
        XCTAssertTrue(viewModel.currentMatch?.currentSet?.currentGame?.serverIsPlayer1 ?? false)
    }
    
    // MARK: - Point Scoring
    
    func test_awardPoint_incrementsScore() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.awardPoint(toPlayer1: true)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer1, 1)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer2, 0)
    }
    
    func test_awardPoint_completesGame() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        // Award 4 points to player 1 (straight game)
        for _ in 0..<4 {
            viewModel.awardPoint(toPlayer1: true)
        }
        
        // Game should be complete, new game started
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.gamesPlayer1, 1)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.gamesPlayer2, 0)
        // New game should have started
        XCTAssertNotNil(viewModel.currentMatch?.currentSet?.currentGame)
        XCTAssertFalse(viewModel.currentMatch?.currentSet?.currentGame?.isComplete ?? true)
    }
    
    func test_awardPoint_alternatesServer() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt, player1ServesFirst: true)
        
        let initialServer = viewModel.currentMatch?.currentSet?.currentGame?.serverIsPlayer1 ?? false
        XCTAssertTrue(initialServer) // P1 serves first
        
        // Complete a game (4 points to P1)
        for _ in 0..<4 {
            viewModel.awardPoint(toPlayer1: true)
        }
        
        // Next game should have opposite server
        let nextServer = viewModel.currentMatch?.currentSet?.currentGame?.serverIsPlayer1 ?? true
        XCTAssertFalse(nextServer) // P2 serves next
    }
    
    // MARK: - Undo
    
    func test_undo_restoresLastPoint() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.awardPoint(toPlayer1: true) // 15-0
        XCTAssertTrue(viewModel.canUndo)
        
        viewModel.undoLastPoint() // Back to 0-0
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer1, 0)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer2, 0)
    }
    
    func test_undo_multiplePoints() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.awardPoint(toPlayer1: true)  // 15-0
        viewModel.awardPoint(toPlayer1: false) // 15-15
        viewModel.awardPoint(toPlayer1: true)  // 30-15
        
        viewModel.undoLastPoint() // 15-15
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer1, 1)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer2, 1)
        
        viewModel.undoLastPoint() // 15-0
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer1, 1)
        XCTAssertEqual(viewModel.currentMatch?.currentSet?.currentGame?.pointsPlayer2, 0)
    }
    
    func test_undo_emptyStack_canUndoFalse() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        XCTAssertFalse(viewModel.canUndo)
    }
    
    // MARK: - Stats Recording
    
    func test_recordAce_incrementsCount() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.recordAce(player1: true)
        XCTAssertEqual(viewModel.currentMatch?.acesPlayer1, 1)
        XCTAssertEqual(viewModel.currentMatch?.acesPlayer2, 0)
        
        viewModel.recordAce(player1: false)
        XCTAssertEqual(viewModel.currentMatch?.acesPlayer2, 1)
    }
    
    func test_recordDoubleFault_incrementsCount() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.recordDoubleFault(player1: true)
        XCTAssertEqual(viewModel.currentMatch?.doubleFaultsPlayer1, 1)
    }
    
    func test_recordWinner_incrementsCount() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        viewModel.recordWinner(player1: true)
        XCTAssertEqual(viewModel.currentMatch?.winnersPlayer1, 1)
    }
    
    // MARK: - Full Game Scenario
    
    func test_fullGame_p1WinsStraight() {
        viewModel.startNewMatch(player1Name: "Cam", player2Name: "Jake", format: .bestOf3, surface: .hardCourt)
        
        // P1 wins 6 straight games (6-0 set)
        for _ in 0..<6 {
            // Each game: P1 wins 4 points
            for _ in 0..<4 {
                viewModel.awardPoint(toPlayer1: true)
            }
        }
        
        // Set 1 should be complete (6-0)
        XCTAssertEqual(viewModel.currentMatch?.sets.count, 2) // New set started
        XCTAssertEqual(viewModel.currentMatch?.sets[0].gamesPlayer1, 6)
        XCTAssertEqual(viewModel.currentMatch?.sets[0].gamesPlayer2, 0)
        XCTAssertTrue(viewModel.currentMatch?.sets[0].isComplete ?? false)
    }
}

// End of tests
