package com.yomi.flutter_restaruant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "").setMethodCallHandler { call, result ->  }
//    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
