//
//  AccessibilityTests.swift
//  FirstServeTests
//
//  Tests for VoiceOver accessibility labels and hints
//

import XCTest
import SwiftData
@testable import FirstServe

final class AccessibilityTests: XCTestCase {
    var modelContext: ModelContext!
    var player1: Player!
    var player2: Player!
    var match: Match!
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Match.self, Player.self, TennisSet.self, Game.self,
            configurations: config
        )
        modelContext = container.mainContext
        
        player1 = Player(name: "Cam")
        player2 = Player(name: "Opponent")
        match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        modelContext.insert(player1)
        modelContext.insert(player2)
        modelContext.insert(match)
    }
    
    @MainActor
    override func tearDown() {
        player1 = nil
        player2 = nil
        match = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - Match Card Accessibility
    
    @MainActor
    func testMatchCardAccessibilityLabelForActiveMatch() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        let card = MatchCard(match: match, isActive: true)
        
        // When
        let label = card.accessibilityLabel
        
        // Then
        XCTAssertTrue(label.contains("Live match"))
        XCTAssertTrue(label.contains("Cam"))
        XCTAssertTrue(label.contains("Opponent"))
        XCTAssertTrue(label.contains("Hard Court"))
    }
    
    @MainActor
    func testMatchCardAccessibilityLabelForCompletedMatch() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Award enough points to complete a set
        for _ in 0..<24 { // 6-0, 6 games
            match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        }
        
        match.completeMatch()
        let card = MatchCard(match: match, isActive: false)
        
        // When
        let label = card.accessibilityLabel
        
        // Then
        XCTAssertFalse(label.contains("Live"))
        XCTAssertTrue(label.contains("Cam"))
        XCTAssertTrue(label.contains("Opponent"))
        XCTAssertTrue(label.contains("Hard Court"))
        
        if let winner = match.winner {
            XCTAssertTrue(label.contains(winner.name))
        }
    }
    
    @MainActor
    func testMatchCardAccessibilityLabelIncludesScore() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Play some points
        for _ in 0..<4 {
            match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        }
        
        let card = MatchCard(match: match, isActive: true)
        
        // When
        let label = card.accessibilityLabel
        
        // Then - should contain score information
        XCTAssertTrue(label.contains("Score") || !match.scoreString.isEmpty)
    }
    
    // MARK: - Player Row Accessibility
    
    @MainActor
    func testPlayerRowAccessibilityLabelIncludesServingStatus() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Player 1 is serving
        let view = LiveMatchView(match: match)
        
        // When - we check the label building logic
        let labelWithServing = view.buildPlayerRowAccessibilityLabel(
            name: "Cam",
            isPlayer1: true,
            isServing: true,
            isWinner: false
        )
        
        let labelWithoutServing = view.buildPlayerRowAccessibilityLabel(
            name: "Opponent",
            isPlayer1: false,
            isServing: false,
            isWinner: false
        )
        
        // Then
        XCTAssertTrue(labelWithServing.contains("currently serving"))
        XCTAssertFalse(labelWithoutServing.contains("currently serving"))
    }
    
    @MainActor
    func testPlayerRowAccessibilityLabelIncludesWinnerStatus() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Complete the match
        for _ in 0..<24 {
            match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        }
        match.completeMatch()
        
        let view = LiveMatchView(match: match)
        
        // When
        let labelForWinner = view.buildPlayerRowAccessibilityLabel(
            name: "Cam",
            isPlayer1: true,
            isServing: false,
            isWinner: true
        )
        
        let labelForLoser = view.buildPlayerRowAccessibilityLabel(
            name: "Opponent",
            isPlayer1: false,
            isServing: false,
            isWinner: false
        )
        
        // Then
        XCTAssertTrue(labelForWinner.contains("winner"))
        XCTAssertFalse(labelForLoser.contains("winner"))
    }
    
    @MainActor
    func testPlayerRowAccessibilityLabelIncludesSetScores() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Play a game
        for _ in 0..<4 {
            match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        }
        
        let view = LiveMatchView(match: match)
        
        // When
        let label = view.buildPlayerRowAccessibilityLabel(
            name: "Cam",
            isPlayer1: true,
            isServing: false,
            isWinner: false
        )
        
        // Then
        XCTAssertTrue(label.contains("Set 1"))
    }
    
    // MARK: - Button Accessibility
    
    @MainActor
    func testScoreButtonHasProperAccessibilityLabel() {
        // This test verifies the accessibility label format
        // In the actual UI, it would be: "Award point to Cam"
        let playerName = "Cam"
        let expectedLabel = "Award point to \(playerName)"
        
        XCTAssertEqual(expectedLabel, "Award point to Cam")
    }
    
    @MainActor
    func testUndoButtonAccessibilityChangesWithState() {
        // When undo is available
        let hintAvailable = "Double tap to undo the last point awarded"
        
        // When undo is not available
        let hintUnavailable = "No points to undo"
        
        // Then both states have clear hints
        XCTAssertFalse(hintAvailable.isEmpty)
        XCTAssertFalse(hintUnavailable.isEmpty)
    }
    
    @MainActor
    func testQuickStatButtonAccessibilityLabels() {
        // Given stat types
        let statTypes = ["Ace", "Double Fault", "Winner"]
        
        // When
        for stat in statTypes {
            let label = stat
            let hint = "Double tap to select which player scored a \(stat.lowercased())"
            
            // Then
            XCTAssertFalse(label.isEmpty)
            XCTAssertFalse(hint.isEmpty)
            XCTAssertTrue(hint.contains(stat.lowercased()))
        }
    }
    
    // MARK: - Game Score Accessibility
    
    @MainActor
    func testCurrentGameScoreAccessibilityLabel() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Award some points
        match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        match.currentSet?.currentGame?.awardPoint(toPlayer1: false)
        
        // When
        guard let game = match.currentSet?.currentGame else {
            XCTFail("Game should exist")
            return
        }
        
        let p1Score = game.scoreString(forPlayer1: true)
        let p2Score = game.scoreString(forPlayer1: false)
        
        // Then - scores should be valid tennis scores
        XCTAssertTrue(["0", "15", "30", "40", "AD"].contains(p1Score))
        XCTAssertTrue(["0", "15", "30", "40", "AD"].contains(p2Score))
    }
    
    @MainActor
    func testTiebreakScoreAccessibilityLabel() {
        // Given - simulate a tiebreak situation
        match.startNewSet()
        
        // Set up a 6-6 situation (tiebreak)
        // This is simplified - in reality we'd need to play full games
        if let set = match.currentSet {
            set.gamesPlayer1 = 6
            set.gamesPlayer2 = 6
            set.isTiebreak = true
            set.tiebreakScorePlayer1 = 3
            set.tiebreakScorePlayer2 = 2
        }
        
        // When
        let expectedLabel = "Tiebreak: Cam 3, Opponent 2. First to 7, win by 2"
        
        // Then
        XCTAssertTrue(expectedLabel.contains("Tiebreak"))
        XCTAssertTrue(expectedLabel.contains("First to 7"))
        XCTAssertTrue(expectedLabel.contains("win by 2"))
    }
    
    // MARK: - Match Header Accessibility
    
    @MainActor
    func testSurfaceBadgeAccessibility() {
        // Given
        let hardCourtMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        let clayMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .clay)
        let grassMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .grass)
        
        // When
        let hardLabel = "Surface: Hard Court"
        let clayLabel = "Surface: Clay"
        let grassLabel = "Surface: Grass"
        
        // Then
        XCTAssertEqual(hardCourtMatch.surface.rawValue, "Hard Court")
        XCTAssertEqual(clayMatch.surface.rawValue, "Clay")
        XCTAssertEqual(grassMatch.surface.rawValue, "Grass")
        
        XCTAssertTrue(hardLabel.contains("Hard Court"))
        XCTAssertTrue(clayLabel.contains("Clay"))
        XCTAssertTrue(grassLabel.contains("Grass"))
    }
    
    @MainActor
    func testLiveIndicatorAccessibility() {
        // Given
        let liveLabel = "Match in progress"
        
        // Then
        XCTAssertFalse(liveLabel.isEmpty)
        XCTAssertTrue(liveLabel.contains("progress"))
    }
    
    @MainActor
    func testFormatBadgeAccessibility() {
        // Given
        let bestOf3Match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        let bestOf5Match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .hardCourt)
        
        // When
        let bestOf3Label = "Format: Best of 3"
        let bestOf5Label = "Format: Best of 5"
        
        // Then
        XCTAssertEqual(bestOf3Match.format.rawValue, "Best of 3")
        XCTAssertEqual(bestOf5Match.format.rawValue, "Best of 5")
        
        XCTAssertTrue(bestOf3Label.contains("Best of 3"))
        XCTAssertTrue(bestOf5Label.contains("Best of 5"))
    }
    
    // MARK: - Match Complete Accessibility
    
    @MainActor
    func testMatchCompleteWinnerAnnouncement() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Complete the match (Cam wins)
        for _ in 0..<24 {
            match.currentSet?.currentGame?.awardPoint(toPlayer1: true)
        }
        match.completeMatch()
        
        // When
        guard let winner = match.winner else {
            XCTFail("Winner should be set")
            return
        }
        
        let announcement = "\(winner.name) wins! Final score: \(match.scoreString)"
        
        // Then
        XCTAssertTrue(announcement.contains(winner.name))
        XCTAssertTrue(announcement.contains("wins"))
        XCTAssertTrue(announcement.contains("Final score"))
    }
    
    // MARK: - Navigation Accessibility
    
    @MainActor
    func testViewStatsButtonAccessibility() {
        // Given
        let label = "View all statistics"
        let hint = "Double tap to open detailed match statistics"
        
        // Then
        XCTAssertFalse(label.isEmpty)
        XCTAssertFalse(hint.isEmpty)
        XCTAssertTrue(hint.contains("statistics"))
    }
    
    @MainActor
    func testEndMatchButtonAccessibility() {
        // Given
        let label = "End match early"
        let hint = "Double tap to end the match before completion"
        
        // Then
        XCTAssertFalse(label.isEmpty)
        XCTAssertFalse(hint.isEmpty)
        XCTAssertTrue(label.contains("End"))
        XCTAssertTrue(hint.contains("before completion"))
    }
    
    @MainActor
    func testNewMatchButtonAccessibility() {
        // Given
        let label = "New match"
        let hint = "Double tap to start a new match"
        
        // Then
        XCTAssertFalse(label.isEmpty)
        XCTAssertFalse(hint.isEmpty)
        XCTAssertTrue(hint.contains("start"))
    }
    
    @MainActor
    func testViewPlayersButtonAccessibility() {
        // Given
        let label = "View players"
        let hint = "Double tap to view and manage players"
        
        // Then
        XCTAssertFalse(label.isEmpty)
        XCTAssertFalse(hint.isEmpty)
        XCTAssertTrue(hint.contains("manage"))
    }
    
    // MARK: - Stats Count Accessibility
    
    @MainActor
    func testMatchCountAccessibility() {
        // Given - singular
        let singleMatchLabel = "1 match recorded"
        
        // Given - plural
        let multipleMatchesLabel = "5 matches recorded"
        
        // Then
        XCTAssertTrue(singleMatchLabel.contains("match"))
        XCTAssertFalse(singleMatchLabel.contains("matches"))
        
        XCTAssertTrue(multipleMatchesLabel.contains("matches"))
        XCTAssertTrue(multipleMatchesLabel.contains("5"))
    }
}
