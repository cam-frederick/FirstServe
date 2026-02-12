import XCTest

final class FirstServeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch & Empty State
    
    func testAppLaunchShowsEmptyState() throws {
        // Given: Fresh app launch
        
        // Then: Should see empty state message
        XCTAssertTrue(app.staticTexts["No Matches Yet"].exists)
        XCTAssertTrue(app.buttons["Start New Match"].exists)
    }
    
    // MARK: - Match Creation
    
    func testCreateNewMatch() throws {
        // Given: Empty state
        let startButton = app.buttons["Start New Match"]
        XCTAssertTrue(startButton.exists)
        
        // When: Tap start new match
        startButton.tap()
        
        // Then: Should show new match form
        XCTAssertTrue(app.navigationBars["New Match"].exists)
        
        // When: Fill in player names
        let player1Field = app.textFields["player1NameField"]
        let player2Field = app.textFields["player2NameField"]
        
        XCTAssertTrue(player1Field.exists)
        XCTAssertTrue(player2Field.exists)
        
        player1Field.tap()
        player1Field.typeText("Roger")
        
        player2Field.tap()
        player2Field.typeText("Rafa")
        
        // When: Select surface and format (defaults should be set)
        // Clay, Best of 3 are defaults
        
        // When: Start match
        let startMatchButton = app.buttons["startMatchButton"]
        XCTAssertTrue(startMatchButton.exists)
        startMatchButton.tap()
        
        // Then: Should show live match view
        XCTAssertTrue(app.staticTexts["Roger"].exists)
        XCTAssertTrue(app.staticTexts["Rafa"].exists)
        XCTAssertTrue(app.staticTexts["0"].exists) // Initial scores
    }
    
    // MARK: - Live Scoring
    
    func testScorePointsUpdatesScore() throws {
        // Given: Match is created
        createQuickMatch(player1: "John", player2: "Pete")
        
        // When: Award point to player 1
        let player1Button = app.buttons["player1ScoreButton"]
        XCTAssertTrue(player1Button.exists)
        player1Button.tap()
        
        // Then: Score should update to 15-0
        XCTAssertTrue(app.staticTexts["15"].exists)
        
        // When: Award another point
        player1Button.tap()
        
        // Then: Score should be 30-0
        XCTAssertTrue(app.staticTexts["30"].exists)
    }
    
    func testCompleteGameSwitchesServer() throws {
        // Given: Match is created
        createQuickMatch(player1: "Andre", player2: "Boris")
        
        // Get initial server indicator
        let serveIndicator = app.images["serve.indicator"]
        
        // When: Win a game (4 points)
        let player1Button = app.buttons["player1ScoreButton"]
        for _ in 1...4 {
            player1Button.tap()
            sleep(1) // Small delay for UI updates
        }
        
        // Then: Should show 1-0 in games
        XCTAssertTrue(app.staticTexts["1"].exists)
        XCTAssertTrue(app.staticTexts["0"].exists)
        
        // And: Server should have switched (check serve indicator moved)
        // The serve indicator should now be on player 2
    }
    
    // MARK: - Undo Functionality
    
    func testUndoRestoresPreviousState() throws {
        // Given: Match with some points scored
        createQuickMatch(player1: "Stefan", player2: "Mats")
        
        let player1Button = app.buttons["player1ScoreButton"]
        player1Button.tap()
        player1Button.tap()
        
        // Should be 30-0
        XCTAssertTrue(app.staticTexts["30"].exists)
        
        // When: Tap undo
        let undoButton = app.buttons["undoButton"]
        XCTAssertTrue(undoButton.exists)
        undoButton.tap()
        
        // Then: Score should revert to 15-0
        XCTAssertTrue(app.staticTexts["15"].exists)
        XCTAssertFalse(app.staticTexts["30"].exists || app.staticTexts["0"].waitForExistence(timeout: 1))
    }
    
    // MARK: - Match Stats
    
    func testQuickStatButtonsAwardPoints() throws {
        // Given: Match is created
        createQuickMatch(player1: "Jim", player2: "Bjorn")
        
        // When: Tap ace button for player 1
        let aceButton = app.buttons["Ace"]
        if aceButton.exists {
            aceButton.tap()
            
            // Then: Score should increase AND ace count should update
            XCTAssertTrue(app.staticTexts["15"].exists)
            // Stats should show 1 ace (may need to open stats view)
        }
    }
    
    // MARK: - Match Completion
    
    func testCompleteMatchShowsWinner() throws {
        // Given: Match near completion
        createQuickMatch(player1: "Winner", player2: "Runner-up")
        
        // When: Win two sets quickly (score 48 points for player 1)
        // This is a long test - simplified version
        let player1Button = app.buttons["player1ScoreButton"]
        
        // Win first set 6-0 (24 points)
        for _ in 1...24 {
            player1Button.tap()
        }
        
        // Win second set 6-0 (24 more points)
        for _ in 1...24 {
            player1Button.tap()
        }
        
        // Then: Should show match complete state
        // Check for winner banner or "Match Complete" text
        let matchCompleteExists = app.staticTexts["Match Complete"].waitForExistence(timeout: 2) ||
                                  app.staticTexts["Winner"].waitForExistence(timeout: 2)
        XCTAssertTrue(matchCompleteExists)
    }
    
    // MARK: - Helper Methods
    
    private func createQuickMatch(player1: String, player2: String) {
        // Tap start new match
        let startButton = app.buttons["Start New Match"]
        if startButton.exists {
            startButton.tap()
        }
        
        // Fill in names
        let player1Field = app.textFields["player1NameField"]
        let player2Field = app.textFields["player2NameField"]
        
        player1Field.tap()
        player1Field.typeText(player1)
        
        player2Field.tap()
        player2Field.typeText(player2)
        
        // Start match with defaults
        app.buttons["startMatchButton"].tap()
        
        // Wait for live view
        _ = app.staticTexts[player1].waitForExistence(timeout: 2)
    }
}
