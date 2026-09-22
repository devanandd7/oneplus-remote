package com.oneplus.tvcompanion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class TvCompanionServerService : Service() {

    companion object {
        private const val TAG = "TvServerService"
        private const val CHANNEL_ID = "oneplus_tv_companion_channel"
        private const val NOTIFICATION_ID = 8765

        fun startService(context: Context) {
            val intent = Intent(context, TvCompanionServerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var server: TvWebSocketServer? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = buildForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)

        startWebSocketServer()
    }

    private fun startWebSocketServer() {
        try {
            if (server == null) {
                server = TvWebSocketServer(8765)
                server?.start()
                Log.i(TAG, "Started WebSocket server on port 8765")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start WebSocket server: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "OnePlus TV Companion Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps TV Accessibility Remote Server active"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("OnePlus TV Remote Companion")
            .setContentText("Listening for mobile remote on port 8765")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (server == null) {
            startWebSocketServer()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            server?.stop()
            server = null
            Log.i(TAG, "WebSocket server stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping server: ${e.message}")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
