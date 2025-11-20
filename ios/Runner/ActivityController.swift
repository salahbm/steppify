import Foundation
import ActivityKit

@objc class ActivityController: NSObject {

    @available(iOS 16.2, *)
    static var activity: Activity<StepActivityAttributes>?

    @objc static func startActivity(
        data: [String: Any]? = nil,
        completion: ((Bool, String?) -> Void)? = nil
    ) {
        print("🔵 startActivity called with data: \(String(describing: data))")

        guard #available(iOS 16.2, *) else {
            print("❌ iOS version not supported")
            completion?(false, "iOS 16.2+ required")
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities are not enabled in Settings")
            completion?(false, "Live Activities are disabled. Please enable them in Settings.")
            return
        }

        let attributes = StepActivityAttributes()

        let todaySteps = (data?["today"] as? Int) ?? 0
        let sinceOpenSteps = (data?["open"] as? Int) ?? 0
        let sinceBootSteps = (data?["boot"] as? Int) ?? 0
        let status = (data?["status"] as? String) ?? "unknown"

        print("📊 Creating state: today=\(todaySteps), open=\(sinceOpenSteps), boot=\(sinceBootSteps), status=\(status)")

        let state = StepActivityAttributes.ContentState(
            todaySteps: todaySteps,
            sinceOpenSteps: sinceOpenSteps,
            sinceBootSteps: sinceBootSteps,
            status: status
        )

        Task {
            do {
                print("🚀 Requesting Live Activity...")
                activity = try Activity<StepActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
                print("✅ Live Activity started with ID: \(activity?.id ?? "unknown")")
                DispatchQueue.main.async { completion?(true, nil) }
            } catch {
                print("❌ Failed to start Live Activity: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(false, error.localizedDescription) }
            }
        }
    }

    @objc static func updateActivity(
        today: Int,
        open: Int,
        boot: Int,
        status: String
    ) {
        guard #available(iOS 16.2, *) else {
            print("❌ iOS version not supported for update")
            return
        }

        guard let currentActivity = activity else {
            print("⚠️ No active Live Activity to update")
            return
        }

        print("🔄 Updating Live Activity ID: \(currentActivity.id)")

        let updated = StepActivityAttributes.ContentState(
            todaySteps: today,
            sinceOpenSteps: open,
            sinceBootSteps: boot,
            status: status
        )

        Task {
            do {
                await currentActivity.update(using: updated)
                print("✅ Live Activity updated: today=\(today), open=\(open), boot=\(boot), status=\(status)")
            } catch {
                print("❌ Failed to update Live Activity: \(error.localizedDescription)")
            }
        }
    }

    @objc static func endActivity() {
        print("🛑 endActivity called")

        guard #available(iOS 16.2, *) else {
            print("❌ iOS version not supported for end")
            return
        }

        guard let currentActivity = activity else {
            print("⚠️ No active Live Activity to end")
            return
        }

        Task {
            await currentActivity.end(dismissalPolicy: .immediate)
            print("✅ Live Activity ended successfully")
            activity = nil
        }
    }
}
