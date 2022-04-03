package com.yomi.flutter_restaruant

import com.yomi.flutter_restaruant.view.NativeViewFactory
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {

    companion object {
        const val PLATFORM_VIEW_TYPE = "platform_text_view"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "").setMethodCallHandler { call, result ->  }
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(PLATFORM_VIEW_TYPE, NativeViewFactory())
    }
}
