//
//  SidebarView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftUI

struct SidebarView: View {
    @Environment(GoalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showNewCalendar   = false
    @State private var showDeleteConfirm = false
    @State private var deleteID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(store.calendars) { cal in
                        SidebarRow(cal: cal) {
                            store.selectedID = cal.id
                            dismiss()
                        } onDelete: {
                            deleteID         = cal.id
                            showDeleteConfirm = true
                        }
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .navigationTitle("My Calendars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewCalendar = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showNewCalendar) {
            NewCalendarView().presentationDetents([.medium])
        }
        .confirmationDialog(
            "Delete this calendar?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let id = deleteID { store.delete(id: id) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Row extracted to its own view to avoid type inference issues

struct SidebarRow: View {
    @Environment(GoalStore.self) private var store
    let cal:      GoalCalendar
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cal.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        let ymd = cal.elapsedYMD()
                        let rec = StreakRecord(
                            years:     ymd.years,
                            months:    ymd.months,
                            days:      ymd.days,
                            savedDate: .now
                        )
                        Text(rec.display)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.selectedID == cal.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .padding(.trailing, 16)
        }
    }
}

#Preview {
    SidebarView().environment(GoalStore())
}
