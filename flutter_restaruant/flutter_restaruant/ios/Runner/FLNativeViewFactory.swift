//  NativeViewFactory.swift
//  Runner
//
//  Created by yomi on 2022/4/2.
//

import Foundation
import Flutter

public class FLNativeViewFactory:NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect,viewIdentifier viewId: Int64,arguments args: Any?) -> FlutterPlatformView {
        let args = args as? Dictionary<String, Any> ?? [:]
        return FLNativeView(frame: frame,
                              viewIdentifier: viewId,
                              arguments: args,
                              binaryMessenger: messenger)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
       return FlutterStandardMessageCodec.sharedInstance()
     }
}
