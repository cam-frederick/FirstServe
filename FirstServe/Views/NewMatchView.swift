//
//  NewMatchView.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
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
    @State private var selectedScoringStyle: ScoringStyle = .advantage
    @State private var selectedRegularTiebreakType: TiebreakType = .regular
    @State private var useFinalSetTiebreak = false
    @State private var selectedFinalSetTiebreakType: TiebreakType = .matchTiebreak
    @State private var location = ""
    @State private var player1ServesFirst = true
    
    @State private var viewModel = MatchViewModel()
    @State private var navigateToMatch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Rich dark background — Court Nouveau aesthetic
                FSColors.backgroundDeep
                    .ignoresSafeArea()
                
                FSGradients.meshBackground
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                FSNetPattern(opacity: 0.025)
                    .ignoresSafeArea()
                
                Form {
                    // MARK: — Players
                    Section {
                        playerNameField(
                            placeholder: "Your Name",
                            text: $player1Name,
                            icon: "person.fill",
                            iconColor: FSColors.courtGreenLight,
                            accessibilityId: "player1NameField"
                        )
                        playerNameField(
                            placeholder: "Opponent Name",
                            text: $player2Name,
                            icon: "person.fill",
                            iconColor: FSColors.hardCourtLight,
                            accessibilityId: "player2NameField"
                        )
                    } header: {
                        formSectionHeader("Players", icon: "person.2.fill")
                    }
                    .listRowBackground(FSColors.backgroundCard)
                    
                    // MARK: — First Serve (shown once both players are entered)
                    if bothPlayersEntered {
                        Section {
                            formPickerRow(
                                label: "Who serves first?",
                                icon: "tennisball.fill",
                                iconColor: FSColors.ace
                            ) {
                                Picker("Who serves first?", selection: $player1ServesFirst) {
                                    Text(player1Name.trimmingCharacters(in: .whitespaces))
                                        .tag(true)
                                    Text(player2Name.trimmingCharacters(in: .whitespaces))
                                        .tag(false)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        } header: {
                            formSectionHeader("First Serve", icon: "tennisball.fill")
                        }
                        .listRowBackground(FSColors.backgroundCard)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // MARK: — Match Details
                    Section {
                        Picker(selection: $selectedSurface) {
                            ForEach(CourtSurface.allCases, id: \.self) { surface in
                                Text(surface.rawValue).tag(surface)
                            }
                        } label: {
                            iconLabel("Surface", icon: selectedSurface.icon, color: selectedSurface.themeColor)
                        }
                        
                        Picker(selection: $selectedFormat) {
                            ForEach(MatchFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        } label: {
                            iconLabel("Format", icon: "flag.checkered.2.crossed", color: FSColors.championship)
                        }
                        
                        HStack(spacing: 12) {
                            iconBadge("location.fill", color: FSColors.textMuted)
                            TextField("Location (optional)", text: $location)
                                .font(FSTypography.body(15))
                                .foregroundStyle(FSColors.textPrimary)
                                .tint(FSColors.ace)
                                .textContentType(.location)
                        }
                        .padding(.vertical, 2)
                        
                    } header: {
                        formSectionHeader("Match Details", icon: "sportscourt.fill")
                    }
                    .listRowBackground(FSColors.backgroundCard)
                    
                    // MARK: — Scoring Rules
                    Section {
                        Picker(selection: $selectedScoringStyle) {
                            ForEach(ScoringStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        } label: {
                            iconLabel("Deuce Scoring", icon: "arrow.trianglehead.2.clockwise.rotate.90", color: FSColors.courtGreenLight)
                        }
                        
                        Picker(selection: $selectedRegularTiebreakType) {
                            Text("7 Points").tag(TiebreakType.regular)
                            Text("10 Points").tag(TiebreakType.extended)
                        } label: {
                            iconLabel("Regular Tiebreak", icon: "bolt.fill", color: FSColors.ballYellow)
                        }
                        
                        if selectedFormat == .bestOf3 || selectedFormat == .bestOf5 {
                            HStack(spacing: 12) {
                                iconBadge("flag.2.crossed.fill", color: FSColors.fault)
                                Text("Match Tiebreak (Final Set)")
                                    .font(FSTypography.body(15))
                                    .foregroundStyle(FSColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $useFinalSetTiebreak)
                                    .tint(FSColors.ace)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 2)
                            
                            if useFinalSetTiebreak {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(FSColors.textMuted)
                                    Text("First to 10 points, win by 2")
                                        .font(FSTypography.label(12))
                                        .foregroundStyle(FSColors.textMuted)
                                }
                                .padding(.vertical, 2)
                                .padding(.leading, 40)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                    } header: {
                        formSectionHeader("Scoring Rules", icon: "dial.medium.fill")
                    } footer: {
                        if selectedScoringStyle == .noAdvantage {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                    .foregroundStyle(FSColors.fault)
                                    .padding(.top, 1)
                                Text("No-Ad: deuce is sudden death — one point decides the game.")
                                    .font(FSTypography.label(11))
                                    .foregroundStyle(FSColors.textMuted)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .listRowBackground(FSColors.backgroundCard)
                    .animation(.easeInOut(duration: 0.2), value: useFinalSetTiebreak)
                    
                    // MARK: — Start Match CTA
                    Section {
                        Button {
                            startMatch()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "tennisball.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Start Match")
                                    .font(FSTypography.label(16))
                                    .fontWeight(.bold)
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .foregroundStyle(canStartMatch ? FSColors.textPrimary : FSColors.textMuted)
                            .padding(.vertical, 8)
                        }
                        .disabled(!canStartMatch)
                        .accessibilityIdentifier("startMatchButton")
                    }
                    .listRowBackground(
                        canStartMatch
                            ? AnyShapeStyle(LinearGradient(
                                colors: [FSColors.courtGreen, FSColors.courtGreenLight.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing))
                            : AnyShapeStyle(FSColors.backgroundCard)
                    )
                    .animation(.easeInOut(duration: 0.25), value: canStartMatch)
                }
                .scrollContentBackground(.hidden)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: bothPlayersEntered)
            }
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FSColors.backgroundDeep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }
            }
            .navigationDestination(isPresented: $navigateToMatch) {
                if let match = viewModel.currentMatch {
                    LiveMatchView(match: match)
                }
            }
        }
        .colorScheme(.dark)
    }
    
    // MARK: - Computed
    
    private var bothPlayersEntered: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var canStartMatch: Bool {
        bothPlayersEntered
    }
    
    // MARK: - Helper View Builders
    
    @ViewBuilder
    private func playerNameField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        iconColor: Color,
        accessibilityId: String
    ) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
            TextField(placeholder, text: text)
                .font(FSTypography.body(15))
                .foregroundStyle(FSColors.textPrimary)
                .tint(FSColors.ace)
                .textContentType(.name)
                .accessibilityIdentifier(accessibilityId)
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func formPickerRow<Content: View>(
        label: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: iconColor)
            content()
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func iconLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            iconBadge(icon, color: color)
            Text(title)
                .font(FSTypography.body(15))
                .foregroundStyle(FSColors.textPrimary)
        }
    }
    
    @ViewBuilder
    private func iconBadge(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.18))
            )
    }
    
    @ViewBuilder
    private func formSectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(FSColors.championship)
            Text(title.uppercased())
                .font(FSTypography.label(10))
                .tracking(2)
                .foregroundStyle(FSColors.textMuted)
        }
        .textCase(nil)
    }
    
    // MARK: - Logic
    
    private func startMatch() {
        viewModel.configure(context: modelContext)
        viewModel.startNewMatch(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            format: selectedFormat,
            surface: selectedSurface,
            scoringStyle: selectedScoringStyle,
            regularTiebreakType: selectedRegularTiebreakType,
            finalSetTiebreakType: useFinalSetTiebreak ? selectedFinalSetTiebreakType : nil,
            player1ServesFirst: player1ServesFirst
        )
        
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
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self, ShotStatistic.self])
}
