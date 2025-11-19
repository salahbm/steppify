import Foundation
import ActivityKit

@objc class ActivityController: NSObject {

    @available(iOS 16.1, *)
    static var activity: Activity<StepActivityAttributes>?

    @objc static func startActivity(data: [String: Any]? = nil) {
        guard #available(iOS 16.2, *) else { return }

        let attributes = StepActivityAttributes()

        let state = StepActivityAttributes.ContentState(
            todaySteps: (data?["today"] as? Int) ?? 0,
            sinceOpenSteps: (data?["open"] as? Int) ?? 0,
            sinceBootSteps: (data?["boot"] as? Int) ?? 0,
            status: (data?["status"] as? String) ?? "unknown"
        )

        Task {
            activity = try? Activity<StepActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        }
    }

    @objc static func updateActivity(
        today: Int,
        open: Int,
        boot: Int,
        status: String
    ) {
        guard #available(iOS 16.1, *) else { return }

        let updated = StepActivityAttributes.ContentState(
            todaySteps: today,
            sinceOpenSteps: open,
            sinceBootSteps: boot,
            status: status
        )

        Task {
            await activity?.update(using: updated)
        }
    }

    @objc static func endActivity() {
        if #available(iOS 16.2, *) {
            Task {
                await activity?.end(dismissalPolicy: .immediate)
            }
        } else if #available(iOS 16.1, *) {
            Task {
                await activity?.end()
            }
        }
    }
}
