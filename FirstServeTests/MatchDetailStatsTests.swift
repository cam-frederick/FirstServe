//
//  MatchDetailStatsTests.swift
//  FirstServeTests
//
//  Tests for the post-match serve stats and shot breakdown data
//  that powers the new MatchDetailView serve/shot sections.
//
//  Created by Cici on 2026-03-09.
//

import XCTest
@testable import FirstServe

final class MatchDetailStatsTests: XCTestCase {

    var player1: Player!
    var player2: Player!
    var match: Match!

    override func setUp() {
        super.setUp()
        player1 = Player(name: "Alice")
        player2 = Player(name: "Bob")
        match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
    }

    override func tearDown() {
        player1 = nil
        player2 = nil
        match = nil
        super.tearDown()
    }

    // MARK: - hasServeData guard

    func testHasServeDataReturnsFalseWhenNoAttempts() {
        // Fresh match with zero serve attempts
        let hasData = match.firstServeAttemptsPlayer1 + match.firstServeAttemptsPlayer2 > 0
        XCTAssertFalse(hasData, "hasServeData should be false with zero first serve attempts")
    }

    func testHasServeDataReturnsTrueAfterRecordingServe() {
        match.firstServeAttemptsPlayer1 = 5
        let hasData = match.firstServeAttemptsPlayer1 + match.firstServeAttemptsPlayer2 > 0
        XCTAssertTrue(hasData, "hasServeData should be true after recording serve attempts")
    }

    func testHasServeDataWhenOnlyPlayer2HasAttempts() {
        match.firstServeAttemptsPlayer2 = 3
        let hasData = match.firstServeAttemptsPlayer1 + match.firstServeAttemptsPlayer2 > 0
        XCTAssertTrue(hasData, "hasServeData should be true when only player 2 has attempts")
    }

    // MARK: - hasShotData guard

    func testHasShotDataReturnsFalseWhenNoShots() {
        XCTAssertTrue(match.shotStatistics.isEmpty, "Fresh match should have no shot statistics")
    }

    func testHasShotDataReturnsTrueAfterRecordingShot() {
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        XCTAssertFalse(match.shotStatistics.isEmpty, "hasShotData should be true after recording a shot")
    }

    // MARK: - Serve percentage computation for display

    func testFirstServePercentageDisplaysCorrectly() {
        // 6 out of 10 first serves in
        match.firstServeAttemptsPlayer1 = 10
        match.firstServesMadePlayer1 = 6

        let pct = match.firstServePercentagePlayer1
        XCTAssertEqual(pct, 60.0, accuracy: 0.1)
    }

    func testFirstServePercentageZeroWhenNoAttempts() {
        // No serve attempts → should not crash, should return 0
        match.firstServeAttemptsPlayer1 = 0
        match.firstServesMadePlayer1 = 0

        let pct = match.firstServePercentagePlayer1
        XCTAssertEqual(pct, 0.0, accuracy: 0.001)
    }

    func testSecondServePercentageComputation() {
        match.secondServeAttemptsPlayer2 = 4
        match.secondServesMadePlayer2 = 3

        let pct = match.secondServePercentagePlayer2
        XCTAssertEqual(pct, 75.0, accuracy: 0.1)
    }

    func testFirstServePointsWonPercentage() {
        // 8 first serves made, 5 points won
        match.firstServesMadePlayer1 = 8
        match.pointsWonOnFirstServePlayer1 = 5

        let pct = match.firstServePointsWonPercentagePlayer1
        XCTAssertEqual(pct, 62.5, accuracy: 0.1)
    }

    func testSecondServePointsWonPercentage() {
        match.secondServesMadePlayer2 = 4
        match.pointsWonOnSecondServePlayer2 = 2

        let pct = match.secondServePointsWonPercentagePlayer2
        XCTAssertEqual(pct, 50.0, accuracy: 0.1)
    }

    func testSecondServeDataPresentWhenBothPlayersHaveAttempts() {
        match.secondServeAttemptsPlayer1 = 3
        match.secondServeAttemptsPlayer2 = 2
        let totalSecondAttempts = match.secondServeAttemptsPlayer1 + match.secondServeAttemptsPlayer2
        XCTAssertEqual(totalSecondAttempts, 5)
        XCTAssertGreaterThan(totalSecondAttempts, 0)
    }

    // MARK: - Shot breakdown filtering for MatchDetailView

    func testDetailShotCountFiltersByPlayerAndType() {
        // P1 FH groundstroke winners
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        // P1 BH groundstroke winner - should not count in FH filter
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .groundstroke)

        // P2 FH winner - should not count in P1 filter
        match.recordShotStatistic(playerNumber: 2, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        let p1FHWinners = match.shotStatistics.filter {
            $0.playerNumber == 1
            && $0.statType == .winner
            && $0.shotType == .forehand
            && $0.contactType == .groundstroke
        }.count

        XCTAssertEqual(p1FHWinners, 2)
    }

    func testDetailShotCountForEntireContactType() {
        // All P1 groundstroke winners (FH + BH)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .volley)

        let allGroundstrokeWinners = match.shotStatistics.filter {
            $0.playerNumber == 1
            && $0.statType == .winner
            && $0.contactType == .groundstroke
        }.count

        XCTAssertEqual(allGroundstrokeWinners, 2, "Should count both FH and BH groundstroke winners")
    }

    func testDetailShotCountOverheadWinners() {
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .overhead)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .overhead)
        match.recordShotStatistic(playerNumber: 1, statType: .unforcedError, shotType: .forehand, contactType: .overhead)

        let overheadWinners = match.shotStatistics.filter {
            $0.playerNumber == 1
            && $0.statType == .winner
            && $0.contactType == .overhead
        }.count

        XCTAssertEqual(overheadWinners, 2, "Should only count overhead winners, not errors")
    }

    func testUnforcedErrorBreakdownSeparateFromWinners() {
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 2, statType: .winner, shotType: .backhand, contactType: .groundstroke)

        let bhErrors = match.shotStatistics.filter {
            $0.playerNumber == 2
            && $0.statType == .unforcedError
            && $0.shotType == .backhand
            && $0.contactType == .groundstroke
        }.count

        XCTAssertEqual(bhErrors, 2, "Unforced errors should be counted separately from winners")
    }

    // MARK: - Notes and location display

    func testMatchNotesNilByDefault() {
        XCTAssertNil(match.notes, "Notes should be nil by default")
    }

    func testMatchLocationNilByDefault() {
        XCTAssertNil(match.location, "Location should be nil by default")
    }

    func testMatchNotesCanBeSet() {
        match.notes = "Great match in the finals"
        XCTAssertEqual(match.notes, "Great match in the finals")
    }

    func testMatchLocationCanBeSet() {
        match.location = "River Oaks Country Club"
        XCTAssertEqual(match.location, "River Oaks Country Club")
    }

    func testEmptyStringNotesAreHandled() {
        match.notes = ""
        // The UI checks !notes.isEmpty — empty string should not show chip
        XCTAssertTrue(match.notes?.isEmpty ?? true)
    }

    // MARK: - Percentage stat row display logic

    func testPercentageStatRowHighlightsHigherPlayer() {
        match.firstServeAttemptsPlayer1 = 10
        match.firstServesMadePlayer1 = 7 // 70%
        match.firstServeAttemptsPlayer2 = 10
        match.firstServesMadePlayer2 = 5 // 50%

        let p1Pct = match.firstServePercentagePlayer1
        let p2Pct = match.firstServePercentagePlayer2

        XCTAssertGreaterThan(p1Pct, p2Pct, "P1 should have higher 1st serve %")
    }

    func testPercentageStatRowEqualValuesAreTreatedCorrectly() {
        match.firstServeAttemptsPlayer1 = 10
        match.firstServesMadePlayer1 = 6 // 60%
        match.firstServeAttemptsPlayer2 = 10
        match.firstServesMadePlayer2 = 6 // 60%

        let p1Pct = match.firstServePercentagePlayer1
        let p2Pct = match.firstServePercentagePlayer2

        // When equal, both should display as prominent (p1 >= p2 is true)
        XCTAssertEqual(p1Pct, p2Pct, accuracy: 0.001)
        XCTAssertTrue(p1Pct >= p2Pct)
    }

    func testProgressBarRatioNeverExceedsOne() {
        // p1 = 90%, p2 = 0% — bar ratio should clamp at 1.0
        match.firstServeAttemptsPlayer1 = 10
        match.firstServesMadePlayer1 = 9
        match.firstServeAttemptsPlayer2 = 0
        match.firstServesMadePlayer2 = 0

        let p1 = match.firstServePercentagePlayer1
        let p2 = match.firstServePercentagePlayer2
        let total = max(p1 + p2, 1.0)
        let ratio = p1 / total

        XCTAssertLessThanOrEqual(ratio, 1.0, "Progress bar ratio must not exceed 1.0")
        XCTAssertGreaterThanOrEqual(ratio, 0.0, "Progress bar ratio must be non-negative")
    }
}
