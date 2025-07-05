import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  GeneratedPluginRegistrant.register(with: self):
  GMSServices.provideAPIKey("AIzaSyBb1yFNPOtimCNuJ4S1nYdXZBBNVCJVQZU")
}
