//
//  ShotPickerView.swift
//  FirstServe
//
//  Enhanced with Court Nouveau styling and smooth animations
//  Created by Cici on 2/13/26.
//

import SwiftUI

struct ShotPickerView: View {
    let statType: StatType
    let playerName: String
    let onSelect: (ShotType, ContactType) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedShotType: ShotType?
    @State private var selectedContactType: ContactType?
    @State private var appearAnimation = false
    
    // Quick combos for fast selection
    private let quickCombos: [(ShotType, ContactType)] = [
        (.forehand, .groundstroke),
        (.backhand, .groundstroke),
        (.forehand, .volley),
        (.backhand, .volley),
        (.forehand, .overhead)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                FSColors.backgroundDeep
                    .ignoresSafeArea()
                
                FSNetPattern(opacity: 0.02)
                    .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        // Stat type icon
                        ZStack {
                            Circle()
                                .fill(statColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: statIcon)
                                .font(.system(size: 36))
                                .foregroundStyle(statColor)
                        }
                        .scaleEffect(appearAnimation ? 1.0 : 0.5)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: appearAnimation)
                        
                        VStack(spacing: 6) {
                            Text(playerName)
                                .font(FSTypography.headline(24))
                                .foregroundStyle(FSColors.textPrimary)
                            
                            Text(statType.rawValue.uppercased())
                                .font(FSTypography.label(11))
                                .tracking(2)
                                .foregroundStyle(statColor)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appearAnimation)
                        
                        Text("Select shot type")
                            .font(FSTypography.body(14))
                            .foregroundStyle(FSColors.textSecondary)
                            .opacity(appearAnimation ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appearAnimation)
                    }
                    .padding(.top, 20)
                    
                    // Quick selection grid
                    VStack(spacing: 20) {
                        Text("QUICK SELECT")
                            .font(FSTypography.label(10))
                            .tracking(2)
                            .foregroundStyle(FSColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .opacity(appearAnimation ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: appearAnimation)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(Array(quickCombos.enumerated()), id: \.offset) { index, combo in
                                let (shotType, contactType) = combo
                                
                                shotSelectionButton(
                                    shotType: shotType,
                                    contactType: contactType,
                                    index: index
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(FSColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Shot Selection Button
    
    private func shotSelectionButton(shotType: ShotType, contactType: ContactType, index: Int) -> some View {
        Button {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Brief scale animation on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                selectShot(shotType: shotType, contactType: contactType)
            }
        } label: {
            VStack(spacing: 12) {
                // Shot icon
                Text(shotIcon(shotType: shotType, contactType: contactType))
                    .font(.system(size: 40))
                
                // Labels
                VStack(spacing: 4) {
                    Text(shotType.rawValue)
                        .font(FSTypography.body(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(FSColors.textPrimary)
                    
                    Text(contactType.rawValue)
                        .font(FSTypography.label(10))
                        .foregroundStyle(FSColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FSColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(statColor.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(ShotPickerButtonStyle())
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.4 + Double(index) * 0.05), value: appearAnimation)
        .accessibilityLabel("\(shotType.rawValue) \(contactType.rawValue)")
    }
    
    // MARK: - Helper Methods
    
    private func selectShot(shotType: ShotType, contactType: ContactType) {
        onSelect(shotType, contactType)
        dismiss()
    }
    
    private func shotIcon(shotType: ShotType, contactType: ContactType) -> String {
        switch (shotType, contactType) {
        case (.forehand, .groundstroke): return "🎾"
        case (.backhand, .groundstroke): return "🎾"
        case (.forehand, .volley): return "⚡️"
        case (.backhand, .volley): return "⚡️"
        case (.forehand, .overhead): return "💥"
        case (.backhand, _): return "🎾"
        }
    }
    
    private var statIcon: String {
        statType == .winner ? "star.fill" : "exclamationmark.triangle.fill"
    }
    
    private var statColor: Color {
        statType == .winner ? FSColors.winner : FSColors.fault
    }
}

// MARK: - Custom Button Style

struct ShotPickerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ShotPickerView(statType: .winner, playerName: "Cam") { shotType, contactType in
        print("\(shotType) - \(contactType)")
    }
}
