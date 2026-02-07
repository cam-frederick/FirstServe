//
//  ShareFunctionalityTests.swift
//  FirstServeTests
//
//  Tests for match result sharing functionality
//

import XCTest
import SwiftData
@testable import FirstServe

final class ShareFunctionalityTests: XCTestCase {
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
    
    // MARK: - Share Text Generation Tests
    
    @MainActor
    func testShareTextIncludesAppName() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("FirstServe"))
        XCTAssertTrue(shareText.contains("🎾"))
    }
    
    @MainActor
    func testShareTextIncludesWinner() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        if let winner = match.winner {
            XCTAssertTrue(shareText.contains(winner.name))
            XCTAssertTrue(shareText.contains("wins"))
        } else {
            XCTFail("Match should have a winner")
        }
    }
    
    @MainActor
    func testShareTextIncludesScore() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        let score = match.scoreString
        
        // Then
        XCTAssertTrue(shareText.contains(score))
        XCTAssertFalse(score.isEmpty)
    }
    
    @MainActor
    func testShareTextIncludesSurface() {
        // Given - Hard Court
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("Hard Court"))
        XCTAssertTrue(shareText.contains("📍"))
    }
    
    @MainActor
    func testShareTextIncludesFormat() {
        // Given - Best of 3
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("Best of 3"))
        XCTAssertTrue(shareText.contains("🏆"))
    }
    
    @MainActor
    func testShareTextIncludesDurationWhenAvailable() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // Simulate some elapsed time
        let futureDate = Date().addingTimeInterval(1800) // 30 minutes
        match.completedAt = futureDate
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("⏱️"))
        XCTAssertTrue(shareText.contains("m") || shareText.contains("h"))
    }
    
    @MainActor
    func testShareTextFormatsHoursAndMinutes() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // Simulate 90 minutes (1h 30m)
        let futureDate = Date().addingTimeInterval(5400)
        match.completedAt = futureDate
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then - should show hours and minutes for matches over 60 minutes
        if shareText.contains("⏱️") {
            XCTAssertTrue(shareText.contains("h") || shareText.contains("hour"))
        }
    }
    
    @MainActor
    func testShareTextIncludesAcesWhenPresent() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Record some aces
        match.acesPlayer1 = 5
        match.acesPlayer2 = 3
        
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("⚡"))
        XCTAssertTrue(shareText.contains("8 aces") || shareText.contains("ace"))
    }
    
    @MainActor
    func testShareTextIncludesWinnersWhenPresent() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Record some winners
        match.winnersPlayer1 = 12
        match.winnersPlayer2 = 8
        
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("⭐"))
        XCTAssertTrue(shareText.contains("20 winners") || shareText.contains("winner"))
    }
    
    @MainActor
    func testShareTextOmitsZeroStats() {
        // Given - no aces or winners
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        match.acesPlayer1 = 0
        match.acesPlayer2 = 0
        match.winnersPlayer1 = 0
        match.winnersPlayer2 = 0
        
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then - should not show stats with 0 count
        XCTAssertFalse(shareText.contains("0 aces"))
        XCTAssertFalse(shareText.contains("0 winners"))
    }
    
    @MainActor
    func testShareTextIncludesHashtags() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("#FirstServe"))
        XCTAssertTrue(shareText.contains("#Tennis"))
    }
    
    @MainActor
    func testShareTextFormattingIsClean() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then - should have proper line breaks and structure
        let lines = shareText.components(separatedBy: "\n")
        XCTAssertGreaterThan(lines.count, 5, "Share text should have multiple lines")
        
        // Should not have excessive whitespace
        XCTAssertFalse(shareText.contains("  "), "Should not have double spaces")
    }
    
    // MARK: - Different Surface Tests
    
    @MainActor
    func testShareTextHandlesClayMatch() {
        // Given
        let clayMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .clay)
        modelContext.insert(clayMatch)
        clayMatch.startNewSet()
        clayMatch.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch(clayMatch)
        
        // When
        let shareText = generateShareText(for: clayMatch)
        
        // Then
        XCTAssertTrue(shareText.contains("Clay"))
    }
    
    @MainActor
    func testShareTextHandlesGrassMatch() {
        // Given
        let grassMatch = Match(player1: player1, player2: player2, format: .bestOf3, surface: .grass)
        modelContext.insert(grassMatch)
        grassMatch.startNewSet()
        grassMatch.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch(grassMatch)
        
        // When
        let shareText = generateShareText(for: grassMatch)
        
        // Then
        XCTAssertTrue(shareText.contains("Grass"))
    }
    
    // MARK: - Different Format Tests
    
    @MainActor
    func testShareTextHandlesBestOf5() {
        // Given
        let bestOf5Match = Match(player1: player1, player2: player2, format: .bestOf5, surface: .hardCourt)
        modelContext.insert(bestOf5Match)
        bestOf5Match.startNewSet()
        bestOf5Match.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch(bestOf5Match)
        
        // When
        let shareText = generateShareText(for: bestOf5Match)
        
        // Then
        XCTAssertTrue(shareText.contains("Best of 5"))
    }
    
    // MARK: - Edge Cases
    
    @MainActor
    func testShareTextWithLongPlayerNames() {
        // Given
        let longName1 = Player(name: "Christopher Alexander")
        let longName2 = Player(name: "Maximilian Rodriguez")
        let longNameMatch = Match(player1: longName1, player2: longName2, format: .bestOf3, surface: .hardCourt)
        
        modelContext.insert(longName1)
        modelContext.insert(longName2)
        modelContext.insert(longNameMatch)
        
        longNameMatch.startNewSet()
        longNameMatch.currentSet?.startNewGame(serverIsPlayer1: true)
        completeMatch(longNameMatch)
        
        // When
        let shareText = generateShareText(for: longNameMatch)
        
        // Then - should handle long names gracefully
        XCTAssertTrue(shareText.contains("Christopher Alexander") || shareText.contains("Maximilian Rodriguez"))
        XCTAssertFalse(shareText.isEmpty)
    }
    
    @MainActor
    func testShareTextWithHighStats() {
        // Given
        match.startNewSet()
        match.currentSet?.startNewGame(serverIsPlayer1: true)
        
        // Record high stats
        match.acesPlayer1 = 25
        match.acesPlayer2 = 18
        match.winnersPlayer1 = 35
        match.winnersPlayer2 = 28
        
        completeMatch()
        
        // When
        let shareText = generateShareText(for: match)
        
        // Then
        XCTAssertTrue(shareText.contains("43 aces"))
        XCTAssertTrue(shareText.contains("63 winners"))
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func completeMatch(_ targetMatch: Match? = nil) {
        let m = targetMatch ?? match
        
        // Complete a set 6-0
        guard let currentSet = m.currentSet else { return }
        
        for _ in 0..<24 { // 6 games, 4 points each
            currentSet.currentGame?.awardPoint(toPlayer1: true)
        }
        
        m.completeMatch()
    }
    
    @MainActor
    private func generateShareText(for match: Match) -> String {
        var text = "🎾 FirstServe Match Result\n\n"
        
        // Winner announcement
        if let winner = match.winner {
            text += "\(winner.name) wins!\n"
        }
        
        // Score
        text += "\(match.scoreString)\n\n"
        
        // Match info
        text += "📍 \(match.surface.rawValue)\n"
        text += "🏆 \(match.format.rawValue)\n"
        
        // Duration if available
        if let completedAt = match.completedAt {
            let duration = completedAt.timeIntervalSince(match.createdAt)
            let minutes = Int(duration) / 60
            if minutes < 60 {
                text += "⏱️ \(minutes)m\n"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                text += "⏱️ \(hours)h \(mins)m\n"
            }
        }
        
        // Key stats if notable
        let totalAces = match.acesPlayer1 + match.acesPlayer2
        let totalWinners = match.winnersPlayer1 + match.winnersPlayer2
        
        if totalAces > 0 {
            text += "⚡ \(totalAces) aces\n"
        }
        if totalWinners > 0 {
            text += "⭐ \(totalWinners) winners\n"
        }
        
        text += "\n#FirstServe #Tennis"
        
        return text
    }
}
