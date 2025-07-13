package com.example.byui_rideshare // Ensure this matches your package name

import android.os.Bundle
import android.content.pm.PackageManager
import android.content.pm.Signature // Make sure Signature is imported if not already
import android.util.Base64
import android.util.Log
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
