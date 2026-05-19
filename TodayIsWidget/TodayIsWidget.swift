//
//  TodayIsWidget.swift
//  TodayIsWidget
//
//  Created by Kai Kim on 2026-05-17.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared types (self contained for widget target)

struct GoalCalendarInfo: Codable, Identifiable {
    var id:         UUID
    var title:      String
    var startDate:  Date

    func currentMonth() -> Int { daysSinceStart() / 30 + 1 }
    func currentDay()   -> Int { daysSinceStart() % 30 + 1 }
    func currentYear()  -> Int { daysSinceStart() / 365 }

    private func daysSinceStart() -> Int {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let now   = cal.startOfDay(for: .now)
        return max(0, cal.dateComponents([.day], from: start, to: now).day ?? 0)
    }
}

func loadCalendars() -> [GoalCalendarInfo] {
    let defaults = UserDefaults(suiteName: "group.com.yourname.todayis") ?? .standard
    guard let data = defaults.data(forKey: "goal_calendars"),
          let decoded = try? JSONDecoder().decode([GoalCalendarInfo].self, from: data)
    else { return [] }
    return decoded
}

// MARK: - App Intent for calendar selection

struct CalendarAppEntity: AppEntity {
    var id:    UUID
    var title: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal Calendar")
    static var defaultQuery = CalendarQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct CalendarQuery: EntityQuery {
    func entities(for ids: [UUID]) async throws -> [CalendarAppEntity] {
        loadCalendars().filter { ids.contains($0.id) }.map {
            CalendarAppEntity(id: $0.id, title: $0.title)
        }
    }

    func suggestedEntities() async throws -> [CalendarAppEntity] {
        loadCalendars().map { CalendarAppEntity(id: $0.id, title: $0.title) }
    }

    func defaultResult() async -> CalendarAppEntity? {
        loadCalendars().first.map { CalendarAppEntity(id: $0.id, title: $0.title) }
    }
}

// MARK: - Widget configuration intent

struct SelectCalendarIntent: WidgetConfigurationIntent {
    static var title:       LocalizedStringResource = "Select Goal"
    static var description  = IntentDescription("Choose which goal calendar to display.")

    @Parameter(title: "Goal Calendar")
    var calendar: CalendarAppEntity?
}

// MARK: - Timeline entry

struct CalendarEntry: TimelineEntry {
    let date:        Date
    let title:       String
    let month:       Int
    let day:         Int
    let year:        Int
}

// MARK: - Provider

struct CalendarProvider: AppIntentTimelineProvider {
    typealias Entry  = CalendarEntry
    typealias Intent = SelectCalendarIntent

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: .now, title: "Morning Runs 🏃", month: 1, day: 1, year: 0)
    }

    func snapshot(for intent: SelectCalendarIntent, in context: Context) async -> CalendarEntry {
        makeEntry(for: intent)
    }

    func timeline(for intent: SelectCalendarIntent, in context: Context) async -> Timeline<CalendarEntry> {
        let entry    = makeEntry(for: intent)
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(86400)
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func makeEntry(for intent: SelectCalendarIntent) -> CalendarEntry {
        let calendars = loadCalendars()
        let cal: GoalCalendarInfo

        if let selectedID = intent.calendar?.id,
           let match = calendars.first(where: { $0.id == selectedID }) {
            cal = match
        } else if let first = calendars.first {
            cal = first
        } else {
            return CalendarEntry(date: .now, title: "No goal yet", month: 1, day: 1, year: 0)
        }

        return CalendarEntry(
            date:  .now,
            title: cal.title,
            month: cal.currentMonth(),
            day:   cal.currentDay(),
            year:  cal.currentYear()
        )
    }
}

// MARK: - Widget view

struct TodayIsWidgetView: View {
    let entry: CalendarEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(.systemBackground)

            VStack(alignment: .leading, spacing: 6) {
                // Goal name
                Text(entry.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                // Month large
                VStack(alignment: .leading, spacing: 0) {
                    Text("Month")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.tertiary)
                    Text("\(entry.month)")
                        .font(.system(size: family == .systemSmall ? 48 : 56, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // Day smaller but still prominent
                VStack(alignment: .leading, spacing: 0) {
                    Text("Day")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.tertiary)
                    Text("\(entry.day)")
                        .font(.system(size: family == .systemSmall ? 32 : 40, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Year small at bottom
                Text("Year \(String(format: "%02d", entry.year))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Widget definition

struct TodayIsWidget: Widget {
    let kind = "TodayIsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind:     kind,
            intent:   SelectCalendarIntent.self,
            provider: CalendarProvider()
        ) { entry in
            TodayIsWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Today is ...")
        .description("See what day it is in your personal goal calendar.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodayIsWidget()
} timeline: {
    CalendarEntry(date: .now, title: "Morning Runs 🏃", month: 2, day: 11, year: 0)
}
