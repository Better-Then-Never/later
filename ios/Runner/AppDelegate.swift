import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyBM1CQjaf4j2cucP8ST5Lsx1dbP-4d2Pww");
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}