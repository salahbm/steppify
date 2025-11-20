import ActivityKit
import Foundation

struct StepActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var todaySteps: Int
        var sinceOpenSteps: Int
        var sinceBootSteps: Int
        var status: String
    }
}
