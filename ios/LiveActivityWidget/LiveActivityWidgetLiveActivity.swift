import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepActivityAttributes.self) { context in

            VStack {
                Text("Today: \(context.state.todaySteps)")
                Text("Since open: \(context.state.sinceOpenSteps)")
                Text("Since boot: \(context.state.sinceBootSteps)")
                Text("Status: \(context.state.status)")
            }
            .padding()

        } dynamicIsland: { context in

            DynamicIsland {

                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.todaySteps)")
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                }

            } compactLeading: {
                Text("\(context.state.todaySteps)")

            } compactTrailing: {
                Text("S")

            } minimal: {
                Text("\(context.state.todaySteps)")
            }
        }
    }
}
