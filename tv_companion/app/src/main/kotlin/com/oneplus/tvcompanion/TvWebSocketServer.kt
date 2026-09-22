package com.oneplus.tvcompanion

import android.accessibilityservice.AccessibilityService
import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap

class TvWebSocketServer(port: Int = 8765) : WebSocketServer(InetSocketAddress(port)) {

    companion object {
        private const val TAG = "TvWebSocketServer"
        var activeInstance: TvWebSocketServer? = null
            private set

        val connectedClients = ConcurrentHashMap.newKeySet<WebSocket>()
        var onClientsChangedListener: (() -> Unit)? = null

        fun broadcastCurrentState() {
            activeInstance?.let { server ->
                val state = mapOf(
                    "type" to "STATE_UPDATE",
                    "package" to TvAccessibilityService.currentPackage,
                    "activity" to TvAccessibilityService.currentActivity,
                    "focused" to TvAccessibilityService.currentFocusedText,
                    "accessibilityActive" to TvAccessibilityService.isServiceActive
                )
                val json = Gson().toJson(state)
                server.broadcast(json)
            }
        }
    }

    private val scope = CoroutineScope(Dispatchers.Default)

    init {
        isReuseAddr = true
    }

    override fun onStart() {
        Log.i(TAG, "TvWebSocketServer started on port: $port")
        activeInstance = this
    }

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake?) {
        Log.i(TAG, "Client connected: ${conn.remoteSocketAddress}")
        connectedClients.add(conn)
        onClientsChangedListener?.invoke()

        // Send current state immediately upon connection
        val welcomeState = mapOf(
            "type" to "WELCOME",
            "server" to "OnePlus TV Remote Companion v1.0",
            "package" to TvAccessibilityService.currentPackage,
            "activity" to TvAccessibilityService.currentActivity,
            "focused" to TvAccessibilityService.currentFocusedText,
            "accessibilityActive" to TvAccessibilityService.isServiceActive
        )
        conn.send(Gson().toJson(welcomeState))
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String?, remote: Boolean) {
        Log.i(TAG, "Client disconnected: ${conn.remoteSocketAddress}, reason: $reason")
        connectedClients.remove(conn)
        onClientsChangedListener?.invoke()
    }

    override fun onMessage(conn: WebSocket, message: String) {
        Log.d(TAG, "Received message: $message")
        try {
            val json = JsonParser.parseString(message).asJsonObject
            val action = json.get("action")?.asString?.uppercase() ?: ""
            val requestId = json.get("requestId")?.asString

            when (action) {
                "PING" -> {
                    val resp = JsonObject().apply {
                        addProperty("type", "PONG")
                        if (requestId != null) addProperty("requestId", requestId)
                        addProperty("package", TvAccessibilityService.currentPackage)
                        addProperty("accessibilityActive", TvAccessibilityService.isServiceActive)
                    }
                    conn.send(resp.toString())
                }

                "GET_STATE" -> {
                    val resp = JsonObject().apply {
                        addProperty("type", "STATE")
                        if (requestId != null) addProperty("requestId", requestId)
                        addProperty("package", TvAccessibilityService.currentPackage)
                        addProperty("activity", TvAccessibilityService.currentActivity)
                        addProperty("focused", TvAccessibilityService.currentFocusedText)
                        addProperty("accessibilityActive", TvAccessibilityService.isServiceActive)
                    }
                    conn.send(resp.toString())
                }

                "LAUNCH_APP" -> {
                    val pkg = json.get("package")?.asString ?: ""
                    val service = TvAccessibilityService.instance
                    val success = service?.launchApp(pkg) ?: false
                    val resp = JsonObject().apply {
                        addProperty("type", "ACK")
                        if (requestId != null) addProperty("requestId", requestId)
                        addProperty("action", "LAUNCH_APP")
                        addProperty("target", pkg)
                        addProperty("success", success)
                        addProperty("message", if (success) "Launch intent dispatched" else "App launch failed or service inactive")
                    }
                    conn.send(resp.toString())
                }

                "CLICK_TEXT" -> {
                    val text = json.get("text")?.asString ?: ""
                    val service = TvAccessibilityService.instance
                    val success = service?.clickNodeByText(text) ?: false
                    val resp = JsonObject().apply {
                        addProperty("type", "ACK")
                        if (requestId != null) addProperty("requestId", requestId)
                        addProperty("action", "CLICK_TEXT")
                        addProperty("target", text)
                        addProperty("success", success)
                    }
                    conn.send(resp.toString())
                }

                "GLOBAL_ACTION" -> {
                    val key = json.get("key")?.asString?.uppercase() ?: ""
                    val actionCode = when (key) {
                        "HOME" -> AccessibilityService.GLOBAL_ACTION_HOME
                        "BACK" -> AccessibilityService.GLOBAL_ACTION_BACK
                        "RECENTS" -> AccessibilityService.GLOBAL_ACTION_RECENTS
                        "NOTIFICATIONS" -> AccessibilityService.GLOBAL_ACTION_NOTIFICATIONS
                        else -> -1
                    }
                    val service = TvAccessibilityService.instance
                    val success = if (actionCode != -1) {
                        service?.performGlobal(actionCode) ?: false
                    } else false

                    val resp = JsonObject().apply {
                        addProperty("type", "ACK")
                        if (requestId != null) addProperty("requestId", requestId)
                        addProperty("action", "GLOBAL_ACTION")
                        addProperty("key", key)
                        addProperty("success", success)
                    }
                    conn.send(resp.toString())
                }

                "VERIFY_SCREEN" -> {
                    val expectedPackage = json.get("expectedPackage")?.asString ?: ""
                    val timeoutMs = json.get("timeoutMs")?.asLong ?: 4000L

                    scope.launch {
                        var elapsed = 0L
                        var matched = false
                        while (elapsed < timeoutMs) {
                            if (TvAccessibilityService.currentPackage.equals(expectedPackage, ignoreCase = true)) {
                                matched = true
                                break
                            }
                            delay(150)
                            elapsed += 150
                        }

                        val resp = JsonObject().apply {
                            addProperty("type", "VERIFY_RESULT")
                            if (requestId != null) addProperty("requestId", requestId)
                            addProperty("expectedPackage", expectedPackage)
                            addProperty("actualPackage", TvAccessibilityService.currentPackage)
                            addProperty("matched", matched)
                            addProperty("elapsedMs", elapsed)
                        }
                        conn.send(resp.toString())
                    }
                }

                else -> {
                    val err = JsonObject().apply {
                        addProperty("type", "ERROR")
                        addProperty("message", "Unknown action: $action")
                    }
                    conn.send(err.toString())
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing incoming message: ${e.message}")
        }
    }

    override fun onError(conn: WebSocket?, ex: Exception?) {
        Log.e(TAG, "Server error: ${ex?.message}")
    }
}
