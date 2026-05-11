package com.example.qrmart_owner

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationPermissionRequestCode = 1001
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        OrderAlertNotifier.ensureChannel(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qrmart_owner/notifications"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "createNotificationChannel" -> {
                    createNotificationChannel(call, result)
                }
                "ensureNotificationPermission" -> {
                    ensureNotificationPermission(result)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings(result)
                }
                "showOrderNotification" -> {
                    showOrderNotification(call, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        OrderAlertNotifier.ensureChannel(this)
        result.success(true)
    }

    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        val notificationsEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(notificationsEnabled)
            return
        }

        val permissionGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED

        if (permissionGranted) {
            result.success(notificationsEnabled)
            return
        }

        if (pendingNotificationPermissionResult != null) {
            result.error(
                "notification_permission_request_in_progress",
                "Notification permission request is already running.",
                null
            )
            return
        }

        pendingNotificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode
        )
    }

    private fun openNotificationSettings(result: MethodChannel.Result) {
        val intent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        result.success(true)
    }

    private fun showOrderNotification(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val title = call.argument<String>("title") ?: "New Order"
        val body = call.argument<String>("body") ?: "A new order was received."
        val orderId = call.argument<String>("orderId") ?: ""
        OrderAlertNotifier.showOrderNotification(this, title, body, orderId, playSound = true)
        result.success(true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == notificationPermissionRequestCode) {
            val granted =
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                    NotificationManagerCompat.from(this).areNotificationsEnabled()
            pendingNotificationPermissionResult?.success(granted)
            pendingNotificationPermissionResult = null
            return
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
