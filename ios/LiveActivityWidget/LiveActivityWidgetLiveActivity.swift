import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            HStack(spacing: 16) {
                // Left side - Main step count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(context.state.todaySteps)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Right side - Additional info
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Image(systemName: context.state.status == "walking" ? "figure.walk" : "figure.stand")
                            .foregroundColor(context.state.status == "walking" ? .green : .orange)
                        Text(context.state.status.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Since Open: \(context.state.sinceOpenSteps)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Since Boot: \(context.state.sinceBootSteps)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Steps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.todaySteps)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Image(systemName: context.state.status == "walking" ? "figure.walk" : "figure.stand")
                            .foregroundColor(context.state.status == "walking" ? .green : .orange)
                        Text(context.state.status.capitalized)
                            .font(.caption2)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Open: \(context.state.sinceOpenSteps)")
                        Spacer()
                        Text("Boot: \(context.state.sinceBootSteps)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

            } compactLeading: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)

            } compactTrailing: {
                Text("\(context.state.todaySteps)")
                    .font(.caption)
                    .fontWeight(.semibold)

            } minimal: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
            }
        }
    }
}
