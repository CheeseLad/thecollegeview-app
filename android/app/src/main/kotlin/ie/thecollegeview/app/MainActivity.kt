package ie.thecollegeview.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val maxRate = display?.supportedModes?.maxByOrNull { it.refreshRate }?.refreshRate ?: 0f
            if (maxRate > 0f) {
                window.attributes = window.attributes.apply {
                    preferredRefreshRate = maxRate
                }
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            val defaultDisplay = windowManager.defaultDisplay
            val maxMode = defaultDisplay?.supportedModes?.maxByOrNull { it.refreshRate }
            if (maxMode != null) {
                window.attributes = window.attributes.apply {
                    preferredDisplayModeId = maxMode.modeId
                }
            }
        }
    }
}
