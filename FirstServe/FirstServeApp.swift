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
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Match.self, Player.self, TennisSet.self, Game.self])
    }
}
