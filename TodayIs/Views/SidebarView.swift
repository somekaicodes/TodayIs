//
//  SidebarView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var calendars: [GoalCalendar]
    @Binding var selectedID: UUID?
    @State private var showNewCalendar = false
    @State private var showDeleteConfirm = false
    @State private var deleteID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(calendars) { calendar in
                        SidebarRow(
                            calendar: calendar,
                            isSelected: selectedID == calendar.id
                        ) {
                            selectedID = calendar.id
                            dismiss()
                        } onDelete: {
                            deleteID = calendar.id
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
            NewCalendarView(selectedID: $selectedID)
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Delete this calendar?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteCalendar()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteCalendar() {
        guard let deleteID,
              let calendar = calendars.first(where: { $0.id == deleteID })
        else { return }

        if selectedID == deleteID {
            selectedID = calendars.first(where: { $0.id != deleteID })?.id
        }

        modelContext.delete(calendar)
        try? modelContext.save()
        self.deleteID = nil
    }
}

// MARK: - Row extracted to its own view to avoid type inference issues

struct SidebarRow: View {
    let calendar: GoalCalendar
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(calendar.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        let ymd = calendar.elapsedYMD()
                        let record = StreakRecord(
                            years: ymd.years,
                            months: ymd.months,
                            days: ymd.days,
                            savedDate: .now
                        )
                        Text(record.display)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isSelected {
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
    SidebarView(selectedID: .constant(nil))
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
}
