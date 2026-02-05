//
//  NewMatchView.swift
//  FirstServe
//
//  Court Nouveau - Premium Editorial Tennis Aesthetic
//

import SwiftUI
import SwiftData

struct NewMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var player1Name = ""
    @State private var player2Name = ""
    @State private var selectedSurface: CourtSurface = .hardCourt
    @State private var selectedFormat: MatchFormat = .bestOf3
    @State private var location = ""
    @State private var player1ServesFirst = true

    @State private var viewModel = MatchViewModel()
    @State private var navigateToMatch = false
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FSColors.backgroundDeep
                    .ignoresSafeArea()

                FSNetPattern(opacity: 0.015)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)

                        // Players Section
                        playersSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)

                        // Who Serves First
                        if bothPlayersEntered {
                            serveSelectionSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .opacity(appearAnimation ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.15), value: appearAnimation)
                        }

                        // Match Config
                        matchConfigSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)

                        // Start Button
                        startButton
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FSColors.textSecondary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(FSColors.backgroundCard)
                            )
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToMatch) {
                if let match = viewModel.currentMatch {
                    LiveMatchView(match: match)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEW MATCH")
                .font(FSTypography.label(11))
                .tracking(4)
                .foregroundStyle(FSColors.textMuted)

            Text("Set Up\nYour Game")
                .font(FSTypography.headline(32))
                .foregroundStyle(FSColors.textPrimary)
                .lineSpacing(4)

            CourtLineAccent(width: 60)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Players Section

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionLabel("PLAYERS")

            VStack(spacing: 16) {
                // Player 1
                playerInputField(
                    placeholder: "Your name",
                    text: $player1Name,
                    icon: "person.fill",
                    accentColor: FSColors.hardCourt,
                    playerNumber: 1
                )

                // VS Divider
                HStack {
                    Rectangle()
                        .fill(FSColors.lineWhite.opacity(0.1))
                        .frame(height: 1)

                    Text("VS")
                        .font(FSTypography.label(12))
                        .tracking(3)
                        .foregroundStyle(FSColors.textMuted)
                        .padding(.horizontal, 16)

                    Rectangle()
                        .fill(FSColors.lineWhite.opacity(0.1))
                        .frame(height: 1)
                }

                // Player 2
                playerInputField(
                    placeholder: "Opponent name",
                    text: $player2Name,
                    icon: "person.fill",
                    accentColor: FSColors.clay,
                    playerNumber: 2
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func playerInputField(placeholder: String, text: Binding<String>, icon: String, accentColor: Color, playerNumber: Int) -> some View {
        HStack(spacing: 14) {
            // Player icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PLAYER \(playerNumber)")
                    .font(FSTypography.label(9))
                    .tracking(1.5)
                    .foregroundStyle(FSColors.textMuted)

                TextField("", text: text, prompt: Text(placeholder).foregroundStyle(FSColors.textMuted.opacity(0.6)))
                    .font(FSTypography.body(17))
                    .foregroundStyle(FSColors.textPrimary)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }

            Spacer()

            if !text.wrappedValue.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(FSColors.winner)
            }
        }
    }

    // MARK: - Serve Selection

    private var serveSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("FIRST SERVE")

            HStack(spacing: 12) {
                serveButton(
                    name: player1Name.trimmingCharacters(in: .whitespaces),
                    isSelected: player1ServesFirst,
                    color: FSColors.hardCourt
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        player1ServesFirst = true
                    }
                }

                serveButton(
                    name: player2Name.trimmingCharacters(in: .whitespaces),
                    isSelected: !player1ServesFirst,
                    color: FSColors.clay
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        player1ServesFirst = false
                    }
                }
            }
        }
    }

    private func serveButton(name: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Ball indicator
                Circle()
                    .fill(isSelected ? FSColors.ballYellow : FSColors.textMuted.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .shadow(color: isSelected ? FSColors.ballYellow.opacity(0.5) : .clear, radius: 6)

                Text(name)
                    .font(FSTypography.body(15))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textSecondary)

                Spacer()

                if isSelected {
                    Text("SERVING")
                        .font(FSTypography.label(9))
                        .tracking(1)
                        .foregroundStyle(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? color.opacity(0.12) : FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? color.opacity(0.4) : FSColors.lineWhite.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Match Config

    private var matchConfigSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionLabel("MATCH SETTINGS")

            VStack(spacing: 16) {
                // Surface Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("COURT SURFACE")
                        .font(FSTypography.label(10))
                        .tracking(1)
                        .foregroundStyle(FSColors.textMuted)

                    HStack(spacing: 10) {
                        ForEach(CourtSurface.allCases, id: \.self) { surface in
                            surfaceButton(surface)
                        }
                    }
                }

                Divider()
                    .background(FSColors.lineWhite.opacity(0.08))

                // Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("MATCH FORMAT")
                        .font(FSTypography.label(10))
                        .tracking(1)
                        .foregroundStyle(FSColors.textMuted)

                    HStack(spacing: 12) {
                        ForEach(MatchFormat.allCases, id: \.self) { format in
                            formatButton(format)
                        }
                    }
                }

                Divider()
                    .background(FSColors.lineWhite.opacity(0.08))

                // Location (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCATION (OPTIONAL)")
                        .font(FSTypography.label(10))
                        .tracking(1)
                        .foregroundStyle(FSColors.textMuted)

                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundStyle(FSColors.textMuted)

                        TextField("", text: $location, prompt: Text("Where are you playing?").foregroundStyle(FSColors.textMuted.opacity(0.5)))
                            .font(FSTypography.body(15))
                            .foregroundStyle(FSColors.textPrimary)
                            .textContentType(.location)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FSColors.backgroundElevated)
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private func surfaceButton(_ surface: CourtSurface) -> some View {
        let isSelected = selectedSurface == surface

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSurface = surface
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: surface.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? surface.themeColor : FSColors.textMuted)

                Text(surfaceShortName(surface))
                    .font(FSTypography.label(9))
                    .tracking(0.5)
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? surface.themeColor.opacity(0.15) : FSColors.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? surface.themeColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func surfaceShortName(_ surface: CourtSurface) -> String {
        switch surface {
        case .hardCourt: return "Hard"
        case .clay: return "Clay"
        case .grass: return "Grass"
        case .carpet: return "Carpet"
        }
    }

    private func formatButton(_ format: MatchFormat) -> some View {
        let isSelected = selectedFormat == format

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFormat = format
            }
        } label: {
            VStack(spacing: 6) {
                Text(format == .bestOf3 ? "3" : "5")
                    .font(FSTypography.score(28))
                    .foregroundStyle(isSelected ? FSColors.textPrimary : FSColors.textMuted)

                Text("SETS")
                    .font(FSTypography.label(9))
                    .tracking(1)
                    .foregroundStyle(isSelected ? FSColors.textSecondary : FSColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? FSColors.courtGreen.opacity(0.15) : FSColors.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? FSColors.courtGreen.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            startMatch()
        } label: {
            HStack(spacing: 12) {
                Text("Start Match")
                    .font(FSTypography.label(15))
                    .fontWeight(.bold)
                    .tracking(1)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(canStartMatch ? FSColors.textPrimary : FSColors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canStartMatch ? FSColors.courtGreen : FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(canStartMatch ? FSColors.courtGreen.opacity(0.5) : FSColors.lineWhite.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: canStartMatch ? FSColors.courtGreen.opacity(0.3) : .clear, radius: 15, y: 5)
        }
        .disabled(!canStartMatch)
        .animation(.easeOut(duration: 0.2), value: canStartMatch)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(FSTypography.label(11))
            .tracking(2)
            .foregroundStyle(FSColors.textMuted)
    }

    private var bothPlayersEntered: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canStartMatch: Bool {
        bothPlayersEntered
    }

    private func startMatch() {
        viewModel.configure(context: modelContext)
        viewModel.startNewMatch(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            surface: selectedSurface,
            player1ServesFirst: player1ServesFirst
        )

        // Set location if provided
        if !location.isEmpty {
            viewModel.currentMatch?.location = location.trimmingCharacters(in: .whitespaces)
            try? modelContext.save()
        }

        navigateToMatch = true
        dismiss()
    }
}

#Preview {
    NewMatchView()
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
}
