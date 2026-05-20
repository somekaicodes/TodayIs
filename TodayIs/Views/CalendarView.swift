//
//  CalendarView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftData
import SwiftUI

struct CalendarView: View {
    let calendar: GoalCalendar

    @State private var viewingMonth: Int = 1
    @State private var showReset   = false
    @State private var showHistory = false

    private var todayAbsolute: Int {
        calendar.daysSinceStart()
    }
    private var todayMonth: Int {
        calendar.currentMonth()
    }
    private var todayYear: Int {
        calendar.currentYear()
    }
    private var totalMonths: Int {
        calendar.totalMonths()
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header: goal title + year ──
            VStack(spacing: 2) {
                Text(calendar.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Year \(String(format: "%02d", todayYear))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)

            // ── Month navigator ──
            HStack {
                Button {
                    if viewingMonth > 1 { viewingMonth -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .disabled(viewingMonth <= 1)

                Spacer()

                VStack(spacing: 2) {
                    Text("Month \(viewingMonth)")
                        .font(.title3.weight(.semibold))
                    // Show which year this month falls in
                    let monthYear = yearForDay(firstDayOfMonth(viewingMonth))
                    Text("Year \(String(format: "%02d", monthYear))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    if viewingMonth < totalMonths + 1 { viewingMonth += 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.top, 8)

            // ── Calendar grid (swipeable) ──
            TabView(selection: $viewingMonth) {
                ForEach(1...(max(totalMonths + 1, 2)), id: \.self) { month in
                    MonthGridView(
                        month:        month,
                        todayAbsolute: todayAbsolute
                    )
                    .tag(month)
                    .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: viewingMonth)

            Divider()

            // ── Bottom bar ──
            HStack(spacing: 16) {
                // Streak display
                let ymd = calendar.elapsedYMD()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(StreakRecord(years: ymd.years, months: ymd.months, days: ymd.days, savedDate: .now).display)
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                Button {
                    showHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                Button {
                    showReset = true
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .onAppear {
            viewingMonth = todayMonth
        }
        .sheet(isPresented: $showReset) {
            ResetView(calendar: calendar)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(calendar: calendar)
                .presentationDetents([.large])
        }
    }
}

// MARK: - Month grid

struct MonthGridView: View {
    let month:         Int
    let todayAbsolute: Int

    // 7 columns, 5 rows (30 days — last cell empty if needed)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let first   = firstDayOfMonth(month)
        let numDays = monthLengths[month - 1]
        
        // Offset: how many columns to indent the first day
        // based on total days elapsed before this month mod 7
        // so weeks flow continuously across months
        let offset  = first % 7

        VStack(spacing: 4) {
         
            // ── Fixed column headers: always 1-7 ──
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...7, id: \.self) { col in
                    Text("\(col)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
         
            // ── Day cells with leading offset ──
            LazyVGrid(columns: columns, spacing: 4) {
 
                // blank cells to push day 1 to correct column
                ForEach(0..<offset, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
 
                // actual day cells
                ForEach(0..<numDays, id: \.self) { i in
                    let absDay   = first + i
                    let dayNum   = i + 1
                    let isToday  = absDay == todayAbsolute
                    let isPast   = absDay < todayAbsolute
                    let isFuture = absDay > todayAbsolute
 
                    DayCellView(
                        number:   dayNum,
                        isToday:  isToday,
                        isPast:   isPast,
                        isFuture: isFuture
                    )
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Day cell

struct DayCellView: View {
    let number:   Int
    let isToday:  Bool
    let isPast:   Bool
    let isFuture: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(background)
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                }

            Text("\(number)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(foreground)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(isFuture ? 0.3 : 1)
    }

    private var background: Color {
        if isToday { return Color(.systemBackground) }
        if isPast  { return Color(.secondarySystemBackground) }
        return Color(.secondarySystemBackground)
    }

    private var foreground: Color {
        if isToday { return .accentColor }
        return .primary
    }
}

#Preview {
    let calendar = GoalCalendar(
        title: "Work out every day",
        startDate: Calendar.current.date(byAdding: .day, value: -45, to: .now)!
    )
    CalendarView(calendar: calendar)
        .modelContainer(for: [GoalCalendar.self, StreakRecord.self], inMemory: true)
}
