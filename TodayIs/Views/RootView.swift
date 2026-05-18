//
//  RootView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftUI

struct RootView: View {
    @Environment(GoalStore.self) private var store
    @State private var showNewCalendar = false
    @State private var showSidebar     = false
    
    var body: some View {
        @Bindable var st = store
        NavigationStack {
            Group {
                if store.calendars.isEmpty {
                    EmptyStateView(showNew: $showNewCalendar)
                } else if let cal = store.selected {
                    CalendarView(calendar: cal)
                } else {
                    EmptyStateView(showNew: $showNewCalendar)
                }
            }
            .navigationTitle("Today is ...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left: sidebar toggle
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSidebar = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
                // Right: new calendar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewCalendar = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // Sidebar sheet
        .sheet(isPresented: $showSidebar) {
            SidebarView()
                .presentationDetents([.medium, .large])
        }
        // New calendar sheet
        .sheet(isPresented: $showNewCalendar) {
            NewCalendarView()
                .presentationDetents([.medium])
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
    RootView().environment(GoalStore())
}
