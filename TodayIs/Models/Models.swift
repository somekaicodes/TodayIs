//
//  Models.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import Foundation

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
        let months    = remaining / 30;  remaining -= months * 30
        return (years, months, remaining)
    }

    /// Which custom month number is "today" in?
    /// Month 1 = days 0–29, Month 2 = days 30–59, etc. (30-day months)
    func currentMonth(today: Date = .now) -> Int {
        daysSinceStart(today: today) / 30 + 1
    }

    /// Which custom year number is "today" in? (year 00 = first year)
    func currentYear(today: Date = .now) -> Int {
        daysSinceStart(today: today) / 365
    }

    /// Day-of-month (1-based) for a given absolute day index
    static func dayOfMonth(absoluteDay: Int) -> Int {
        absoluteDay % 30 + 1
    }

    /// Month number (1-based) for a given absolute day index
    static func month(absoluteDay: Int) -> Int {
        absoluteDay / 30 + 1
    }

    /// Year number (0-based) for a given absolute day index
    static func year(absoluteDay: Int) -> Int {
        absoluteDay / 365
    }

    /// First absolute day index of a given month (1-based month)
    static func firstDay(ofMonth month: Int) -> Int {
        (month - 1) * 30
    }

    /// Last absolute day index of a given month (1-based month)
    static func lastDay(ofMonth month: Int) -> Int {
        month * 30 - 1
    }

    /// Total months elapsed from start (1-based)
    func totalMonths(today: Date = .now) -> Int {
        daysSinceStart(today: today) / 30 + 1
    }
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
    private let key = "goal_calendars"
    private let selKey = "selected_id"

    private func save() {
        if let data = try? JSONEncoder().encode(calendars) {
            UserDefaults.standard.set(data, forKey: key)
        }
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([GoalCalendar].self, from: data) {
            calendars = decoded
        }
        if let str = UserDefaults.standard.string(forKey: selKey),
           let uid = UUID(uuidString: str) {
            selectedID = uid
        } else {
            selectedID = calendars.first?.id
        }
    }
}
