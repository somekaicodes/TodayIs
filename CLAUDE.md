# TodayIs — Project Context

**App name:** "Today is ..."
**Developer:** Kai Kim (somekaicodes)
**Platform:** iOS, SwiftUI + SwiftData
**App Group ID:** `group.com.kaikim.todayis`

---

## What the app does

"Today is..." is a personal habit/goal tracker built around a **custom calendar system**. Instead of tracking dates on the real-world calendar, each goal has its own independent year that starts on a user-defined date (day 0). The app shows you what "month" and "day" it is *within your personal goal year*, and tracks your streak — how long you've continuously kept the habit.

Users can have **multiple goal calendars** (e.g. "Morning runs", "No sugar"), each with its own start date and streak history.

---

## Custom calendar system (critical to understand)

This is not the Gregorian calendar. The app defines its own time units:

- **Year** = 365 days, zero-indexed (Year 00, Year 01, ...)
- **Months** use real calendar lengths: `[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]`
- **Day 0** = the `startDate` the user chose when creating the calendar
- All day math uses absolute day indices (days since startDate), then converts to (year, month, dayOfMonth)
- **Week alignment is continuous across months** — the offset for the first day of each month is `firstDayOfMonth(month) % 7`, so weeks don't reset at month boundaries

Helper functions in `Models.swift`:
- `firstDayOfMonth(_ month:)` — 0-based index of the first day of a month within a year
- `lastDayOfMonth(_ month:)` — 0-based index of the last day
- `monthForDay(_ day:)` — which month (1-based) an absolute day falls in
- `dayOfMonthForDay(_ day:)` — which day-of-month (1-based) an absolute day is
- `yearForDay(_ day:)` — which year (0-based) an absolute day falls in

The widget has its own simplified copy of these calculations (using 30-day months) because it can't import the app target.

---

## Data model

### `GoalCalendar` (SwiftData)
- `title: String` — user's goal name
- `startDate: Date` — the real-world date that maps to Day 0 of the calendar
- `streakHistory: [StreakRecord]` — past streaks saved on reset (cascade delete)
- Key methods: `daysSinceStart()`, `elapsedYMD()`, `currentMonth()`, `currentYear()`, `currentDayOfMonth()`

### `StreakRecord` (SwiftData)
- Stores a past streak as `(years, months, days, savedDate)`
- `display` — human-readable string, e.g. "1 year, 2 months, 5 days"
- `totalDays` — used for sorting/editing in HistoryView

### Persistence
- SwiftData container stored in the **App Group** so both the app and widget can access it
- `makeTodayIsModelContainer()` in `Models.swift` sets this up
- Widget **cannot** use SwiftData directly (different target) — instead the app writes a JSON snapshot to shared `UserDefaults` via `syncWidgetData(calendars:)`, keyed as `"goal_calendars"`
- Widget data sync is triggered from `RootView` via `.task(id: widgetSyncKey)` whenever any calendar changes

---

## File structure

| File | Purpose |
|------|---------|
| `TodayIs/Models/Models.swift` | SwiftData models, all day/month/year math helpers, widget sync |
| `TodayIs/TodayIsApp.swift` | App entry point, Firebase setup, SwiftData container |
| `TodayIs/Services/AuthService.swift` | Firebase Auth — Google Sign-In + Sign in with Apple |
| `TodayIs/Services/FirestoreService.swift` | Firestore CRUD — upload/download GoalCalendar + StreakRecord |
| `TodayIs/Views/RootView.swift` | Nav shell, toolbar with account button, Firestore sync on sign-in |
| `TodayIs/Views/AccountView.swift` | Profile sheet — shows sign-in options or signed-in profile + sign-out |
| `TodayIs/Views/SignInView.swift` | Google + Apple sign-in buttons |
| `TodayIs/Views/SidebarView.swift` | List of goal calendars to switch between |
| `TodayIs/Views/NewCalendarView.swift` | Sheet for creating a new calendar |
| `TodayIs/Views/CalendarView.swift` | Month grid view with swipeable months, streak display, reset/history buttons |
| `TodayIs/Views/ResetView.swift` | Reset streak (saves current streak to history first) |
| `TodayIs/Views/HistoryView.swift` | Editable list of past streaks |
| `TodayIs/Views/SplashView.swift` | Launch screen |
| `TodayIsWidget/TodayIsWidget.swift` | WidgetKit extension — small widget showing current month/day/year |

---

## Firebase architecture

### Auth
- `AuthService` is `@Observable @MainActor` — injected via `.environment(authService)` from `TodayIsApp`
- Supports **Google Sign-In** and **Sign in with Apple**
- Auth state is mirrored into `AuthService.user` via `Auth.auth().addStateDidChangeListener`
- Sign-in is **opt-in** — the app works fully offline without an account

### Firestore data structure
```
users/{userID}/
  calendars/{calendarID}    { id, title, startDate }
    streaks/{recordID}      { id, years, months, days, savedDate }
```

### Sync strategy
- **SwiftData is the local source of truth** — the app always works offline
- On **fresh sign-in**: if the user has cloud data → download into SwiftData (cloud wins); else → upload local data to Firestore
- On **any calendar change**: `RootView.widgetSyncKey` fires `.task` which uploads to Firestore (if signed in) and refreshes the widget
- On **sign-out**: local SwiftData is left untouched

### Required Swift packages (add via Xcode → File → Add Package Dependencies)
- `https://github.com/firebase/firebase-ios-sdk` — add: FirebaseAuth, FirebaseFirestore, FirebaseCore
- `https://github.com/google/GoogleSignIn-iOS` — add: GoogleSignIn, GoogleSignInSwift

---

## Widget

- **Size:** systemSmall only
- **Configuration:** user picks which goal calendar to display via `SelectCalendarIntent` (AppIntents)
- **Data flow:** app writes JSON snapshot to shared UserDefaults (`goal_calendars` key) → widget reads on timeline refresh
- **Deep-link:** `RootView.handleDeepLink` handles `todayis://goal/<uuid>` URLs from the widget
- Widget refreshes daily at midnight

---

## Known bugs / things that have caused issues

- **Month offset bug history:** The calendar grid needs `firstDayOfMonth(month) % 7` for the column offset — earlier versions used wrong offsets causing months to start on wrong columns or show a greyed-out first row
- **Current month on open:** CalendarView initializes `viewingIndex = todayIndex` in `.onAppear` — without this it defaulted to month 1 every time
- **Widget can't use SwiftData:** The widget target can't include the app's SwiftData models, so `GoalCalendarInfo` is a self-contained struct in the widget file that duplicates the date math
- **Widget uses 30-day months** in its `currentMonth()`/`currentDay()` calculations (simplified), while the main app uses real month lengths — these will drift apart over long streaks
- **Apple Sign-In requires a capability:** the Xcode target needs "Sign in with Apple" enabled under Signing & Capabilities, otherwise the auth flow crashes silently
