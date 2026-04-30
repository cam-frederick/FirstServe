# FirstServe

> Elegant tennis scoring and stats tracking for iPhone and Apple Watch

[![Platform](https://img.shields.io/badge/platform-iOS%2018.0%2B-blue.svg)](https://www.apple.com/ios/)
[![watchOS](https://img.shields.io/badge/watchOS-11.0%2B-blue.svg)](https://www.apple.com/watchos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-green.svg)](https://developer.apple.com/xcode/swiftui/)

FirstServe is a beautifully designed tennis scoring and statistics app built with 100% SwiftUI and SwiftData. Score matches from your iPhone or Apple Watch, and track your game with comprehensive per-match and aggregate statistics.

## Features

### Match Scoring
- **Flexible Formats** — Single Set, Super Set (first to 8), Best of 3, Best of 5
- **Scoring Modes** — Games only, point-by-point, or full shot statistics
- **Scoring Styles** — Advantage scoring or No-Ad (sudden death at deuce)
- **Tiebreak Options** — Standard (7-point), Extended (10-point), or Match Tiebreak
- **Undo Support** — Full snapshot-based undo; reverses any mistake to the exact prior state
- **Auto-save** — SwiftData persists every point; nothing is ever lost

### Apple Watch Companion
- **Score from your wrist** — Full scoring controls on watchOS 11
- **Real-time sync** — WatchConnectivity keeps iPhone and Watch in lockstep
- **Optimistic updates** — Watch UI responds immediately; rolls back if phone disagrees
- **Match list** — Browse and select active matches directly on Watch

### Match History & Statistics
- **Match History** — All past matches with opponent search and surface filtering
- **Shot-level Stats** — Track aces, double faults, winners, forced/unforced errors by shot type
- **Aggregate Stats** — Win/loss record, service percentages, break point conversion across all matches
- **Head-to-head** — Records against specific opponents by surface

### Accessibility
- Full VoiceOver support with descriptive labels and semantic actions
- Dynamic Type — respects system text size preferences
- Reduced Motion — respects accessibility preferences

### Social Sharing
- Share match results to Twitter/X with a pre-formatted, editable message

### Design: "Court Nouveau"
A dark editorial aesthetic inspired by iconic tennis venues — Wimbledon green, Roland Garros clay, US Open blue — with serif headlines, monospace scores, spring-based animations, and haptic feedback synced to every action.

## Architecture

### Data Layer
- **SwiftData** — All models (`Match`, `Player`, `TennisSet`, `Game`, `ShotStatistic`) use `@Model`
- **Ordered access** — `@Relationship` arrays are unordered; all code sorts before access via `sortedSets`, `sortedGames`, `currentGame` helpers on the model layer
- **Cascade deletes** — Sets, games, and shot stats are cleaned up with their parent match

### State Management
- **`@Observable`** — `MatchViewModel` and Watch services use the modern Swift observation framework
- **Snapshot-based undo** — `PointSnapshot` captures full game state before each point; undo restores the entire snapshot

### Watch Sync
- **Phone is source of truth** — Watch sends commands; phone applies them and broadcasts the new state
- **Optimistic updates** — Watch applies the expected outcome immediately, then rolls back if the phone's confirmed state differs
- **`WatchMatchState`** — Lightweight `Codable` structs shuttle state over `WatchConnectivity` `applicationContext`
- **Duplicate prevention** — `isProcessingWatchCommand` flag on the phone prevents double-application of commands arriving via both reply and `sendMatchUpdate`

### Project Structure
```
FirstServe/
├── FirstServe/                    # iOS app target
│   ├── FirstServeApp.swift        # SwiftData container setup
│   ├── Models/                    # @Model types: Match, Player, TennisSet, Game, ShotStatistic
│   ├── Views/                     # HomeView, LiveMatchView, MatchSummaryView, etc.
│   ├── ViewModels/                # MatchViewModel (@Observable)
│   ├── Services/                  # WatchConnectivityService
│   └── Theme/                     # DesignSystem.swift (Court Nouveau)
│
├── FirstServeWatch/               # watchOS app target
│   ├── Views/                     # WatchMatchListView, WatchScoringView
│   ├── Services/                  # WatchSessionService (optimistic updates)
│   └── Theme/                     # WatchDesignSystem.swift
│
├── Shared/
│   └── WatchMatchState.swift      # Codable structs shared between targets
│
├── FirstServeTests/               # 12 test files, 30+ unit tests
├── FirstServeUITests/             # UI automation tests
│
└── project.yml                    # XcodeGen project definition
```

## Getting Started

### Prerequisites
- Xcode 16.2+
- macOS Sequoia or later
- iPhone running iOS 18.0+
- Apple Watch running watchOS 11.0+ (for Watch companion)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — only needed if modifying `project.yml`

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/cam-frederick/FirstServe.git
   cd FirstServe
   ```

2. **Open in Xcode**
   ```bash
   open FirstServe.xcodeproj
   ```
   If the `.xcodeproj` is missing (e.g. after a fresh clone that didn't include it), regenerate it:
   ```bash
   xcodegen generate
   ```

3. **Run the app**
   - Select the `FirstServe` scheme and an iOS 18 simulator or device
   - Press `Cmd+R`
   - For Watch: select the `FirstServeWatch` scheme paired to an Apple Watch simulator

### Testing

```bash
xcodebuild test -project FirstServe.xcodeproj -scheme FirstServe
```
Or press `Cmd+U` in Xcode. Tests cover scoring logic, set/match completion, tiebreak rules, serve statistics, shot tracking, accessibility labels, match sharing, and form validation.

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (100%, no UIKit) |
| Persistence | SwiftData |
| State | `@Observable` |
| Watch sync | WatchConnectivity |
| Sharing | `UIActivityViewController` |
| Haptics | UIFeedbackGenerator |
| Build | XcodeGen (`project.yml` → `.xcodeproj`) |
| CI | GitHub Actions + Claude Code |

**Deployment targets:** iOS 18.0 / watchOS 11.0  
**Xcode:** 16.2 | **Swift:** 5.9

## License

Private — All rights reserved.
