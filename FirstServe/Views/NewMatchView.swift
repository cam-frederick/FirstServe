//
//  NewMatchView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

private enum PlayerField: Hashable {
    case player1, player2
}

struct NewMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Player.name) private var allPlayers: [Player]

    var onMatchCreated: ((Match) -> Void)?

    @State private var player1Name = ""
    @State private var player2Name = ""
    @FocusState private var focusedField: PlayerField?
    @State private var selectedSurface: CourtSurface = .hardCourt
    @State private var selectedFormat: MatchFormat = .bestOf3
    @State private var selectedScoringStyle: ScoringStyle = .advantage
    @State private var selectedRegularTiebreakType: TiebreakType = .regular
    @State private var useFinalSetTiebreak = false
    @State private var selectedFinalSetTiebreakType: TiebreakType = .matchTiebreak
    @State private var location = ""
    @State private var player1ServesFirst = true
    @State private var selectedScoringMode: ScoringMode = .fullStats

    @State private var viewModel = MatchViewModel()
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich dark background
                FSColors.backgroundDeep
                    .ignoresSafeArea()

                FSGradients.meshBackground
                    .ignoresSafeArea()
                    .opacity(0.6)

                FSNetPattern(opacity: 0.02)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.bottom, 28)

                        VStack(spacing: 24) {
                            // Players
                            playersCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            // First serve selector
                            if bothPlayersEntered {
                                firstServeCard
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                        removal: .opacity
                                    ))
                            }

                            // Surface
                            surfaceCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.05), value: appearAnimation)

                            // Match Format
                            formatCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                            // Scoring Mode
                            scoringModeCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)

                            // Scoring Rules
                            if selectedScoringMode != .gamesOnly {
                                scoringRulesCard
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                        removal: .opacity
                                    ))
                            }

                            // Location
                            locationCard
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

                            // Start Match
                            startMatchButton
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.25), value: appearAnimation)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(FSTypography.label(14))
                            .foregroundStyle(FSColors.textSecondary)
                    }
                }
            }
        }
        .colorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEW MATCH")
                        .font(FSTypography.label(11))
                        .tracking(4)
                        .foregroundStyle(FSColors.textMuted)

                    Text("Set Up\nYour Game")
                        .font(FSTypography.headline(32))
                        .foregroundStyle(FSColors.textPrimary)
                        .lineSpacing(2)
                }

                Spacer()

                // Tennis ball decorative element
                ZStack {
                    Circle()
                        .fill(FSColors.ballYellow.opacity(0.08))
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [FSColors.ballYellow, FSColors.ballYellow.opacity(0.6)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: FSColors.ballYellow.opacity(0.3), radius: 12)
                }
                .padding(.top, 8)
            }

            CourtLineAccent(width: 60)
                .opacity(appearAnimation ? 1 : 0)
                .offset(x: appearAnimation ? 0 : -20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Players Card

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Players", icon: "person.2.fill")

            VStack(spacing: 12) {
                // Player 1
                playerInputRow(
                    placeholder: "Your Name",
                    text: $player1Name,
                    accentColor: FSColors.courtGreenLight,
                    field: .player1,
                    accessibilityId: "player1NameField"
                )

                if focusedField == .player1 {
                    playerSuggestions(for: player1Name, excluding: player2Name) { name in
                        player1Name = name
                        focusedField = .player2
                    }
                }

                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(FSColors.lineWhite.opacity(0.06))
                        .frame(height: 1)
                    Text("VS")
                        .font(FSTypography.label(10))
                        .tracking(2)
                        .foregroundStyle(FSColors.textMuted)
                    Rectangle()
                        .fill(FSColors.lineWhite.opacity(0.06))
                        .frame(height: 1)
                }

                // Player 2
                playerInputRow(
                    placeholder: "Opponent Name",
                    text: $player2Name,
                    accentColor: FSColors.hardCourtLight,
                    field: .player2,
                    accessibilityId: "player2NameField"
                )

                if focusedField == .player2 {
                    playerSuggestions(for: player2Name, excluding: player1Name) { name in
                        player2Name = name
                        focusedField = nil
                    }
                }
            }
        }
        .sectionCard()
        .animation(.easeInOut(duration: 0.2), value: focusedField)
    }

    @ViewBuilder
    private func playerInputRow(
        placeholder: String,
        text: Binding<String>,
        accentColor: Color,
        field: PlayerField,
        accessibilityId: String
    ) -> some View {
        HStack(spacing: 14) {
            // Player icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            TextField(placeholder, text: text)
                .font(FSTypography.body(16))
                .foregroundStyle(FSColors.textPrimary)
                .tint(FSColors.ace)
                .textContentType(.name)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(accessibilityId)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FSColors.backgroundDeep.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            focusedField == field ? accentColor.opacity(0.4) : FSColors.lineWhite.opacity(0.06),
                            lineWidth: focusedField == field ? 1.5 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focusedField)
    }

    @ViewBuilder
    private func playerSuggestions(
        for query: String,
        excluding otherName: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        let filtered = filteredPlayers(query: query, excluding: otherName)
        if !filtered.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filtered) { player in
                        Button {
                            onSelect(player.name)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 12))
                                Text(player.name)
                                    .font(FSTypography.label(13))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(FSColors.championship.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(FSColors.championship.opacity(0.25), lineWidth: 0.5)
                                    )
                            )
                            .foregroundStyle(FSColors.championship)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - First Serve Card

    private var firstServeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("First Serve", icon: "tennisball.fill")

            Text("Who serves first?")
                .font(FSTypography.body(14))
                .foregroundStyle(FSColors.textSecondary)

            HStack(spacing: 10) {
                serveToggleButton(
                    name: player1Name.trimmingCharacters(in: .whitespaces),
                    isSelected: player1ServesFirst
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        player1ServesFirst = true
                    }
                }

                serveToggleButton(
                    name: player2Name.trimmingCharacters(in: .whitespaces),
                    isSelected: !player1ServesFirst
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        player1ServesFirst = false
                    }
                }
            }
        }
        .sectionCard()
    }

    private func serveToggleButton(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? FSColors.ballYellow : FSColors.textMuted.opacity(0.2))
                        .frame(width: 10, height: 10)

                    if isSelected {
                        Circle()
                            .stroke(FSColors.ballYellow.opacity(0.4), lineWidth: 3)
                            .frame(width: 18, height: 18)
                    }
                }
                .frame(width: 22)

                Text(name)
                    .font(FSTypography.label(14))
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textSecondary)

                Spacer()

                if isSelected {
                    Image(systemName: "tennisball.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(FSColors.ballYellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? FSColors.backgroundElevated : FSColors.backgroundDeep.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? FSColors.ballYellow.opacity(0.3) : FSColors.lineWhite.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name) serves first")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Surface Card

    private var surfaceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Court Surface", icon: "sportscourt.fill")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(CourtSurface.allCases, id: \.self) { surface in
                    surfaceTile(surface)
                }
            }
        }
        .sectionCard()
    }

    private func surfaceTile(_ surface: CourtSurface) -> some View {
        let isSelected = selectedSurface == surface
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSurface = surface
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(surface.themeColor.opacity(isSelected ? 0.25 : 0.1))
                        .frame(height: 44)

                    Image(systemName: surface.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(surface.themeColor.opacity(isSelected ? 1 : 0.5))
                }

                Text(surface.rawValue)
                    .font(FSTypography.label(12))
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? FSColors.backgroundElevated : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? surface.themeColor.opacity(0.4) : FSColors.lineWhite.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(surface.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Format Card

    private var formatCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Match Format", icon: "flag.checkered.2.crossed")

            VStack(spacing: 8) {
                ForEach(MatchFormat.allCases, id: \.self) { format in
                    formatRow(format)
                }
            }
        }
        .sectionCard()
    }

    private func formatRow(_ format: MatchFormat) -> some View {
        let isSelected = selectedFormat == format
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFormat = format
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? FSColors.championship : FSColors.textMuted.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(FSColors.championship)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(format.displayName)
                        .font(FSTypography.body(15))
                        .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textSecondary)

                    Text(formatSubtitle(format))
                        .font(FSTypography.label(11))
                        .foregroundStyle(FSColors.textMuted)
                }

                Spacer()

                // Visual set indicator
                HStack(spacing: 4) {
                    ForEach(0..<setsForFormat(format), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? FSColors.championship.opacity(0.6) : FSColors.textMuted.opacity(0.2))
                            .frame(width: 14, height: 6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? FSColors.championship.opacity(0.06) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? FSColors.championship.opacity(0.2) : FSColors.lineWhite.opacity(0.04),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(format.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func formatSubtitle(_ format: MatchFormat) -> String {
        switch format {
        case .singleSet: return "One set to 6 games"
        case .superSet: return "One set to 8 games"
        case .bestOf3: return "First to win 2 sets"
        case .bestOf5: return "First to win 3 sets"
        }
    }

    private func setsForFormat(_ format: MatchFormat) -> Int {
        switch format {
        case .singleSet, .superSet: return 1
        case .bestOf3: return 3
        case .bestOf5: return 5
        }
    }

    // MARK: - Scoring Mode Card

    private var scoringModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Tracking Level", icon: "gauge.with.dots.needle.33percent")

            Text("How much do you want to track?")
                .font(FSTypography.body(14))
                .foregroundStyle(FSColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(ScoringMode.allCases, id: \.self) { mode in
                    scoringModeTile(mode)
                }
            }

            // Description
            HStack(spacing: 8) {
                Image(systemName: scoringModeIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(FSColors.textMuted)

                Text(scoringModeDescription)
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(FSColors.backgroundDeep.opacity(0.5))
            )
            .animation(.easeInOut(duration: 0.2), value: selectedScoringMode)
        }
        .sectionCard()
    }

    private func scoringModeTile(_ mode: ScoringMode) -> some View {
        let isSelected = selectedScoringMode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedScoringMode = mode
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: scoringModeSystemIcon(mode))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? FSColors.ace : FSColors.textMuted)

                Text(mode.rawValue)
                    .font(FSTypography.label(11))
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? FSColors.ace.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? FSColors.ace.opacity(0.35) : FSColors.lineWhite.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func scoringModeSystemIcon(_ mode: ScoringMode) -> String {
        switch mode {
        case .gamesOnly: return "number"
        case .pointByPoint: return "target"
        case .fullStats: return "chart.bar.fill"
        }
    }

    private var scoringModeIcon: String {
        switch selectedScoringMode {
        case .gamesOnly: return "info.circle"
        case .pointByPoint: return "info.circle"
        case .fullStats: return "sparkles"
        }
    }

    // MARK: - Scoring Rules Card

    private var scoringRulesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Scoring Rules", icon: "dial.medium.fill")

            // Deuce scoring
            VStack(alignment: .leading, spacing: 10) {
                Text("Deuce Scoring")
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.textSecondary)

                HStack(spacing: 8) {
                    ruleToggleButton(
                        label: "Advantage",
                        subtitle: "Traditional",
                        isSelected: selectedScoringStyle == .advantage,
                        color: FSColors.courtGreenLight
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedScoringStyle = .advantage
                        }
                    }

                    ruleToggleButton(
                        label: "No-Ad",
                        subtitle: "Sudden Death",
                        isSelected: selectedScoringStyle == .noAdvantage,
                        color: FSColors.fault
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedScoringStyle = .noAdvantage
                        }
                    }
                }

                if selectedScoringStyle == .noAdvantage {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(FSColors.fault)
                        Text("Deuce is sudden death - one point decides the game")
                            .font(FSTypography.label(11))
                            .foregroundStyle(FSColors.textMuted)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FSColors.fault.opacity(0.06))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Separator
            Rectangle()
                .fill(FSColors.lineWhite.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 4)

            // Tiebreak type
            VStack(alignment: .leading, spacing: 10) {
                Text("Regular Tiebreak")
                    .font(FSTypography.label(12))
                    .foregroundStyle(FSColors.textSecondary)

                HStack(spacing: 8) {
                    ruleToggleButton(
                        label: "7 Points",
                        subtitle: "Standard",
                        isSelected: selectedRegularTiebreakType == .regular,
                        color: FSColors.ballYellow
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRegularTiebreakType = .regular
                        }
                    }

                    ruleToggleButton(
                        label: "10 Points",
                        subtitle: "Extended",
                        isSelected: selectedRegularTiebreakType == .extended,
                        color: FSColors.ballYellow
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRegularTiebreakType = .extended
                        }
                    }
                }
            }

            // Final set tiebreak (only for multi-set formats)
            if selectedFormat == .bestOf3 || selectedFormat == .bestOf5 {
                Rectangle()
                    .fill(FSColors.lineWhite.opacity(0.06))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Match Tiebreak")
                                .font(FSTypography.label(12))
                                .foregroundStyle(FSColors.textSecondary)

                            Text("Replace final set with a tiebreak")
                                .font(FSTypography.label(11))
                                .foregroundStyle(FSColors.textMuted)
                        }

                        Spacer()

                        // Custom toggle
                        fsToggle(isOn: $useFinalSetTiebreak, color: FSColors.ace)
                    }

                    if useFinalSetTiebreak {
                        HStack(spacing: 8) {
                            Image(systemName: "flag.2.crossed.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(FSColors.ace)
                            Text("First to 10 points, win by 2")
                                .font(FSTypography.label(12))
                                .foregroundStyle(FSColors.textMuted)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FSColors.ace.opacity(0.06))
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: useFinalSetTiebreak)
            }
        }
        .sectionCard()
        .animation(.easeInOut(duration: 0.2), value: selectedScoringStyle)
    }

    private func ruleToggleButton(
        label: String,
        subtitle: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(FSTypography.label(14))
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textSecondary)

                Text(subtitle)
                    .font(FSTypography.label(10))
                    .foregroundStyle(FSColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? color.opacity(0.35) : FSColors.lineWhite.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Location", icon: "location.fill")

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(FSColors.textMuted.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "mappin")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FSColors.textMuted)
                }

                TextField("Where are you playing? (optional)", text: $location)
                    .font(FSTypography.body(15))
                    .foregroundStyle(FSColors.textPrimary)
                    .tint(FSColors.ace)
                    .textContentType(.location)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(FSColors.backgroundDeep.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .sectionCard()
    }

    // MARK: - Start Match Button

    private var startMatchButton: some View {
        Button {
            startMatch()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "tennisball.fill")
                    .font(.system(size: 16, weight: .bold))

                Text("START MATCH")
                    .font(FSTypography.label(16))
                    .fontWeight(.bold)
                    .tracking(2)
            }
            .foregroundStyle(canStartMatch ? FSColors.textPrimary : FSColors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        canStartMatch
                            ? AnyShapeStyle(LinearGradient(
                                colors: [FSColors.courtGreen, FSColors.courtGreenLight.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(FSColors.backgroundCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                canStartMatch ? FSColors.courtGreenLight.opacity(0.3) : FSColors.lineWhite.opacity(0.06),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: canStartMatch ? FSColors.courtGreen.opacity(0.4) : Color.clear,
                radius: 20, y: 8
            )
        }
        .disabled(!canStartMatch)
        .scaleEffect(canStartMatch ? 1 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canStartMatch)
        .accessibilityIdentifier("startMatchButton")
    }

    // MARK: - Shared Components

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FSColors.championship)

            Text(title.uppercased())
                .font(FSTypography.label(11))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
        }
    }

    private func fsToggle(isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                Capsule()
                    .fill(isOn.wrappedValue ? color.opacity(0.35) : FSColors.backgroundDeep)
                    .overlay(
                        Capsule()
                            .stroke(isOn.wrappedValue ? color.opacity(0.5) : FSColors.textMuted.opacity(0.3), lineWidth: 1.5)
                    )
                    .frame(width: 52, height: 30)

                Circle()
                    .fill(isOn.wrappedValue ? color : FSColors.textMuted)
                    .frame(width: 24, height: 24)
                    .padding(3)
                    .shadow(color: isOn.wrappedValue ? color.opacity(0.5) : Color.clear, radius: 6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn.wrappedValue ? .isSelected : [])
    }

    // MARK: - Computed

    private var bothPlayersEntered: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canStartMatch: Bool {
        bothPlayersEntered
    }

    private var scoringModeDescription: String {
        switch selectedScoringMode {
        case .gamesOnly:
            return "Just tap to award games — simplest tracking."
        case .pointByPoint:
            return "Track points within each game — standard scoring."
        case .fullStats:
            return "Full details: serves, winners, errors, and shot types."
        }
    }

    // MARK: - Player Filtering

    private func filteredPlayers(query: String, excluding otherName: String) -> [Player] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let otherTrimmed = otherName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allPlayers.filter { player in
            let name = player.name.lowercased()
            guard name != otherTrimmed else { return false }
            return trimmed.isEmpty || name.hasPrefix(trimmed)
        }
    }

    // MARK: - Logic

    private func startMatch() {
        viewModel.configure(context: modelContext)
        viewModel.startNewMatch(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            surface: selectedSurface,
            scoringMode: selectedScoringMode,
            scoringStyle: selectedScoringStyle,
            regularTiebreakType: selectedRegularTiebreakType,
            finalSetTiebreakType: useFinalSetTiebreak ? selectedFinalSetTiebreakType : nil,
            player1ServesFirst: player1ServesFirst
        )

        if !location.isEmpty {
            viewModel.currentMatch?.location = location.trimmingCharacters(in: .whitespaces)
            try? modelContext.save()
        }

        if let match = viewModel.currentMatch {
            onMatchCreated?(match)
        }
        dismiss()
    }
}

// MARK: - Section Card Modifier

private struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
    }
}

private extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }
}

#Preview {
    NewMatchView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self])
}
