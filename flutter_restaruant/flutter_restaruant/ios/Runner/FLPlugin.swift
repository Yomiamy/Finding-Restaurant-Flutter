import Flutter
import UIKit

class FLPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = FLNativeViewFactory(messenger: registrar.messenger())
        
        registrar.register(factory, withId: AppDelegate.PLATFORM_VIEW_TYPE_NAME)
    }
}
