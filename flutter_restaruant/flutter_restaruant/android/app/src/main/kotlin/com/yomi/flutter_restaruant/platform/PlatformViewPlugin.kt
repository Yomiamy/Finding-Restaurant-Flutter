package com.yomi.flutter_restaruant.platform
import com.yomi.flutter_restaruant.view.NativeViewFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class PlatformViewPlugin : FlutterPlugin {
    companion object {
        const val PLATFORM_VIEW_TYPE = "platform_text_view"
    }

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        binding
            .platformViewRegistry
            .registerViewFactory(PLATFORM_VIEW_TYPE, NativeViewFactory())
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}
}