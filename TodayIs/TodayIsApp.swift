//
//  TodayIsApp.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct TodayIsApp: App {
    @State private var showSplash = true
    @State private var authService: AuthService
    @State private var firestoreService: FirestoreService

    private let modelContainer: ModelContainer = {
        do {
            return try makeTodayIsModelContainer()
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }
    }()

    init() {
        // Configure Firebase FIRST before creating any service that touches Firebase
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
        _firestoreService = State(initialValue: FirestoreService())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(authService)
                    .environment(firestoreService)

                if showSplash {
                    SplashView(isShowing: $showSplash)
                        .transition(.opacity)
                }
            }
            // Required for Google Sign-In to handle the OAuth redirect
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(modelContainer)
    }
}
