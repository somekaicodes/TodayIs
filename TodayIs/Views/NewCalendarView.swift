//
//  NewCalendarView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftUI

struct NewCalendarView: View {
    @Environment(GoalStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title     = ""
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
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        store.add(title: title.trimmingCharacters(in: .whitespaces), startDate: startDate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewCalendarView().environment(GoalStore())
}
