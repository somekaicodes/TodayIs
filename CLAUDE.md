{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 TodayIs \'97 Project Context for Claude Code\
\
App name: "Today is ..."\
Project name: TodayIs\
Developer: Kai Kim (somekaicodes)\
App Group ID: group.com.kaikim.todayis\
\
File structure:\
- TodayIs/Models/Models.swift \'97 SwiftData models, month math helpers\
- TodayIs/Views/RootView.swift \'97 nav shell, empty state\
- TodayIs/Views/SidebarView.swift \'97 goal calendar list\
- TodayIs/Views/NewCalendarView.swift \'97 create calendar sheet\
- TodayIs/Views/CalendarView.swift \'97 month grid, continuous week alignment\
- TodayIs/Views/ResetView.swift \'97 reset with streak saving\
- TodayIs/Views/HistoryView.swift \'97 editable streak history\
- TodayIs/Views/SplashView.swift \'97 launch screen\
- TodayIs/TodayIsApp.swift \'97 app entry, SwiftData container\
- TodayIsWidget/ \'97 WidgetKit extension (in progress)\
\
Key decisions:\
- SwiftData for persistence (migrated from UserDefaults)\
- Real calendar month lengths [31,28,31,30,31,30,31,31,30,31,30,31]\
- Continuous week alignment across months (offset = firstDayOfMonth % 7)\
- 365 days = 1 year, months follow real calendar lengths\
- Year starts at 00\
- App Groups for widget data sharing}