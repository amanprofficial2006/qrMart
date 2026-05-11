package com.example.qrmart_owner

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object OrderAlertNotifier {
    const val channelId = "orders_alerts_v2"
    const val channelName = "Order alerts"
    const val channelDescription =
        "Alerts and background notifications for new customer orders."

    private const val orderAlertSoundResource = "order_alert"
    private val legacyChannelIds = listOf("orders_alerts")
    private var activeRingtone: Ringtone? = null

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            context.getSystemService(NotificationManager::class.java)
        deleteLegacyChannels(notificationManager)
        val existingChannel = notificationManager.getNotificationChannel(channelId)

        if (existingChannel != null && existingChannel.sound != null) {
            notificationManager.deleteNotificationChannel(channelId)
        }

        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = channelDescription
            enableVibration(true)
            setShowBadge(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
        }

        notificationManager.createNotificationChannel(channel)
    }

    fun showOrderNotification(
        context: Context,
        title: String,
        body: String,
        orderId: String = "",
        playSound: Boolean = true
    ) {
        ensureChannel(context)

        val notificationId =
            if (orderId.isNotBlank()) orderId.hashCode() else System.currentTimeMillis().toInt()
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("notification_order_id", orderId)
        }

        val pendingIntent = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                notificationId,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setDefaults(Notification.DEFAULT_VIBRATE or Notification.DEFAULT_LIGHTS)
            .apply {
                if (pendingIntent != null) {
                    setContentIntent(pendingIntent)
                }
            }
            .build()

        NotificationManagerCompat.from(context).notify(notificationId, notification)

        if (playSound) {
            playAlertSound(context)
        }
    }

    fun playAlertSound(context: Context) {
        try {
            val soundUri =
                customSoundUri(context)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            activeRingtone?.stop()
            val ringtone =
                RingtoneManager.getRingtone(context.applicationContext, soundUri) ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone.audioAttributes =
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
            }

            activeRingtone = ringtone
            ringtone.play()
        } catch (_: Throwable) {
            // Keep notifications visible even if audio playback fails on a device.
        }
    }

    fun isAppInForeground(context: Context): Boolean {
        val activityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        val packageName = context.packageName
        val runningProcesses = activityManager.runningAppProcesses ?: return false

        return runningProcesses.any { process ->
            process.processName == packageName &&
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }

    private fun deleteLegacyChannels(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        legacyChannelIds.forEach { legacyChannelId ->
            if (notificationManager.getNotificationChannel(legacyChannelId) != null) {
                notificationManager.deleteNotificationChannel(legacyChannelId)
            }
        }
    }

    private fun customSoundUri(context: Context): Uri? {
        val resourceId =
            context.resources.getIdentifier(orderAlertSoundResource, "raw", context.packageName)

        if (resourceId == 0) {
            return null
        }

        return Uri.parse("android.resource://${context.packageName}/$resourceId")
    }
}
