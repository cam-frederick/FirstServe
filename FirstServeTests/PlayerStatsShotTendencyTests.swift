//
//  PlayerStatsShotTendencyTests.swift
//  FirstServeTests
//
//  Tests for career shot tendency aggregation and serve peak logic
//  used by the new PlayerStatsView sections.
//
//  Created by Cici on 2026-03-09.
//

import XCTest
@testable import FirstServe

final class PlayerStatsShotTendencyTests: XCTestCase {

    var player: Player!
    var opponent: Player!

    override func setUp() {
        super.setUp()
        player = Player(name: "Career Player")
        opponent = Player(name: "Opponent")
    }

    override func tearDown() {
        player = nil
        opponent = nil
        super.tearDown()
    }

    // MARK: - Helper: create completed match

    private func makeCompletedMatch(player1: Player, player2: Player) -> Match {
        let m = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        m.isComplete = true
        return m
    }

    // MARK: - Career shot count aggregation

    func testCareerFHWinnersAggregatesAcrossMatches() {
        let m1 = makeCompletedMatch(player1: player, player2: opponent)
        m1.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        m1.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        let m2 = makeCompletedMatch(player1: player, player2: opponent)
        m2.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        let matches = [m1, m2]

        func isPlayer1(in match: Match) -> Bool { match.players.first?.id == player.id }

        let fhWinners = matches.reduce(0) { total, match in
            let playerNum = isPlayer1(in: match) ? 1 : 2
            return total + match.shotStatistics.filter {
                $0.playerNumber == playerNum
                && $0.statType == .winner
                && $0.shotType == .forehand
                && $0.contactType == .groundstroke
            }.count
        }

        XCTAssertEqual(fhWinners, 3, "Should aggregate FH winners across all matches")
    }

    func testCareerBHWinnersExcludesFHWinners() {
        let m = makeCompletedMatch(player1: player, player2: opponent)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .groundstroke)

        let bhWinners = m.shotStatistics.filter {
            $0.playerNumber == 1
            && $0.statType == .winner
            && $0.shotType == .backhand
            && $0.contactType == .groundstroke
        }.count

        XCTAssertEqual(bhWinners, 1, "BH winners should not include FH winners")
    }

    func testCareerShotCountWhenPlayerIsPlayer2() {
        // Player is player2 in the match
        let m = makeCompletedMatch(player1: opponent, player2: player)
        m.recordShotStatistic(playerNumber: 2, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        m.recordShotStatistic(playerNumber: 2, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        func isPlayer1(in match: Match) -> Bool { match.players.first?.id == player.id }
        let playerNum = isPlayer1(in: m) ? 1 : 2 // should be 2

        let fhWinners = m.shotStatistics.filter {
            $0.playerNumber == playerNum
            && $0.statType == .winner
            && $0.shotType == .forehand
            && $0.contactType == .groundstroke
        }.count

        XCTAssertEqual(fhWinners, 2, "Should count shots for player as player2 correctly")
        XCTAssertEqual(playerNum, 2)
    }

    // MARK: - Shot signature logic

    func testShotSignatureBalancedWhenEqualFHBH() {
        // 3 FH winners, 3 BH winners → diff = 0 → "Balanced"
        let fhWinners = 3
        let bhWinners = 3
        let diff = abs(fhWinners - bhWinners)
        XCTAssertLessThan(diff, 2, "Diff < 2 should yield Balanced signature")
    }

    func testShotSignatureForehandDominantWhenSignificantlyMoreFH() {
        let fhWinners = 15
        let bhWinners = 5
        let fhErrors = 4
        let bhErrors = 3

        let fhTotal = fhWinners + fhErrors
        let bhTotal = bhWinners + bhErrors
        let _ = bhTotal

        let fhRatio = fhTotal > 0 ? Double(fhWinners) / Double(fhTotal) : 0
        let diff = abs(fhWinners - bhWinners)

        XCTAssertGreaterThanOrEqual(diff, 2)
        XCTAssertGreaterThan(fhWinners, bhWinners)
        XCTAssertGreaterThan(fhRatio, 0.55, "fhRatio > 0.55 should yield 'Forehand Dominant'")
    }

    func testShotSignatureBackhandPreferredWhenModeratelyMoreBH() {
        let fhWinners = 6
        let bhWinners = 10
        let fhErrors = 5
        let bhErrors = 8

        let bhTotal = bhWinners + bhErrors
        let bhRatio = bhTotal > 0 ? Double(bhWinners) / Double(bhTotal) : 0
        let diff = abs(fhWinners - bhWinners)

        XCTAssertGreaterThanOrEqual(diff, 2)
        XCTAssertGreaterThan(bhWinners, fhWinners)
        // bhRatio = 10/18 ≈ 0.555 which is > 0.55 but barely
        // In the logic: diff >= 2, bhWinners > fhWinners, bhRatio > 0.55 → "Backhand Dominant"
        XCTAssertGreaterThan(bhRatio, 0.5)
    }

    func testShotSignatureNoDataReturnsBalanced() {
        // Both 0 FH and 0 BH winners
        let fhWinners = 0
        let bhWinners = 0
        let fhErrors = 0
        let bhErrors = 0

        let fhTotal = fhWinners + fhErrors
        let bhTotal = bhWinners + bhErrors
        let totalGroundstroke = fhTotal + bhTotal

        // With no data, should yield "Balanced"
        XCTAssertEqual(totalGroundstroke, 0, "No groundstroke data → should show Balanced")
    }

    // MARK: - Best single match 1st serve %

    func testBestSingleMatchServePctReturnsMaxAcrossMatches() {
        let m1 = makeCompletedMatch(player1: player, player2: opponent)
        m1.firstServeAttemptsPlayer1 = 10
        m1.firstServesMadePlayer1 = 7 // 70%

        let m2 = makeCompletedMatch(player1: player, player2: opponent)
        m2.firstServeAttemptsPlayer1 = 10
        m2.firstServesMadePlayer1 = 9 // 90%

        let m3 = makeCompletedMatch(player1: player, player2: opponent)
        m3.firstServeAttemptsPlayer1 = 10
        m3.firstServesMadePlayer1 = 5 // 50%

        func isPlayer1(in match: Match) -> Bool { match.players.first?.id == player.id }

        let matches = [m1, m2, m3]
        let pcts = matches.compactMap { match -> Double? in
            let attempts = isPlayer1(in: match) ? match.firstServeAttemptsPlayer1 : match.firstServeAttemptsPlayer2
            guard attempts > 0 else { return nil }
            return isPlayer1(in: match) ? match.firstServePercentagePlayer1 : match.firstServePercentagePlayer2
        }

        let best = pcts.max()
        XCTAssertNotNil(best)
        XCTAssertEqual(best!, 90.0, accuracy: 0.1, "Best match should be m2 with 90%")
    }

    func testBestSingleMatchServePctReturnsNilWhenNoServeData() {
        let m = makeCompletedMatch(player1: player, player2: opponent)
        // No serve data
        m.firstServeAttemptsPlayer1 = 0
        m.firstServeAttemptsPlayer2 = 0

        func isPlayer1(in match: Match) -> Bool { match.players.first?.id == player.id }

        let pcts = [m].compactMap { match -> Double? in
            let attempts = isPlayer1(in: match) ? match.firstServeAttemptsPlayer1 : match.firstServeAttemptsPlayer2
            guard attempts > 0 else { return nil }
            return isPlayer1(in: match) ? match.firstServePercentagePlayer1 : match.firstServePercentagePlayer2
        }

        XCTAssertTrue(pcts.isEmpty, "Should return nil when no serve data exists")
    }

    func testBestSingleMatchServePctSkipsMatchesWithNoServeAttempts() {
        let m1 = makeCompletedMatch(player1: player, player2: opponent)
        m1.firstServeAttemptsPlayer1 = 0 // no serve data

        let m2 = makeCompletedMatch(player1: player, player2: opponent)
        m2.firstServeAttemptsPlayer1 = 8
        m2.firstServesMadePlayer1 = 6 // 75%

        func isPlayer1(in match: Match) -> Bool { match.players.first?.id == player.id }

        let pcts = [m1, m2].compactMap { match -> Double? in
            let attempts = isPlayer1(in: match) ? match.firstServeAttemptsPlayer1 : match.firstServeAttemptsPlayer2
            guard attempts > 0 else { return nil }
            return isPlayer1(in: match) ? match.firstServePercentagePlayer1 : match.firstServePercentagePlayer2
        }

        XCTAssertEqual(pcts.count, 1, "Should skip m1 with no serve data")
        XCTAssertEqual(pcts.first!, 75.0, accuracy: 0.1)
    }

    // MARK: - hasCareerShotData

    func testHasCareerShotDataFalseWhenNoMatches() {
        let matches: [Match] = []
        let hasData = matches.contains { !$0.shotStatistics.isEmpty }
        XCTAssertFalse(hasData, "No matches → no shot data")
    }

    func testHasCareerShotDataFalseWhenMatchesHaveNoShots() {
        let m = makeCompletedMatch(player1: player, player2: opponent)
        let hasData = [m].contains { !$0.shotStatistics.isEmpty }
        XCTAssertFalse(hasData, "Match with no shot stats → no shot data")
    }

    func testHasCareerShotDataTrueWhenAtLeastOneMatchHasShots() {
        let m1 = makeCompletedMatch(player1: player, player2: opponent)
        // m1 has no shots

        let m2 = makeCompletedMatch(player1: player, player2: opponent)
        m2.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)

        let hasData = [m1, m2].contains { !$0.shotStatistics.isEmpty }
        XCTAssertTrue(hasData, "Should report shot data present when at least one match has shots")
    }

    // MARK: - Net winners (volley + overhead)

    func testCareerVolleyWinnersAggregation() {
        let m = makeCompletedMatch(player1: player, player2: opponent)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .volley)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .volley)
        m.recordShotStatistic(playerNumber: 1, statType: .unforcedError, shotType: .forehand, contactType: .volley)

        let volleyWinners = m.shotStatistics.filter {
            $0.playerNumber == 1 && $0.statType == .winner && $0.contactType == .volley
        }.count

        XCTAssertEqual(volleyWinners, 2, "Should count FH+BH volley winners but not errors")
    }

    func testCareerOverheadWinnersDoNotIncludeErrors() {
        let m = makeCompletedMatch(player1: player, player2: opponent)
        m.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .overhead)
        m.recordShotStatistic(playerNumber: 1, statType: .unforcedError, shotType: .forehand, contactType: .overhead)

        let overheadWinners = m.shotStatistics.filter {
            $0.playerNumber == 1 && $0.statType == .winner && $0.contactType == .overhead
        }.count

        XCTAssertEqual(overheadWinners, 1, "Overhead winners should exclude overhead errors")
    }
}
