//
//  MatchSummaryViewTests.swift
//  FirstServeTests
//
//  Tests for MatchSummaryView data calculations and formatting
//  Created by Cici on 2/14/26.
//

import XCTest
import SwiftData
@testable import FirstServe

@MainActor
final class MatchSummaryViewTests: XCTestCase {
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
        match = Match(player1: player1, player2: player2, format: .bestOf3, surface: .hardCourt)
        
        modelContext.insert(match)
        modelContext.insert(player1)
        modelContext.insert(player2)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        match = nil
        player1 = nil
        player2 = nil
    }
    
    // MARK: - Duration Formatting Tests
    
    func testDurationFormattingMinutes() throws {
        // Given: Match duration under 1 hour
        let start = Date()
        let end = start.addingTimeInterval(45 * 60) // 45 minutes
        
        match.createdAt = start
        match.completedAt = end
        
        // When: Formatting duration
        let formatted = formatDuration(from: start, to: end)
        
        // Then: Shows minutes only
        XCTAssertEqual(formatted, "45 min")
    }
    
    func testDurationFormattingHours() throws {
        // Given: Match duration over 1 hour
        let start = Date()
        let end = start.addingTimeInterval(90 * 60) // 1h 30min
        
        match.createdAt = start
        match.completedAt = end
        
        // When: Formatting duration
        let formatted = formatDuration(from: start, to: end)
        
        // Then: Shows hours and minutes
        XCTAssertEqual(formatted, "1h 30m")
    }
    
    func testDurationFormattingExactHour() throws {
        // Given: Match duration exactly 2 hours
        let start = Date()
        let end = start.addingTimeInterval(120 * 60) // 2h 0min
        
        match.createdAt = start
        match.completedAt = end
        
        // When: Formatting duration
        let formatted = formatDuration(from: start, to: end)
        
        // Then: Shows hours with 0 minutes
        XCTAssertEqual(formatted, "2h 0m")
    }
    
    // MARK: - Share Text Generation Tests
    
    func testShareTextBasic() throws {
        // Given: Completed match with winner
        match.startNewSet()
        match.isComplete = true
        match.completedAt = Date()
        
        // When: Generating share text
        let shareText = generateShareText(for: match)
        
        // Then: Contains required elements
        XCTAssertTrue(shareText.contains("🎾 FirstServe Match Summary"))
        XCTAssertTrue(shareText.contains(match.surface.rawValue))
        XCTAssertTrue(shareText.contains(match.format.rawValue))
        XCTAssertTrue(shareText.contains("#FirstServe #Tennis"))
    }
    
    func testShareTextWithStats() throws {
        // Given: Match with statistics
        match.startNewSet()
        match.acesPlayer1 = 5
        match.acesPlayer2 = 3
        match.winnersPlayer1 = 12
        match.winnersPlayer2 = 8
        match.unforcedErrorsPlayer1 = 7
        match.unforcedErrorsPlayer2 = 11
        match.isComplete = true
        match.completedAt = Date()
        
        // When: Generating share text
        let shareText = generateShareText(for: match)
        
        // Then: Contains stats
        XCTAssertTrue(shareText.contains("Aces: 5 - 3"))
        XCTAssertTrue(shareText.contains("Winners: 12 - 8"))
        XCTAssertTrue(shareText.contains("Errors: 7 - 11"))
    }
    
    func testShareTextWithDuration() throws {
        // Given: Match with duration
        let start = Date()
        let end = start.addingTimeInterval(75 * 60) // 1h 15min
        
        match.createdAt = start
        match.completedAt = end
        match.startNewSet()
        match.isComplete = true
        
        // When: Generating share text
        let shareText = generateShareText(for: match)
        
        // Then: Contains duration
        XCTAssertTrue(shareText.contains("1h 15m"))
    }
    
    // MARK: - Score Progression Tests
    
    func testScoreProgressionSingleSet() throws {
        // Given: Single set match
        match = Match(player1: player1, player2: player2, format: .singleSet, surface: .hardCourt)
        modelContext.insert(match)
        
        match.startNewSet()
        if let set = match.currentSet {
            set.gamesPlayer1 = 6
            set.gamesPlayer2 = 4
            set.isComplete = true
        }
        match.isComplete = true
        
        // When: Checking sets
        // Then: Has one set with correct scores
        XCTAssertEqual(match.sets.count, 1)
        XCTAssertEqual(match.sets[0].gamesPlayer1, 6)
        XCTAssertEqual(match.sets[0].gamesPlayer2, 4)
    }
    
    func testScoreProgressionBestOf3() throws {
        // Given: Best of 3 match with 2 sets played
        match.startNewSet()
        if let set1 = match.currentSet {
            set1.gamesPlayer1 = 6
            set1.gamesPlayer2 = 4
            set1.isComplete = true
        }
        
        match.startNewSet()
        if let set2 = match.currentSet {
            set2.gamesPlayer1 = 6
            set2.gamesPlayer2 = 2
            set2.isComplete = true
        }
        
        match.isComplete = true
        
        // When: Checking sets
        // Then: Has two sets with correct scores
        XCTAssertEqual(match.sets.count, 2)
        XCTAssertEqual(match.sets[0].gamesPlayer1, 6)
        XCTAssertEqual(match.sets[0].gamesPlayer2, 4)
        XCTAssertEqual(match.sets[1].gamesPlayer1, 6)
        XCTAssertEqual(match.sets[1].gamesPlayer2, 2)
    }
    
    func testScoreProgressionWithTiebreak() throws {
        // Given: Set with tiebreak
        match.startNewSet()
        if let set = match.currentSet {
            set.gamesPlayer1 = 7
            set.gamesPlayer2 = 6
            set.tiebreakScorePlayer1 = 7
            set.tiebreakScorePlayer2 = 5
            set.isComplete = true
        }
        
        // When: Checking if tiebreak is indicated
        let set = match.sets[0]
        
        // Then: Tiebreak occurred
        XCTAssertEqual(set.gamesPlayer1, 7)
        XCTAssertEqual(set.gamesPlayer2, 6)
        XCTAssertNotNil(set.tiebreakScorePlayer1)
        XCTAssertNotNil(set.tiebreakScorePlayer2)
    }
    
    // MARK: - Shot Statistics Display Tests
    
    func testShotStatisticsBreakdown() throws {
        // Given: Match with various shot statistics
        let fhGroundstrokeWinner = ShotStatistic(
            playerNumber: 1,
            statType: .winner,
            shotType: .forehand,
            contactType: .groundstroke
        )
        match.shotStatistics.append(fhGroundstrokeWinner)
        modelContext.insert(fhGroundstrokeWinner)
        
        let bhVolleyError = ShotStatistic(
            playerNumber: 2,
            statType: .unforcedError,
            shotType: .backhand,
            contactType: .volley
        )
        match.shotStatistics.append(bhVolleyError)
        modelContext.insert(bhVolleyError)
        
        // When: Filtering statistics
        let p1Winners = match.shotStatistics.filter { $0.playerNumber == 1 && $0.statType == .winner }
        let p2Errors = match.shotStatistics.filter { $0.playerNumber == 2 && $0.statType == .unforcedError }
        
        // Then: Statistics are categorized correctly
        XCTAssertEqual(p1Winners.count, 1)
        XCTAssertEqual(p1Winners[0].shotType, .forehand)
        XCTAssertEqual(p1Winners[0].contactType, .groundstroke)
        
        XCTAssertEqual(p2Errors.count, 1)
        XCTAssertEqual(p2Errors[0].shotType, .backhand)
        XCTAssertEqual(p2Errors[0].contactType, .volley)
    }
    
    func testShotStatisticsGrouping() throws {
        // Given: Multiple shots of the same type
        for _ in 0..<3 {
            let winner = ShotStatistic(
                playerNumber: 1,
                statType: .winner,
                shotType: .forehand,
                contactType: .groundstroke
            )
            match.shotStatistics.append(winner)
            modelContext.insert(winner)
        }
        
        for _ in 0..<2 {
            let winner = ShotStatistic(
                playerNumber: 1,
                statType: .winner,
                shotType: .backhand,
                contactType: .groundstroke
            )
            match.shotStatistics.append(winner)
            modelContext.insert(winner)
        }
        
        // When: Filtering by shot type
        let fhWinners = match.shotStatistics.filter {
            $0.playerNumber == 1 && $0.statType == .winner && $0.shotType == .forehand && $0.contactType == .groundstroke
        }
        let bhWinners = match.shotStatistics.filter {
            $0.playerNumber == 1 && $0.statType == .winner && $0.shotType == .backhand && $0.contactType == .groundstroke
        }
        
        // Then: Counts are correct
        XCTAssertEqual(fhWinners.count, 3)
        XCTAssertEqual(bhWinners.count, 2)
    }
    
    // MARK: - Chart Data Tests
    
    func testServePercentageChartData() throws {
        // Given: Serve statistics for both players
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        match.recordServe(forPlayer1: true, firstServe: true, made: false)
        match.recordServe(forPlayer1: true, firstServe: true, made: true)
        // Player 1: 3/4 = 75%
        
        match.recordServe(forPlayer1: false, firstServe: true, made: true)
        match.recordServe(forPlayer1: false, firstServe: true, made: false)
        // Player 2: 1/2 = 50%
        
        // When: Getting percentages
        let p1Percentage = match.firstServePercentagePlayer1
        let p2Percentage = match.firstServePercentagePlayer2
        
        // Then: Percentages are correct for chart display
        XCTAssertEqual(p1Percentage, 75.0)
        XCTAssertEqual(p2Percentage, 50.0)
    }
    
    func testWinnersErrorsBarChartData() throws {
        // Given: Winners and errors for both players
        match.winnersPlayer1 = 15
        match.winnersPlayer2 = 10
        match.unforcedErrorsPlayer1 = 8
        match.unforcedErrorsPlayer2 = 12
        
        // When: Calculating bar widths (relative to max)
        let maxWinners = max(match.winnersPlayer1 + match.winnersPlayer2, 1)
        let maxErrors = max(match.unforcedErrorsPlayer1 + match.unforcedErrorsPlayer2, 1)
        
        let p1WinnersRatio = Double(match.winnersPlayer1) / Double(maxWinners)
        let p2WinnersRatio = Double(match.winnersPlayer2) / Double(maxWinners)
        let p1ErrorsRatio = Double(match.unforcedErrorsPlayer1) / Double(maxErrors)
        let p2ErrorsRatio = Double(match.unforcedErrorsPlayer2) / Double(maxErrors)
        
        // Then: Ratios are correct for visual representation
        XCTAssertEqual(p1WinnersRatio, 15.0 / 25.0, accuracy: 0.01)
        XCTAssertEqual(p2WinnersRatio, 10.0 / 25.0, accuracy: 0.01)
        XCTAssertEqual(p1ErrorsRatio, 8.0 / 20.0, accuracy: 0.01)
        XCTAssertEqual(p2ErrorsRatio, 12.0 / 20.0, accuracy: 0.01)
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    private func generateShareText(for match: Match) -> String {
        var text = "🎾 FirstServe Match Summary\n\n"
        
        if let winner = match.winner {
            text += "\(winner.name) defeats "
            if let loser = match.players.first(where: { $0.id != winner.id }) {
                text += "\(loser.name)\n"
            }
        }
        
        text += "\(match.scoreString)\n\n"
        text += "📍 \(match.surface.rawValue) | \(match.format.rawValue)\n"
        
        if let completedAt = match.completedAt {
            text += "⏱️ \(formatDuration(from: match.createdAt, to: completedAt))\n\n"
        }
        
        text += "Key Stats:\n"
        text += "Aces: \(match.acesPlayer1) - \(match.acesPlayer2)\n"
        text += "Winners: \(match.winnersPlayer1) - \(match.winnersPlayer2)\n"
        text += "Errors: \(match.unforcedErrorsPlayer1) - \(match.unforcedErrorsPlayer2)\n"
        text += "1st Serve: \(String(format: "%.0f%%", match.firstServePercentagePlayer1)) - \(String(format: "%.0f%%", match.firstServePercentagePlayer2))\n\n"
        
        text += "#FirstServe #Tennis"
        
        return text
    }
}
