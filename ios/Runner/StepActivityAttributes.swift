import ActivityKit
import Foundation

struct StepActivityAttributes: ActivityAttributes {

    // REQUIRED ROOT-LEVEL PROPERTY
    var id: String = UUID().uuidString

    struct ContentState: Codable, Hashable {
        var todaySteps: Int
        var sinceOpenSteps: Int
        var sinceBootSteps: Int
        var status: String
    }
}
