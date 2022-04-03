//
//  FLNativeView.swift
//  Runner
//
//  Created by yomi on 2022/4/2.
//

import Foundation
import Flutter

class FLNativeView:NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _dict: Dictionary<String, Any>
    
    init(frame: CGRect,viewIdentifier viewId: Int64,arguments args: Dictionary<String, Any>, binaryMessenger messenger: FlutterBinaryMessenger?) {
        // iOS views can be created here
        self._view = UIView()
        self._dict = args
        
        super.init()
        self.initNativeView()
    }
    
    func view() -> UIView {
        return self._view
    }
    
    func initNativeView() {
        _view.backgroundColor = UIColor.blue
        
        let nativeLabel = UILabel()
        nativeLabel.text = self._dict["content"] as? String ?? "N/A"
        nativeLabel.textColor = UIColor.white
        nativeLabel.textAlignment = .center
        nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
        _view.addSubview(nativeLabel)
    }
    
}
