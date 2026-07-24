package com.yomi.flutter_restaruant

import android.os.Bundle
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        GoogleApiAvailability.getInstance().makeGooglePlayServicesAvailable(this);
    }
}
