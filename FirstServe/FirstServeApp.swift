//
//  FirstServeApp.swift
//  FirstServe
//
//  Created by Cici on 1/30/26.
//

import SwiftUI
import SwiftData

@main
struct FirstServeApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashScreenView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    })
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
    }
}
