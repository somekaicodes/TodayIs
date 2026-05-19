//
//  HistoryView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let calendar: GoalCalendar

    @State private var editingRecord: StreakRecord?

    var body: some View {
        NavigationStack {
            Group {
                if !calendar.streakHistory.isEmpty {
                    List {
                        ForEach(calendar.streakHistory.reversed()) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.display)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Saved \(record.savedDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    editingRecord = record
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No history yet")
                            .font(.headline)
                        Text("When you reset this calendar, your streak will be saved here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("History - \(calendar.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            EditStreakView(record: record)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Edit streak (can only reduce)

struct EditStreakView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: StreakRecord

    @State private var years: Int = 0
    @State private var months: Int = 0
    @State private var days: Int = 0
    @State private var showError = false

    private var editedTotal: Int { years * 365 + months * 30 + days }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Years: \(years)", value: $years, in: 0...record.years)
                    Stepper("Months: \(months)", value: $months, in: 0...11)
                    Stepper("Days: \(days)", value: $days, in: 0...29)
                } header: {
                    Text("Edit streak (can only reduce)")
                } footer: {
                    Text("Original: \(record.display)")
                }

                if showError {
                    Section {
                        Text("Edited value must be less than or equal to the original streak.")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard editedTotal <= record.totalDays else {
                            showError = true
                            return
                        }
                        saveEdit()
                    }
                }
            }
            .onAppear {
                years = record.years
                months = record.months
                days = record.days
            }
        }
    }

    private func saveEdit() {
        record.years = years
        record.months = months
        record.days = days
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let calendar = GoalCalendar(
        title: "Work out",
        startDate: Calendar.current.date(byAdding: .day, value: -400, to: .now)!,
        streakHistory: [StreakRecord(years: 1, months: 1, days: 5, savedDate: .now)]
    )
    HistoryView(calendar: calendar)
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
}
