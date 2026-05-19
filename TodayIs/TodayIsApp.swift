//
//  TodayIsApp.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

@main
struct TodayIsApp: App {
    @State private var showSplash = true

    private let modelContainer: ModelContainer = {
        do {
            return try makeTodayIsModelContainer()
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                if showSplash {
                    SplashView(isShowing: $showSplash)
                        .transition(.opacity)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
