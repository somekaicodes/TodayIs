//
//  TodayIsWidgetLiveActivity.swift
//  TodayIsWidget
//
//  Created by Kai Kim on 2026-05-17.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TodayIsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TodayIsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodayIsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TodayIsWidgetAttributes {
    fileprivate static var preview: TodayIsWidgetAttributes {
        TodayIsWidgetAttributes(name: "World")
    }
}

extension TodayIsWidgetAttributes.ContentState {
    fileprivate static var smiley: TodayIsWidgetAttributes.ContentState {
        TodayIsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TodayIsWidgetAttributes.ContentState {
         TodayIsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TodayIsWidgetAttributes.preview) {
   TodayIsWidgetLiveActivity()
} contentStates: {
    TodayIsWidgetAttributes.ContentState.smiley
    TodayIsWidgetAttributes.ContentState.starEyes
}
