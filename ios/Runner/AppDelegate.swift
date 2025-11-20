import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController

    let channel = FlutterMethodChannel(
      name: "step_activity_channel",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {

      case "requestForNotificationPermission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          print("SWIFT: notification permission granted = \(granted)")
          result(granted)
        }

      case "registerDevice":
        // This is for API testing - just acknowledge the call
        print("SWIFT: registerDevice called")
        result(nil)

      case "startActivity":
        if #available(iOS 16.2, *) {
          ActivityController.startActivity(
            data: call.arguments as? [String: Any]
          ) { success, error in
            if success {
              result(nil)
            } else {
              result(FlutterError(
                code: "LIVE_ACTIVITY_ERROR",
                message: error ?? "Failed to start Live Activity",
                details: nil
              ))
            }
          }
        } else {
          result(FlutterError(
            code: "VERSION_ERROR",
            message: "iOS 16.2+ required for Live Activities",
            details: nil
          ))
        }

      case "updateActivity":
        if #available(iOS 16.2, *) {
          guard let args = call.arguments as? [String: Any] else {
            result(nil); return
          }
          ActivityController.updateActivity(
            today: args["today"] as? Int ?? 0,
            open: args["open"] as? Int ?? 0,
            boot: args["boot"] as? Int ?? 0,
            status: args["status"] as? String ?? "unknown"
          )
        }
        result(nil)

      case "endActivity":
        if #available(iOS 16.2, *) {
          ActivityController.endActivity()
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
