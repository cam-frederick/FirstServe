# FirstServe

> *Elegant tennis scoring and stats tracking for iOS*

[![Platform](https://img.shields.io/badge/platform-iOS%2015.0%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green.svg)](https://developer.apple.com/xcode/swiftui/)

FirstServe is a beautifully designed tennis scoring and statistics app for iPhone and iPad. Built with 100% SwiftUI and SwiftData, it features a premium "Court Nouveau" design system inspired by the world's greatest tennis venues.

## ✨ Features

### Match Scoring
- **Quick Match Start** — Opponent name, court surface, best-of format
- **Live Scoring** — Tap to score, track aces, double faults, winners, errors
- **Undo Support** — Reverse mistakes with unlimited undo
- **Auto-save** — Never lose match progress
- **Match Completion** — Confetti celebration with final stats

### Match History
- **Comprehensive List** — All past matches with search and filtering
- **Surface Filter** — Filter by Hard, Clay, Grass, or Carpet
- **Opponent Search** — Find matches against specific players
- **Match Details** — Full point-by-point breakdown
- **Delete Matches** — Swipe to remove completed matches

### Statistics
- **Aggregate Stats** — Overall performance across all matches
- **Opponent-specific Stats** — Head-to-head records
- **Surface Stats** — Performance breakdown by court type
- **Win/Loss Record** — Track your tennis journey
- **Advanced Metrics:**
  - Aces and double faults
  - Winners and unforced errors
  - Service games won
  - Break points converted

### Accessibility
- **Full VoiceOver Support** — Complete screen reader compatibility
- **Dynamic Type** — Respects system text size preferences
- **Clear Labels** — Descriptive accessibility labels throughout
- **Semantic Actions** — Custom VoiceOver actions for quick navigation
- **Reduced Motion** — Respects accessibility preferences

### Social Sharing
- **Share Match Results** — Post victories on social media
- **Twitter/X Integration** — Pre-formatted tweets with match details
- **Customizable Messages** — Edit before sharing
- **Privacy Friendly** — Share only what you want

### Design Excellence
- **"Court Nouveau" Design System** — Premium editorial aesthetic
- **Tennis-themed Colors** — Wimbledon green, Roland Garros clay, US Open blue
- **Sophisticated Typography** — Serif headlines, monospace scores
- **Spring-based Animations** — Smooth, natural motion
- **Haptic Feedback** — Tactile response for scoring and undo
- **Match-win Confetti** — Celebratory particle system
- **Dark Mode** — Dark-first design with adaptive colors

## 🏗️ Architecture

### SwiftData Persistence
- **@Model** — Modern Swift data persistence
- **Real-time Updates** — UI automatically reflects data changes
- **Relationships** — Matches linked to opponents and surfaces
- **Efficient Queries** — Sorted and filtered with SwiftData predicates

### MVVM Pattern
- **ViewModels** — Separate business logic from UI
- **@Observable** — Modern state management with observation framework
- **Service Layer** — Reusable components for match logic
- **Clean Separation** — Testable, maintainable code

### File Structure
```
FirstServe/
├── App/
│   └── FirstServeApp.swift      # App entry + SwiftData container
│
├── Models/ (3 files)
│   ├── Match.swift              # @Model for match data
│   ├── Surface.swift            # Court surface enum
│   └── MatchStatistics.swift    # Computed stats
│
├── ViewModels/ (3 files)
│   ├── HomeViewModel.swift      # Home screen logic
│   ├── LiveMatchViewModel.swift # Live scoring logic
│   └── HistoryViewModel.swift   # Match history logic
│
├── Views/
│   ├── HomeView.swift           # Landing screen
│   ├── LiveMatchView.swift      # Match in progress
│   ├── HistoryView.swift        # Past matches
│   ├── StatsView.swift          # Aggregate statistics
│   └── Components/              # Reusable UI components
│
├── Services/
│   └── ScoringService.swift     # Match scoring logic
│
├── Extensions/
│   └── Match+Accessibility.swift
│
└── Theme/
    └── AppTheme.swift           # Court Nouveau design system

FirstServeTests/                 # 30+ unit tests
FirstServeUITests/               # 6 UI automation tests
```

## 🎨 Design System: "Court Nouveau"

### Color Palette
Inspired by iconic tennis venues:
- **Wimbledon Green** — Primary accent
- **Roland Garros Clay** — Warm earth tones
- **US Open Blue** — Cool, modern
- **Australian Open Court** — Vibrant, energetic
- **Neutral Surfaces** — Adaptive backgrounds with elevation

### Typography
- **Headlines** — Serif fonts for editorial feel
- **Body Text** — San Francisco for readability
- **Scores** — Monospace for alignment and clarity
- **Dynamic Type** — Full support for accessibility

### Animations
- **Spring Physics** — Natural, bouncy motion
- **Score Transitions** — Animated point changes
- **Confetti System** — Celebratory particles on match win
- **Appear Animations** — Staggered offsets for list items
- **Haptic Feedback** — Synced with visual changes

## 🛠️ Tech Stack

**Core:**
- SwiftUI (100%, no UIKit)
- SwiftData (local persistence)
- Swift 5.9+
- iOS 15.0+ deployment target

**Features:**
- @Observable (modern state management)
- Swift Charts (future: trend visualization)
- VoiceOver (full accessibility)
- UIActivityViewController (social sharing)
- Haptic Engine (tactile feedback)

**Testing:**
- XCTest (unit + UI tests)
- 1,012 lines of test coverage
- 30+ unit tests
- 6 UI automation tests

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- macOS Sonoma or later
- iPhone or iPad running iOS 15.0+

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

3. **Run the app**
   - Select an iOS simulator or device
   - Press `Cmd+R` to build and run

### Testing

```bash
# Run all tests in Xcode: Cmd+U
# Or via command line:
xcodebuild test -project FirstServe.xcodeproj -scheme FirstServe
```

**Test Coverage:**
- 30+ unit tests (ViewModels, scoring logic, stats calculations)
- 6 UI tests (navigation, match flow, history)
- 1,012 lines of test code

## 🎾 How It Works

### Starting a Match

1. **Opponent Name** — Enter your opponent's name
2. **Surface Selection** — Choose Hard, Clay, Grass, or Carpet
3. **Match Format** — Select best-of-3 or best-of-5 sets
4. **Start Match** — Tap to begin live scoring

### Live Scoring

- **Tap Score Buttons** — Award points to yourself or opponent
- **Track Stats** — Record aces, double faults, winners, errors
- **Undo Mistakes** — Reverse incorrect scores with undo button
- **View Set Score** — Current set score displayed prominently
- **Match Progress** — Sets won shown at the top

### Match Completion

1. **Final Point Scored** — Match automatically completes
2. **Confetti Celebration** — Particle effects for victory
3. **Stats Summary** — View complete match statistics
4. **Share Result** — Post to social media (optional)
5. **Save to History** — Match stored in SwiftData

## 📊 Statistics

### Calculated Metrics
- **Win/Loss Record** — Overall and by surface
- **Head-to-head** — Records against specific opponents
- **Service Stats:**
  - Aces per match
  - Double faults per match
  - Service games won
- **Groundstroke Stats:**
  - Winners per match
  - Unforced errors per match
- **Break Point Conversion** — Success rate on break opportunities

### Future Premium Stats (planned)
- First serve percentage
- Break point save percentage
- Trend graphs over time
- PDF match reports
- Apple Watch quick scoring

## 🚢 App Store Readiness

| Requirement | Status | Notes |
|-------------|--------|-------|
| Core features (MVP) | ✅ | Complete |
| Polish (animations, haptics, confetti) | ✅ | Complete |
| VoiceOver accessibility | ✅ | Complete |
| Social sharing | ✅ | Complete |
| Unit tests | ✅ | 30+ passing |
| UI tests | ✅ | 6 passing |
| README | ✅ | Comprehensive |
| App icon | ✅ | Present |
| Screenshots | ❌ | **Needs capture** |
| Privacy policy | ❌ | **Needs URL** |

**Ready to ship** pending screenshots and privacy policy setup.

## 📊 Status

**Version:** 1.0 (MVP complete)  
**Status:** 🎉 **Ship-ready!** All coding complete, awaiting final assets

### Recent Development (February 2026)
- ✅ MVP features (scoring, stats, history, undo)
- ✅ Polish (haptic feedback, animations, confetti)
- ✅ VoiceOver accessibility (comprehensive support)
- ✅ Social sharing (Twitter/X integration)
- ✅ Tests (30+ unit, 6 UI)
- ✅ README (comprehensive documentation)

### Open Pull Requests
- **PR #5:** Match Result Sharing (1 day old) — ✅ Ready
- **PR #4:** VoiceOver Accessibility (1 day old) — ✅ Ready
- **PR #3:** Polish (haptics, animations, confetti) (4 days old) — ✅ Ready
- **PR #2:** UI tests + README (5 days old) — Superseded by #3

**Recommended Merge Order:**
1. PR #3 (polish — foundation for other features)
2. PR #4 (accessibility)
3. PR #5 (sharing)
4. Close PR #2 (superseded)

## 💰 Monetization Strategy

### Free Version (v1.0)
- All core features included
- Unlimited matches
- Full statistics
- No ads

### Premium Features (Future)
- Apple Watch companion app
- Visual share cards (image with score)
- iCloud sync for cross-device
- Advanced stats (first serve %, trends)
- PDF match reports
- Head-to-head graphs

**Price:** $2.99/month or $9.99 lifetime

## 🎯 Roadmap

### v1.0 (Current)
- [x] Live match scoring
- [x] Match history
- [x] Aggregate statistics
- [x] VoiceOver accessibility
- [x] Social sharing

### v1.1 (Future)
- [ ] Apple Watch quick scoring
- [ ] Visual share card generation
- [ ] iCloud sync
- [ ] Dark mode refinements

### v2.0 (Premium)
- [ ] Advanced statistics
- [ ] First serve percentage
- [ ] Break point conversion tracking
- [ ] Trend graphs (Swift Charts)
- [ ] PDF match reports
- [ ] In-app purchases (StoreKit)

## 🤝 Contributing

This is a private repository. For access or questions, contact the repository owner.

## 📝 License

Private — All rights reserved.

---

**Built with ❤️ for tennis players who love tracking their game.**
