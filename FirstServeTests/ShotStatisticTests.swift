//
//  ShotStatisticTests.swift
//  FirstServeTests
//
//  Created by Cici on 2/13/26.
//

import XCTest
@testable import FirstServe

final class ShotStatisticTests: XCTestCase {
    
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
    
    // MARK: - Basic Shot Recording
    
    func testRecordShotStatistic() {
        match.recordShotStatistic(
            playerNumber: 1,
            statType: .winner,
            shotType: .forehand,
            contactType: .groundstroke
        )
        
        XCTAssertEqual(match.shotStatistics.count, 1)
        
        let stat = match.shotStatistics.first!
        XCTAssertEqual(stat.playerNumber, 1)
        XCTAssertEqual(stat.statType, .winner)
        XCTAssertEqual(stat.shotType, .forehand)
        XCTAssertEqual(stat.contactType, .groundstroke)
    }
    
    func testRecordMultipleShotStatistics() {
        // Record various shots
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .volley)
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .forehand, contactType: .groundstroke)
        
        XCTAssertEqual(match.shotStatistics.count, 3)
    }
    
    // MARK: - Basic Counter Updates
    
    func testShotStatisticUpdatesBasicCounters() {
        // Recording a winner should also update the basic winner counter
        match.recordShotStatistic(
            playerNumber: 1,
            statType: .winner,
            shotType: .forehand,
            contactType: .groundstroke
        )
        
        XCTAssertEqual(match.winnersPlayer1, 1)
        XCTAssertEqual(match.winnersPlayer2, 0)
    }
    
    func testUnforcedErrorUpdatesBasicCounters() {
        match.recordShotStatistic(
            playerNumber: 2,
            statType: .unforcedError,
            shotType: .backhand,
            contactType: .groundstroke
        )
        
        XCTAssertEqual(match.unforcedErrorsPlayer2, 1)
        XCTAssertEqual(match.unforcedErrorsPlayer1, 0)
    }
    
    // MARK: - Filtering and Aggregation
    
    func testGetShotStatisticsForPlayer() {
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .volley)
        match.recordShotStatistic(playerNumber: 2, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        
        let player1Stats = match.shotStatistics(forPlayerNumber: 1)
        let player2Stats = match.shotStatistics(forPlayerNumber: 2)
        
        XCTAssertEqual(player1Stats.count, 2)
        XCTAssertEqual(player2Stats.count, 1)
    }
    
    func testGetWinnersByShotType() {
        // Forehand groundstroke winners
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        
        // Backhand volley winner
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .volley)
        
        // Unforced error (should not count as winner)
        match.recordShotStatistic(playerNumber: 1, statType: .unforcedError, shotType: .forehand, contactType: .groundstroke)
        
        let fhGroundstrokeWinners = match.winners(forPlayerNumber: 1, shotType: .forehand, contactType: .groundstroke)
        let bhVolleyWinners = match.winners(forPlayerNumber: 1, shotType: .backhand, contactType: .volley)
        
        XCTAssertEqual(fhGroundstrokeWinners, 2)
        XCTAssertEqual(bhVolleyWinners, 1)
    }
    
    func testGetUnforcedErrorsByShotType() {
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 2, statType: .unforcedError, shotType: .forehand, contactType: .volley)
        
        let bhGroundstrokeErrors = match.unforcedErrors(forPlayerNumber: 2, shotType: .backhand, contactType: .groundstroke)
        let fhVolleyErrors = match.unforcedErrors(forPlayerNumber: 2, shotType: .forehand, contactType: .volley)
        
        XCTAssertEqual(bhGroundstrokeErrors, 2)
        XCTAssertEqual(fhVolleyErrors, 1)
    }
    
    func testGetWinnersByContactTypeOnly() {
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .volley)
        
        // Get all groundstroke winners regardless of shot type
        let groundstrokeWinners = match.winners(forPlayerNumber: 1, shotType: nil, contactType: .groundstroke)
        
        XCTAssertEqual(groundstrokeWinners, 2)
    }
    
    func testGetWinnersByShotTypeOnly() {
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .groundstroke)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .forehand, contactType: .volley)
        match.recordShotStatistic(playerNumber: 1, statType: .winner, shotType: .backhand, contactType: .volley)
        
        // Get all forehand winners regardless of contact type
        let forehandWinners = match.winners(forPlayerNumber: 1, shotType: .forehand, contactType: nil)
        
        XCTAssertEqual(forehandWinners, 2)
    }
    
    // MARK: - Model Relationships
    
    func testShotStatisticMatchIdRelationship() {
        match.recordShotStatistic(
            playerNumber: 1,
            statType: .winner,
            shotType: .forehand,
            contactType: .groundstroke
        )
        
        let stat = match.shotStatistics.first!
        XCTAssertEqual(stat.matchId, match.id)
    }
    
    func testShotStatisticTimestamp() {
        let beforeTime = Date()
        
        match.recordShotStatistic(
            playerNumber: 1,
            statType: .winner,
            shotType: .forehand,
            contactType: .groundstroke
        )
        
        let afterTime = Date()
        let stat = match.shotStatistics.first!
        
        XCTAssertGreaterThanOrEqual(stat.timestamp, beforeTime)
        XCTAssertLessThanOrEqual(stat.timestamp, afterTime)
    }
    
    // MARK: - Enums
    
    func testStatTypeEnum() {
        XCTAssertEqual(StatType.winner.rawValue, "Winner")
        XCTAssertEqual(StatType.unforcedError.rawValue, "Unforced Error")
    }
    
    func testShotTypeEnum() {
        XCTAssertEqual(ShotType.forehand.rawValue, "Forehand")
        XCTAssertEqual(ShotType.backhand.rawValue, "Backhand")
    }
    
    func testContactTypeEnum() {
        XCTAssertEqual(ContactType.groundstroke.rawValue, "Groundstroke")
        XCTAssertEqual(ContactType.volley.rawValue, "Volley")
        XCTAssertEqual(ContactType.overhead.rawValue, "Overhead")
        XCTAssertEqual(ContactType.serve.rawValue, "Serve")
    }
}
