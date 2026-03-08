//
//  FirstServeWatchApp.swift
//  FirstServe Watch
//

import SwiftUI

@main
struct FirstServeWatchApp: App {
    @State private var sessionService = WatchSessionService()

    var body: some Scene {
        WindowGroup {
            WatchMatchListView()
                .environment(sessionService)
        }
    }
}
