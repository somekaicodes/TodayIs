//
//  RootView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var calendars: [GoalCalendar]
    @State private var selectedID: UUID?
    @State private var showNewCalendar = false
    @State private var showSidebar = false
    @Environment(\.scenePhase) private var scenePhase

    private var selectedCalendar: GoalCalendar? {
        if let selectedID,
           let calendar = calendars.first(where: { $0.id == selectedID }) {
            return calendar
        }
        return calendars.first
    }

    // Key that changes whenever any calendar's id, title or startDate
    // changes — used to trigger widget-data re-sync.
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewCalendar = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            refreshSelection()
            consumePendingCalendarSelection()
        }
        .onChange(of: calendars.map(\.id)) { _, _ in
            refreshSelection()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumePendingCalendarSelection() }
        }
        .task(id: widgetSyncKey) {
            syncWidgetData(calendars: calendars)
        }
        .sheet(isPresented: $showSidebar) {
            SidebarView(selectedID: $selectedID)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showNewCalendar) {
            NewCalendarView(selectedID: $selectedID)
                .presentationDetents([.medium])
        }
    }

    private func refreshSelection() {
        if let selectedID, calendars.contains(where: { $0.id == selectedID }) {
            return
        }
        selectedID = calendars.first?.id
    }

    /// Picks up a calendar ID written by the widget's OpenGoalIntent
    /// (in shared App Group UserDefaults) and switches the visible goal.
    ///
    /// The widget's `perform()` runs in the widget-extension process, so
    /// there's a small lag before its UserDefaults write is visible here.
    /// Retry a few times to absorb the cross-process sync delay.
    private func consumePendingCalendarSelection() {
        Task { @MainActor in
            for attempt in 0..<6 {
                if attempt > 0 {
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
                }
                guard let defaults = UserDefaults(suiteName: appGroupID),
                      let idStr = defaults.string(forKey: "pending_calendar_id"),
                      let id = UUID(uuidString: idStr) else { continue }
                defaults.removeObject(forKey: "pending_calendar_id")
                if calendars.contains(where: { $0.id == id }) {
                    selectedID = id
                }
                return
            }
        }
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
}
