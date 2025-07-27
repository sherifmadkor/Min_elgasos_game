package com.sherifmadkor.minelgasos

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Allow Flutter content to draw under status- and nav-bars for true edge-to-edge
    }
}
