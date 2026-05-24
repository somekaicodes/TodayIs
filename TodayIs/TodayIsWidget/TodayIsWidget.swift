//
//  TodayIsWidget.swift
//  TodayIsWidget
//
//  Created by Kai Kim on 2026-05-17.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared constants

private let widgetAppGroupID    = "group.com.kaikim.todayis"
private let widgetCalendarsKey  = "goal_calendars"
private let pendingCalendarKey  = "pending_calendar_id"

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
    let defaults = UserDefaults(suiteName: widgetAppGroupID) ?? .standard
    guard let data = defaults.data(forKey: widgetCalendarsKey),
          let decoded = try? JSONDecoder().decode([GoalCalendarInfo].self, from: data)
    else { return [] }
    return decoded
}

// MARK: - App Intent for calendar selection

struct CalendarAppEntity: AppEntity {
    var id:        UUID
    var title:     String
    var startDate: Date

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal Calendar")
    static var defaultQuery = CalendarQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct CalendarQuery: EntityQuery {
    func entities(for ids: [UUID]) async throws -> [CalendarAppEntity] {
        loadCalendars()
            .filter { ids.contains($0.id) }
            .map { CalendarAppEntity(id: $0.id, title: $0.title, startDate: $0.startDate) }
    }

    func suggestedEntities() async throws -> [CalendarAppEntity] {
        loadCalendars()
            .map { CalendarAppEntity(id: $0.id, title: $0.title, startDate: $0.startDate) }
    }

    // Returning nil so iOS prompts the user to pick a goal rather than
    // silently defaulting to the first calendar.
    func defaultResult() async -> CalendarAppEntity? {
        nil
    }
}

// MARK: - Widget configuration intent

struct SelectCalendarIntent: WidgetConfigurationIntent {
    static var title:       LocalizedStringResource = "Select Goal"
    static var description  = IntentDescription("Choose which goal calendar to display.")

    @Parameter(title: "Goal Calendar")
    var calendar: CalendarAppEntity?
}

// MARK: - Open goal intent (tap → opens app on that goal)

struct OpenGoalIntent: AppIntent {
    static var title:           LocalizedStringResource = "Open Goal"
    static var openAppWhenRun:  Bool = true

    @Parameter(title: "Calendar ID")
    var calendarID: String

    init() {}

    init(calendarID: String) {
        self.calendarID = calendarID
    }

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: widgetAppGroupID)?
            .set(calendarID, forKey: pendingCalendarKey)
        return .result()
    }
}

// MARK: - Timeline entry

struct CalendarEntry: TimelineEntry {
    let date:    Date
    let id:      UUID?      // nil when in a placeholder state
    let title:   String
    let month:   Int
    let day:     Int
    let year:    Int
}

// MARK: - Provider

struct CalendarProvider: AppIntentTimelineProvider {
    typealias Entry  = CalendarEntry
    typealias Intent = SelectCalendarIntent

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: .now, id: nil, title: "Morning Runs 🏃", month: 1, day: 1, year: 0)
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
        // Render directly from the entity stored on the intent. No second
        // lookup against the snapshot — the entity is self contained, so
        // this is robust to UserDefaults timing.
        guard let entity = intent.calendar else {
            // No selection yet — tell the user how to configure.
            return CalendarEntry(
                date:  .now,
                id:    nil,
                title: loadCalendars().isEmpty ? "No goal yet" : "Tap & hold to pick a goal",
                month: 0, day: 0, year: 0
            )
        }

        let info = GoalCalendarInfo(id: entity.id, title: entity.title, startDate: entity.startDate)
        return CalendarEntry(
            date:  .now,
            id:    entity.id,
            title: entity.title,
            month: info.currentMonth(),
            day:   info.currentDay(),
            year:  info.currentYear()
        )
    }
}

// MARK: - Widget view

struct TodayIsWidgetView: View {
    let entry: CalendarEntry

    private var isPlaceholder: Bool { entry.month == 0 || entry.id == nil }

    var body: some View {
        Group {
            if isPlaceholder {
                placeholderBody
            } else if let id = entry.id {
                Button(intent: OpenGoalIntent(calendarID: id.uuidString)) {
                    contentBody
                }
                .buttonStyle(.plain)
            } else {
                contentBody
            }
        }
    }

    private var placeholderBody: some View {
        Text(entry.title)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Goal name — pushed down slightly
            Text(entry.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.top, 8)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                Text("Month")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
                Text("\(entry.month)")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Day")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
                Text("\(entry.day)")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Year — lifted up slightly
            Text("Year \(String(format: "%02d", entry.year))")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodayIsWidget()
} timeline: {
    CalendarEntry(date: .now, id: UUID(), title: "Morning Runs 🏃", month: 2, day: 11, year: 0)
}
