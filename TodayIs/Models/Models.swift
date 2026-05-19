//
//  Models.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import Foundation

// MARK: - Month lengths (real calendar, 365 days total)
 
let monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
 
/// First day index (0-based) of a given month (1-based month number)
func firstDayOfMonth(_ month: Int) -> Int {
    monthLengths.prefix(month - 1).reduce(0, +)
}
 
/// Last day index (0-based) of a given month
func lastDayOfMonth(_ month: Int) -> Int {
    firstDayOfMonth(month) + monthLengths[month - 1] - 1
}
 
/// Which month (1-based) does an absolute day fall in?
func monthForDay(_ day: Int) -> Int {
    let dayInYear = day % 365
    var total = 0
    for (i, len) in monthLengths.enumerated() {
        total += len
        if dayInYear < total { return i + 1 }
    }
    return 12
}
 
/// Which day of the month (1-based) is an absolute day?
func dayOfMonthForDay(_ day: Int) -> Int {
    let dayInYear = day % 365
    let mo = monthForDay(day)
    return dayInYear - firstDayOfMonth(mo) + 1
}
 
/// Which year (0-based) does an absolute day fall in?
func yearForDay(_ day: Int) -> Int { day / 365 }

// MARK: - Streak history entry

struct StreakRecord: Identifiable, Codable {
    var id         = UUID()
    var years:     Int
    var months:    Int
    var days:      Int
    var savedDate: Date

    /// Human-readable e.g. "1 year, 2 months, 5 days"
    var display: String {
        var parts: [String] = []
        if years  > 0 { parts.append("\(years) \(years  == 1 ? "year"  : "years")") }
        if months > 0 { parts.append("\(months) \(months == 1 ? "month" : "months")") }
        if days   > 0 { parts.append("\(days) \(days    == 1 ? "day"   : "days")") }
        return parts.isEmpty ? "0 days" : parts.joined(separator: ", ")
    }

    /// Total days for comparison when editing
    var totalDays: Int { years * 365 + months * 30 + days }
}

// MARK: - A single goal calendar

struct GoalCalendar: Identifiable, Codable {
    var id        = UUID()
    var title:    String          // user's goal name
    var startDate: Date           // the real-world date that = 01.01 (month 1, day 1)
    var streakHistory: [StreakRecord] = []

    // MARK: Derived

    /// Days elapsed since startDate (0 = day one)
    func daysSinceStart(today: Date = .now) -> Int {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let now   = cal.startOfDay(for: today)
        return max(0, cal.dateComponents([.day], from: start, to: now).day ?? 0)
    }

    /// Decompose total elapsed days into years / months / days
    /// using fixed 12-month year, 30-day month
    func elapsedYMD(today: Date = .now) -> (years: Int, months: Int, days: Int) {
        var remaining = daysSinceStart(today: today)
        let years     = remaining / 365; remaining -= years * 365
        var months = 0
        for len in monthLengths {
            if remaining >= len { remaining -= len; months += 1 }
            else { break }
        }
        return (years, months, remaining)
    }

    /// Which custom month number is "today" in?
    /// Month 1 = days 0–29, Month 2 = days 30–59, etc. (30-day months)
    func currentMonth(today: Date = .now) -> Int {
        monthForDay(daysSinceStart(today: today))
    }

    /// Which custom year number is "today" in? (year 00 = first year)
    func currentYear(today: Date = .now) -> Int {
        yearForDay(daysSinceStart(today: today))
    }

    func currentDayOfMonth(today: Date = .now) -> Int {
        dayOfMonthForDay(daysSinceStart(today: today))
    }

    /// Total months elapsed from start (1-based)
    func totalMonths(today: Date = .now) -> Int {
        daysSinceStart(today: today) / 30 + 1
    }
}

// MARK: - Shared storage key (App Groups)
// Replace "yourname" with your actual name e.g. "group.com.kai.todayis"
let appGroupID = "group.com.kaikim.todayis"
 
func sharedDefaults() -> UserDefaults {
    UserDefaults(suiteName: appGroupID) ?? .standard
}
 

// MARK: - Store (persists array of GoalCalendars)

@Observable
final class GoalStore {
    var calendars: [GoalCalendar] = []
    var selectedID: UUID?

    var selected: GoalCalendar? {
        calendars.first { $0.id == selectedID }
    }

    init() { load() }

    func add(title: String, startDate: Date) {
        let cal = GoalCalendar(title: title, startDate: startDate)
        calendars.append(cal)
        selectedID = cal.id
        save()
    }

    func update(_ calendar: GoalCalendar) {
        if let i = calendars.firstIndex(where: { $0.id == calendar.id }) {
            calendars[i] = calendar
            save()
        }
    }

    func delete(id: UUID) {
        calendars.removeAll { $0.id == id }
        if selectedID == id { selectedID = calendars.first?.id }
        save()
    }

    /// Reset a calendar: save streak to history, set startDate to today
    func reset(id: UUID) {
        guard let i = calendars.firstIndex(where: { $0.id == id }) else { return }
        let cal = calendars[i]
        let ymd = cal.elapsedYMD()
        let record = StreakRecord(
            years:     ymd.years,
            months:    ymd.months,
            days:      ymd.days,
            savedDate: .now
        )
        calendars[i].streakHistory.append(record)
        calendars[i].startDate = Calendar.current.startOfDay(for: .now)
        save()
    }

    // MARK: Persistence
    private let defaults = sharedDefaults()
    private let key = "goal_calendars"
    private let selKey = "selected_id"

    private func save() {
        if let data = try? JSONEncoder().encode(calendars) {
            defaults.set(data, forKey: key)
        }
        defaults.set(selectedID?.uuidString, forKey: selKey)
    }

    private func load() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([GoalCalendar].self, from: data) {
            calendars = decoded
        }
        if let str = defaults.string(forKey: selKey),
           let uid = UUID(uuidString: str) {
            selectedID = uid
        } else {
            selectedID = calendars.first?.id
        }
    }
}
