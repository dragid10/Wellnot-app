import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for flutter_local_notifications scheduled notifications on iOS.
    // Without this, zonedSchedule notifications won't fire.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Platform channel for OS-level queries and file operations.
    // Uses the plugin registrar's messenger so it works with both
    // window-based and scene-based app lifecycles.
    let registrar = self.registrar(forPlugin: "PlatformChannel")!
    let platformChannel = FlutterMethodChannel(
      name: "com.symptom_tracker_app/platform",
      binaryMessenger: registrar.messenger()
    )
    platformChannel.setMethodCallHandler { (call, result) in
      if call.method == "getFirstDayOfWeek" {
        // Calendar.current.firstWeekday respects the user's regional
        // preferences. Returns 1 = Sunday through 7 = Saturday.
        result(Calendar.current.firstWeekday)
      } else if call.method == "excludeFromBackup" {
        // Sets NSURLIsExcludedFromBackupKey on a file to prevent iCloud
        // backup. Used to keep the SQLite database off iCloud.
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing 'path' argument", details: nil))
          return
        }
        var url = URL(fileURLWithPath: path)
        do {
          var resourceValues = URLResourceValues()
          resourceValues.isExcludedFromBackup = true
          try url.setResourceValues(resourceValues)
          result(true)
        } catch {
          result(FlutterError(code: "BACKUP_EXCLUSION_FAILED",
                              message: error.localizedDescription, details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return launched
  }
}
