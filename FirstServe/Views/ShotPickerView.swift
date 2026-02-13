//
//  ShotPickerView.swift
//  FirstServe
//
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
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(statType == .winner ? "🎯" : "⚠️")
                        .font(.system(size: 48))
                    
                    Text("\(playerName) - \(statType.rawValue)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select shot type")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Quick selection grid
                VStack(spacing: 16) {
                    Text("Quick Select")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(quickCombos.indices, id: \.self) { index in
                            let (shotType, contactType) = quickCombos[index]
                            
                            Button {
                                selectShot(shotType: shotType, contactType: contactType)
                            } label: {
                                VStack(spacing: 8) {
                                    Text(shotIcon(shotType: shotType, contactType: contactType))
                                        .font(.system(size: 32))
                                    
                                    VStack(spacing: 2) {
                                        Text(shotType.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(contactType.rawValue)
                                            .font(.caption2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Cancel button
                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shotIcon(shotType: ShotType, contactType: ContactType) -> String {
        switch (shotType, contactType) {
        case (.forehand, .groundstroke):
            return "🏸"  // Forehand groundstroke
        case (.backhand, .groundstroke):
            return "🎾"  // Backhand groundstroke
        case (.forehand, .volley):
            return "⚡️"  // Forehand volley
        case (.backhand, .volley):
            return "💨"  // Backhand volley
        case (_, .overhead):
            return "💥"  // Overhead
        default:
            return "🎯"
        }
    }
    
    private func selectShot(shotType: ShotType, contactType: ContactType) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Call the selection handler
        onSelect(shotType, contactType)
        
        // Dismiss after a brief delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

#Preview {
    ShotPickerView(
        statType: .winner,
        playerName: "Cam",
        onSelect: { _, _ in }
    )
}
