//
//  ResetView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct ResetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let calendar: GoalCalendar

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let ymd = calendar.elapsedYMD()
                    let record = StreakRecord(years: ymd.years, months: ymd.months, days: ymd.days, savedDate: .now)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your current streak of")
                            .foregroundStyle(.secondary)
                        Text(record.display)
                            .font(.title3.weight(.semibold))
                        Text("will be saved to history and your calendar will restart from today as the new 01.01.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("What happens when you reset")
                }

                Section {
                    Button(role: .destructive) {
                        resetCalendar()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset Calendar")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Reset \"\(calendar.title)\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func resetCalendar() {
        let ymd = calendar.elapsedYMD()
        let record = StreakRecord(
            years: ymd.years,
            months: ymd.months,
            days: ymd.days,
            savedDate: .now
        )
        calendar.streakHistory.append(record)
        calendar.startDate = Calendar.current.startOfDay(for: .now)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let calendar = GoalCalendar(
        title: "Work out",
        startDate: Calendar.current.date(byAdding: .day, value: -60, to: .now)!
    )
    ResetView(calendar: calendar)
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
}
