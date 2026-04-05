import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var mapKey = ""
    if let envPath = Bundle.main.path(forResource: ".env", ofType: nil, inDirectory: "flutter_assets") {
        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = envContent.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 && parts[0] == "GOOGLE_MAPS_API_KEY" {
                    mapKey = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            print("Error reading .env file")
        }
    }
    
    if !mapKey.isEmpty {
        GMSServices.provideAPIKey(mapKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
