//
//  NewCalendarView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct NewCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedID: UUID?

    @State private var title = ""
    @State private var startDate = Calendar.current.startOfDay(for: .now)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Work out every day", text: $title)
                } header: {
                    Text("Goal")
                } footer: {
                    Text("This becomes the calendar's name.")
                }

                Section {
                    DatePicker(
                        "Start date (your 01.01)",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("When does your year begin?")
                } footer: {
                    Text("The real-world date that becomes month 1, day 1 of your personal calendar.")
                }
            }
            .navigationTitle("New Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCalendar()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespaces)
    }

    private func createCalendar() {
        guard !trimmedTitle.isEmpty else { return }
        let calendar = GoalCalendar(title: trimmedTitle, startDate: startDate)
        modelContext.insert(calendar)
        selectedID = calendar.id
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NewCalendarView(selectedID: .constant(nil))
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
}
