import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    static let PLATFORM_VIEW_TYPE_NAME = "platform_text_view"
    static let PLATFORM_VIEW_PLUGIN_NAME = "FLPlugin"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Platform View
        weak var registrar = self.registrar(forPlugin:AppDelegate.PLATFORM_VIEW_PLUGIN_NAME)
        let factory = FLNativeViewFactory(messenger: registrar!.messenger())
        
        registrar!.register(factory,withId: AppDelegate.PLATFORM_VIEW_TYPE_NAME)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
