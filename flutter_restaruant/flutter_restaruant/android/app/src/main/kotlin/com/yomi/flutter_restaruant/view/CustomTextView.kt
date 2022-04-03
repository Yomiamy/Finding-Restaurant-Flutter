package com.yomi.flutter_restaruant.view

import android.content.Context
import android.graphics.Typeface
import android.view.View
import android.widget.TextView
import androidx.core.content.ContextCompat
import io.flutter.plugin.platform.PlatformView

class CustomTextView constructor(context: Context?, id:Int, params:Map<String, Any>):PlatformView {
    private val mTextView:TextView = TextView(context)

    companion object {
        const val DATA_KEY_CONTENT = "content"
    }

    init {
        this.mTextView.apply {
            this.text = text
            this.textSize = 20f
            this.typeface = Typeface.SANS_SERIF
            this.text = "No Data Received"

            if(context != null) {
                this.setTextColor(ContextCompat.getColor(context, android.R.color.holo_blue_light))
            }

            //flutter 傳遞過來的引數
            if (params != null && params.containsKey(DATA_KEY_CONTENT)) {
                this.text = params["content"] as String? ?: "N/A"
            }
        }
    }

    override fun getView(): View = mTextView
    override fun dispose() {}
}