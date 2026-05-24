package com.uqac.agroscan

import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.decorView.isForceDarkAllowed = false
        }
        window.setBackgroundDrawableResource(R.color.splash_white)
        super.onCreate(savedInstanceState)
    }
}
