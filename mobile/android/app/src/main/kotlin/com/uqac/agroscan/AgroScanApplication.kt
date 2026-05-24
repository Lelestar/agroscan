package com.uqac.agroscan

import android.app.Application
import android.content.Context
import android.content.res.Configuration
import androidx.appcompat.app.AppCompatDelegate

/** Light splash (logo on white) even when system / MIUI dark mode is on. */
class AgroScanApplication : Application() {
    override fun attachBaseContext(base: Context) {
        val config = Configuration(base.resources.configuration)
        config.uiMode =
            (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                Configuration.UI_MODE_NIGHT_NO
        super.attachBaseContext(base.createConfigurationContext(config))
    }

    override fun onCreate() {
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
        super.onCreate()
    }
}
