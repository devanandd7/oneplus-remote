package com.oneplus.tvcompanion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i("BootReceiver", "TV Boot Completed: Starting OnePlus TV Companion Server")
            TvCompanionServerService.startService(context)
        }
    }
}
