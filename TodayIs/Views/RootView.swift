//
//  RootView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var calendars: [GoalCalendar]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Environment(FirestoreService.self) private var firestoreService

    @State private var selectedID: UUID?
    @State private var showNewCalendar = false
    @State private var showSidebar = false
    @State private var showAccount = false
    @Environment(\.scenePhase) private var scenePhase

    private var selectedCalendar: GoalCalendar? {
        if let selectedID,
           let calendar = calendars.first(where: { $0.id == selectedID }) {
            return calendar
        }
        return calendars.first
    }

    // Key that changes whenever any calendar's id, title or startDate
    // changes — used to trigger widget-data re-sync and Firestore sync.
    private var widgetSyncKey: String {
        calendars
            .map { "\($0.id.uuidString)|\($0.title)|\($0.startDate.timeIntervalSince1970)" }
            .joined(separator: ",")
    }

    var body: some View {
        NavigationStack {
            Group {
                if calendars.isEmpty {
                    EmptyStateView(showNew: $showNewCalendar)
                } else if let calendar = selectedCalendar {
                    CalendarView(calendar: calendar)
                } else {
                    EmptyStateView(showNew: $showNewCalendar)
                }
            }
            .navigationTitle("Today is ...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSidebar = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Account button — filled icon when signed in
                    Button {
                        showAccount = true
                    } label: {
                        Image(systemName: authService.isSignedIn
                              ? "person.crop.circle.fill"
                              : "person.crop.circle")
                    }

                    Button {
                        showNewCalendar = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear(perform: refreshSelection)
        .onChange(of: calendars.map(\.id)) { _, _ in
            refreshSelection()
        }
        .onOpenURL { url in
            // Handles Google Sign-In OAuth redirect AND widget deep-links
            handleDeepLink(url)
        }
        // Widget data + Firestore sync — fires whenever any calendar changes
        .task(id: widgetSyncKey) {
            syncWidgetData(calendars: calendars)
            if let userID = authService.user?.uid {
                await firestoreService.uploadAll(calendars: calendars, userID: userID)
            }
        }
        // On fresh sign-in: pull from Firestore if the user has cloud data,
        // otherwise push local data up. Only fires on the transition nil → uid.
        .onChange(of: authService.user?.uid) { oldUID, newUID in
            handleSignIn(oldUID: oldUID, newUID: newUID)
        }
        .sheet(isPresented: $showSidebar) {
            SidebarView(selectedID: $selectedID)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showNewCalendar) {
            NewCalendarView(selectedID: $selectedID)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAccount) {
            AccountView()
                .environment(authService)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Sign-in sync handler

    private func handleSignIn(oldUID: String?, newUID: String?) {
        guard oldUID == nil, let newUID else { return }
        Task {
            if await firestoreService.hasCloudData(userID: newUID) {
                await loadFromCloud(userID: newUID)
            } else {
                await firestoreService.uploadAll(calendars: calendars, userID: newUID)
            }
        }
    }

    // MARK: - Cloud → local sync

    /// Downloads all calendars from Firestore and replaces local SwiftData.
    /// Called once on sign-in when the user already has cloud data (e.g. signing
    /// in on a second device).
    private func loadFromCloud(userID: String) async {
        guard let results = await firestoreService.downloadAll(userID: userID) else { return }

        for calendar in calendars {
            modelContext.delete(calendar)
        }
        for (calendar, streaks) in results {
            calendar.streakHistory = streaks
            modelContext.insert(calendar)
        }
        try? modelContext.save()
        refreshSelection()
    }

    // MARK: - Helpers

    private func refreshSelection() {
        if let selectedID, calendars.contains(where: { $0.id == selectedID }) { return }
        selectedID = calendars.first?.id
    }

    /// Handles `todayis://goal/<uuid>` deep-links from the widget.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "todayis", url.host == "goal" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let first = parts.first,
              let id = UUID(uuidString: first),
              calendars.contains(where: { $0.id == id }) else { return }
        selectedID = id
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    @Binding var showNew: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No goal calendars yet")
                .font(.title3.weight(.semibold))
            Text("Create your first calendar to start tracking your personal year.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Create a Calendar") {
                showNew = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
        .environment(AuthService())
        .environment(FirestoreService())
}
