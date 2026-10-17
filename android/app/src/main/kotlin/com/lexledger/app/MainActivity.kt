package com.lexledger.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // SEC-06: Prevent screen capture and recents snapshot data leaks on Android
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

