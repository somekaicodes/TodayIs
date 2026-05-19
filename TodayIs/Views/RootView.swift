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

    private var selectedCalendar: GoalCalendar? {
        if let selectedID,
           let calendar = calendars.first(where: { $0.id == selectedID }) {
            return calendar
        }
        return calendars.first
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
        .onAppear(perform: refreshSelection)
        .onChange(of: calendars.map(\.id)) { _, _ in
            refreshSelection()
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
