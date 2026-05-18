//
//  TodayIsApp.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftUI

@main
struct TodayIsApp: App {
    @State private var store       = GoalStore()
    @State private var showSplash  = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(store)

                if showSplash {
                    SplashView(isShowing: $showSplash)
                        .transition(.opacity)
                }
            }
        }
    }
}
