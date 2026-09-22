package com.oneplus.tvcompanion

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class TvAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "TvAccessibilityService"
        var instance: TvAccessibilityService? = null
            private set

        var currentPackage: String = ""
            private set
        var currentActivity: String = ""
            private set
        var currentFocusedText: String = ""
            private set
        var isServiceActive: Boolean = false
            private set

        var onStateChangedListener: (() -> Unit)? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isServiceActive = true
        Log.i(TAG, "Accessibility Service Connected and Ready!")

        // Ensure background WebSocket server service is running
        TvCompanionServerService.startService(this)
        onStateChangedListener?.invoke()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        var changed = false

        if (event.packageName != null) {
            val pkg = event.packageName.toString()
            if (pkg != currentPackage) {
                currentPackage = pkg
                changed = true
            }
        }

        if (event.className != null) {
            val cls = event.className.toString()
            if (cls != currentActivity) {
                currentActivity = cls
                changed = true
            }
        }

        if (event.eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED) {
            val text = event.text?.joinToString(" ") ?: ""
            val contentDesc = event.contentDescription?.toString() ?: ""
            val focusDesc = if (text.isNotBlank()) text else contentDesc
            if (focusDesc != currentFocusedText) {
                currentFocusedText = focusDesc
                changed = true
            }
        }

        if (changed) {
            Log.d(TAG, "Screen update: Pkg=$currentPackage, Act=$currentActivity, Focus=$currentFocusedText")
            onStateChangedListener?.invoke()
            TvWebSocketServer.broadcastCurrentState()
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceActive = false
        if (instance == this) {
            instance = null
        }
        Log.i(TAG, "Accessibility Service Destroyed")
        onStateChangedListener?.invoke()
    }

    fun launchApp(packageName: String): Boolean {
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                startActivity(launchIntent)
                Log.i(TAG, "Successfully launched app: $packageName")
                true
            } else {
                Log.e(TAG, "Launch intent not found for package: $packageName")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching package $packageName: ${e.message}")
            false
        }
    }

    fun clickNodeByText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val nodes = root.findAccessibilityNodeInfosByText(text)
        for (node in nodes) {
            if (node.isClickable) {
                val success = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (success) {
                    Log.i(TAG, "Clicked node with text: $text")
                    return true
                }
            }
            // Check parent clickable
            var parent = node.parent
            while (parent != null) {
                if (parent.isClickable) {
                    val success = parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    if (success) {
                        Log.i(TAG, "Clicked parent of node with text: $text")
                        return true
                    }
                }
                parent = parent.parent
            }
        }
        return false
    }

    fun performGlobal(action: Int): Boolean {
        val success = performGlobalAction(action)
        Log.i(TAG, "Performed global action $action: success=$success")
        return success
    }
}
