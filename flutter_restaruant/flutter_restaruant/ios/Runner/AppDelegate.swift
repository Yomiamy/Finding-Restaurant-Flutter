import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
      
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    
  @available(iOS 10.0, *)
  func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void)
  {
      //Handle the notification
      completionHandler([.alert, .sound, .badge])
  }
}
