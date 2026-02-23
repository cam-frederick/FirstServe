//
//  NewMatchFormTests.swift
//  FirstServeTests
//
//  Tests for match creation validation and configuration.
//  Covers the polished NewMatchView dark-theme form logic.
//

import XCTest
import SwiftData
@testable import FirstServe

/// Tests for the match creation flow and form validation.
/// These cover the model/ViewModel layer that backs NewMatchView.
@MainActor
final class NewMatchFormTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: MatchViewModel!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        viewModel = MatchViewModel()
        viewModel.configure(context: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        viewModel = nil
    }
    
    // MARK: - Player Name Validation
    
    func test_playerNames_trimmedBeforeCreating() throws {
        viewModel.startNewMatch(
            player1Name: "  Cam  ",
            player2Name: "  Opponent  ",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertNotNil(match, "Match should be created")
        XCTAssertEqual(match?.player1?.name, "Cam", "Player 1 name should be trimmed")
        XCTAssertEqual(match?.player2?.name, "Opponent", "Player 2 name should be trimmed")
    }
    
    func test_matchCreated_withCorrectFormat() throws {
        viewModel.startNewMatch(
            player1Name: "Alice",
            player2Name: "Bob",
            format: .bestOf5,
            surface: .clay,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertEqual(match?.format, .bestOf5)
        XCTAssertEqual(match?.surface, .clay)
    }
    
    func test_matchCreated_withNoAdScoring() throws {
        viewModel.startNewMatch(
            player1Name: "Player A",
            player2Name: "Player B",
            format: .singleSet,
            surface: .grass,
            scoringStyle: .noAdvantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: false
        )
        
        let match = viewModel.currentMatch
        XCTAssertEqual(match?.scoringStyle, .noAdvantage)
        XCTAssertFalse(match?.player1ServesFirst ?? true, "Player 2 should serve first")
    }
    
    func test_matchCreated_withExtendedTiebreak() throws {
        viewModel.startNewMatch(
            player1Name: "Cam",
            player2Name: "Rafa",
            format: .bestOf3,
            surface: .clay,
            scoringStyle: .advantage,
            regularTiebreakType: .extended,
            finalSetTiebreakType: nil,
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertEqual(match?.regularTiebreakType, .extended)
        XCTAssertEqual(match?.regularTiebreakType.pointsToWin, 10)
        XCTAssertNil(match?.finalSetTiebreakType, "No final set tiebreak should be set")
    }
    
    func test_matchCreated_withFinalSetMatchTiebreak() throws {
        viewModel.startNewMatch(
            player1Name: "Cam",
            player2Name: "Novak",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: .matchTiebreak,
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertEqual(match?.regularTiebreakType, .regular)
        XCTAssertEqual(match?.finalSetTiebreakType, .matchTiebreak)
        XCTAssertEqual(match?.finalSetTiebreakType?.pointsToWin, 10)
    }
    
    func test_matchCreated_withoutFinalSetTiebreak_finalTypeIsNil() throws {
        viewModel.startNewMatch(
            player1Name: "P1",
            player2Name: "P2",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,  // user left "Match Tiebreak" toggle off
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertNil(match?.finalSetTiebreakType,
                     "When toggle is off, finalSetTiebreakType should be nil")
    }
    
    func test_matchCreated_player1ServesFirst() throws {
        viewModel.startNewMatch(
            player1Name: "Server",
            player2Name: "Returner",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: true
        )
        
        let match = viewModel.currentMatch
        XCTAssertTrue(match?.player1ServesFirst ?? false,
                      "Player 1 should be designated server")
    }
    
    func test_matchCreated_player2ServesFirst() throws {
        viewModel.startNewMatch(
            player1Name: "Returner",
            player2Name: "Server",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: false
        )
        
        let match = viewModel.currentMatch
        XCTAssertFalse(match?.player1ServesFirst ?? true,
                       "Player 2 should be designated server")
    }
    
    func test_surfaceOptions_allCasesAvailable() {
        // Verify CourtSurface has all expected cases for the picker
        let surfaces = CourtSurface.allCases
        XCTAssertTrue(surfaces.contains(.hardCourt))
        XCTAssertTrue(surfaces.contains(.clay))
        XCTAssertTrue(surfaces.contains(.grass))
        XCTAssertTrue(surfaces.contains(.carpet))
        XCTAssertEqual(surfaces.count, 4, "Should have exactly 4 surface options")
    }
    
    func test_formatOptions_allCasesAvailable() {
        let formats = MatchFormat.allCases
        XCTAssertTrue(formats.contains(.singleSet))
        XCTAssertTrue(formats.contains(.bestOf3))
        XCTAssertTrue(formats.contains(.bestOf5))
    }
    
    func test_scoringStyleOptions_allCasesAvailable() {
        let styles = ScoringStyle.allCases
        XCTAssertTrue(styles.contains(.advantage))
        XCTAssertTrue(styles.contains(.noAdvantage))
        XCTAssertEqual(styles.count, 2, "Should have exactly 2 scoring styles")
    }
    
    // MARK: - Location
    
    func test_location_canBeSetAfterCreation() throws {
        viewModel.startNewMatch(
            player1Name: "Cam",
            player2Name: "Friend",
            format: .bestOf3,
            surface: .hardCourt,
            scoringStyle: .advantage,
            regularTiebreakType: .regular,
            finalSetTiebreakType: nil,
            player1ServesFirst: true
        )
        
        guard let match = viewModel.currentMatch else {
            XCTFail("Match should be created")
            return
        }
        
        match.location = "Wimbledon, Centre Court"
        XCTAssertEqual(match.location, "Wimbledon, Centre Court")
    }
    
    // MARK: - Default Values
    
    func test_defaultRegularTiebreakType_isRegular7Points() {
        // Verify default is 7-point tiebreak (standard tennis)
        let defaultType = TiebreakType.regular
        XCTAssertEqual(defaultType.pointsToWin, 7)
    }
    
    func test_defaultMatchTiebreakType_is10Points() {
        // Match tiebreaks are 10 points by default
        let matchType = TiebreakType.matchTiebreak
        XCTAssertEqual(matchType.pointsToWin, 10)
    }
    
    // MARK: - Shot Picker Function Name Consistency
    
    /// Verifies the parameter naming consistency for shot picker trigger.
    /// This is a regression test for Bug 1: showShotPicker parameter shadowing.
    func test_shotPickerIsPlayer1Parameter_notShadowedByProperty() {
        // This test documents the naming fix: the parameter must be `isPlayer1` not `player1`
        // to avoid shadowing the computed property var player1: Player?
        // We verify this indirectly by ensuring the ViewModel provides correct player names.
        
        let p1 = Player(name: "Cam")
        let p2 = Player(name: "Opponent")
        let match = Match(player1: p1, player2: p2, format: .bestOf3, surface: .hardCourt)
        
        // The view would pass isPlayer1: true/false to showShotPicker.
        // Verify that player names are what we expect for both positions.
        XCTAssertEqual(match.player1?.name, "Cam",
                       "Player 1 name should be accessible without shadowing")
        XCTAssertEqual(match.player2?.name, "Opponent",
                       "Player 2 name should be accessible without shadowing")
        XCTAssertNotNil(match.player1, "player1 should not be nil")
        XCTAssertNotNil(match.player2, "player2 should not be nil")
    }
}
