package com.oneplus.remote

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "oneplus_remote/hid"
    private val EVENT_CHANNEL = "oneplus_remote/hid_events"
    private val PERMISSION_REQUEST_BT = 1001

    private var hidManager: BluetoothHidManager? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestBtPermissions()
    }

    private fun checkAndRequestBtPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = mutableListOf<String>()
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            }
            if (permissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_BT)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_BT) {
            val connectGranted = permissions.indices.any { 
                permissions[it] == Manifest.permission.BLUETOOTH_CONNECT && grantResults[it] == PackageManager.PERMISSION_GRANTED 
            }
            if (connectGranted) {
                hidManager?.registerApp()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        hidManager = BluetoothHidManager(applicationContext)
        hidManager?.onConnectionStateListener = { state, deviceName ->
            val event = mapOf(
                "state" to state,
                "deviceName" to (deviceName ?: "")
            )
            eventSink?.success(event)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeHid" -> {
                    checkAndRequestBtPermissions()
                    val success = hidManager?.initialize() ?: false
                    result.success(success)
                }
                "sendKey" -> {
                    val keyName = call.argument<String>("key") ?: ""
                    hidManager?.sendKey(keyName)
                    result.success(true)
                }
                "unregisterHid" -> {
                    hidManager?.unregisterApp()
                    result.success(true)
                }
                "getBondedDevices" -> {
                    val list = hidManager?.getBondedDevices() ?: emptyList()
                    result.success(list)
                }
                "connectDevice" -> {
                    val address = call.argument<String>("address") ?: ""
                    val success = hidManager?.connectDevice(address) ?: false
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    override fun onDestroy() {
        hidManager?.unregisterApp()
        super.onDestroy()
    }
}
