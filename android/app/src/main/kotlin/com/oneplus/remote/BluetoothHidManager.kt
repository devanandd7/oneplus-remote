package com.oneplus.remote

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.Executors

@SuppressLint("MissingPermission")
class BluetoothHidManager(private val context: Context) {
    companion object {
        private const val TAG = "OnePlusBT_HID"
        private const val REPORT_ID_KEYBOARD: Byte = 1
        private const val REPORT_ID_CONSUMER: Byte = 2

        // Standard USB HID Keyboard Scan Codes
        private const val KEY_UP: Byte = 0x52
        private const val KEY_DOWN: Byte = 0x51
        private const val KEY_LEFT: Byte = 0x50
        private const val KEY_RIGHT: Byte = 0x4F
        private const val KEY_ENTER: Byte = 0x28
        private const val KEY_ESCAPE: Byte = 0x29

        // Consumer Control usages (16-bit)
        private const val USAGE_POWER: Short = 0x0030
        private const val USAGE_VOLUME_UP: Short = 0x00E9
        private const val USAGE_VOLUME_DOWN: Short = 0x00EA
        private const val USAGE_MUTE: Short = 0x00E2
        private const val USAGE_HOME: Short = 0x0223
        private const val USAGE_BACK: Short = 0x0224
        private const val USAGE_MENU: Short = 0x0040
        private const val USAGE_PLAY_PAUSE: Short = 0x00CD
        private const val USAGE_VOICE_SEARCH: Short = 0x0221
        private const val USAGE_SETTINGS: Short = 0x0096
        private const val USAGE_YOUTUBE: Short = 0x018A

        /**
         * Standard USB HID Composite Descriptor
         * Report 1: Standard Keyboard (D-Pad, Enter, Esc/Back)
         * Report 2: Consumer Control (Power, Volume, Mute, Home, Assistant)
         */
        private val hidReportDescriptor = byteArrayOf(
            // --- Report 1: Keyboard ---
            0x05.toByte(), 0x01.toByte(),       // USAGE_PAGE (Generic Desktop)
            0x09.toByte(), 0x06.toByte(),       // USAGE (Keyboard)
            0xA1.toByte(), 0x01.toByte(),       // COLLECTION (Application)
            0x85.toByte(), REPORT_ID_KEYBOARD,  //   REPORT_ID (1)
            0x05.toByte(), 0x07.toByte(),       //   USAGE_PAGE (Keyboard/Keypad)
            0x19.toByte(), 0xE0.toByte(),       //   USAGE_MINIMUM (Keyboard LeftControl)
            0x29.toByte(), 0xE7.toByte(),       //   USAGE_MAXIMUM (Keyboard Right GUI)
            0x15.toByte(), 0x00.toByte(),       //   LOGICAL_MINIMUM (0)
            0x25.toByte(), 0x01.toByte(),       //   LOGICAL_MAXIMUM (1)
            0x75.toByte(), 0x01.toByte(),       //   REPORT_SIZE (1)
            0x95.toByte(), 0x08.toByte(),       //   REPORT_COUNT (8)
            0x81.toByte(), 0x02.toByte(),       //   INPUT (Data,Var,Abs) - Modifiers
            0x95.toByte(), 0x01.toByte(),       //   REPORT_COUNT (1)
            0x75.toByte(), 0x08.toByte(),       //   REPORT_SIZE (8)
            0x81.toByte(), 0x01.toByte(),       //   INPUT (Cnst,Ary,Abs) - Reserved byte
            0x95.toByte(), 0x06.toByte(),       //   REPORT_COUNT (6)
            0x75.toByte(), 0x08.toByte(),       //   REPORT_SIZE (8)
            0x15.toByte(), 0x00.toByte(),       //   LOGICAL_MINIMUM (0)
            0x26.toByte(), 0xFF.toByte(), 0x00.toByte(), // LOGICAL_MAXIMUM (255)
            0x05.toByte(), 0x07.toByte(),       //   USAGE_PAGE (Keyboard/Keypad)
            0x19.toByte(), 0x00.toByte(),       //   USAGE_MINIMUM (0)
            0x29.toByte(), 0xFF.toByte(),       //   USAGE_MAXIMUM (255)
            0x81.toByte(), 0x00.toByte(),       //   INPUT (Data,Ary,Abs) - Key codes
            0xC0.toByte(),                      // END_COLLECTION

            // --- Report 2: Consumer Devices ---
            0x05.toByte(), 0x0C.toByte(),       // USAGE_PAGE (Consumer Devices)
            0x09.toByte(), 0x01.toByte(),       // USAGE (Consumer Control)
            0xA1.toByte(), 0x01.toByte(),       // COLLECTION (Application)
            0x85.toByte(), REPORT_ID_CONSUMER,  //   REPORT_ID (2)
            0x15.toByte(), 0x00.toByte(),       //   LOGICAL_MINIMUM (0)
            0x26.toByte(), 0xFF.toByte(), 0x03.toByte(), // LOGICAL_MAXIMUM (0x03FF)
            0x19.toByte(), 0x00.toByte(),       //   USAGE_MINIMUM (0)
            0x2A.toByte(), 0xFF.toByte(), 0x03.toByte(), // USAGE_MAXIMUM (0x03FF)
            0x75.toByte(), 0x10.toByte(),       //   REPORT_SIZE (16)
            0x95.toByte(), 0x01.toByte(),       //   REPORT_COUNT (1)
            0x81.toByte(), 0x00.toByte(),       //   INPUT (Data,Ary,Abs) - Usage Code
            0xC0.toByte()                       // END_COLLECTION
        )
    }

    private var bluetoothHidDevice: BluetoothHidDevice? = null
    var connectedDevice: BluetoothDevice? = null
        private set
    private var isAppRegistered = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    var onConnectionStateListener: ((state: String, deviceName: String?, deviceAddress: String?) -> Unit)? = null

    private val profileServiceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(TAG, "Bluetooth HID Device profile connected")
                bluetoothHidDevice = proxy as BluetoothHidDevice
                registerApp()
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(TAG, "Bluetooth HID Device profile disconnected")
                bluetoothHidDevice = null
                isAppRegistered = false
                connectedDevice = null
                notifyState("DISCONNECTED", null, null)
            }
        }
    }

    private val hidDeviceCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            Log.d(TAG, "onAppStatusChanged: registered=$registered, pluggedDevice=${pluggedDevice?.name} ($pluggedDevice)")
            isAppRegistered = registered
            if (pluggedDevice != null) {
                connectedDevice = pluggedDevice
                notifyState("CONNECTED", pluggedDevice.name ?: pluggedDevice.address, pluggedDevice.address)
            } else if (registered) {
                val hid = bluetoothHidDevice
                val connectedList = hid?.connectedDevices ?: emptyList()
                if (connectedList.isNotEmpty()) {
                    val activeDev = connectedList[0]
                    connectedDevice = activeDev
                    notifyState("CONNECTED", activeDev.name ?: activeDev.address, activeDev.address)
                } else {
                    connectedDevice = null
                    notifyState("READY_TO_PAIR", null, null)
                    autoConnectBondedTv()
                }
            } else {
                connectedDevice = null
                notifyState("UNREGISTERED", null, null)
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            val devName = try {
                device?.name ?: device?.address
            } catch (e: SecurityException) {
                device?.address
            }
            val devAddr = device?.address
            Log.d(TAG, "onConnectionStateChanged: device=$devName ($devAddr), state=$state")
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    notifyState("CONNECTED", devName, devAddr)
                }
                BluetoothProfile.STATE_CONNECTING -> {
                    notifyState("CONNECTING", devName, devAddr)
                }
                BluetoothProfile.STATE_DISCONNECTING -> {
                    notifyState("DISCONNECTING", devName, devAddr)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    if (connectedDevice?.address == devAddr || connectedDevice == device) {
                        connectedDevice = null
                    }
                    notifyState("DISCONNECTED", null, null)
                }
            }
        }
    }

    fun initialize(): Boolean {
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
            if (!adapter.isEnabled) return false

            return adapter.getProfileProxy(context, profileServiceListener, BluetoothProfile.HID_DEVICE)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException in initialize: ${e.message}")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Exception in initialize: ${e.message}")
            return false
        }
    }

    fun registerApp() {
        val hid = bluetoothHidDevice ?: return
        if (isAppRegistered) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "BLUETOOTH_CONNECT permission not yet granted; registerApp deferred")
                return
            }
        }

        try {
            val sdp = BluetoothHidDeviceAppSdpSettings(
                "OnePlus TV Remote",
                "OnePlus Smart Remote Controller",
                "OnePlus",
                BluetoothHidDevice.SUBCLASS1_COMBO,
                hidReportDescriptor
            )

            val qos = null // Default QoS
            hid.registerApp(sdp, qos, null, executor, hidDeviceCallback)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException registering HID app: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception registering HID app: ${e.message}")
        }
    }

    fun unregisterApp() {
        try {
            bluetoothHidDevice?.unregisterApp()
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException unregistering HID app: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception unregistering HID app: ${e.message}")
        }
        isAppRegistered = false
        connectedDevice = null
    }

    fun connectDevice(address: String): Boolean {
        val hid = bluetoothHidDevice ?: return false
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        return try {
            val dev = adapter.getRemoteDevice(address)
            Log.d(TAG, "Manually connecting HID to device: ${dev.name} ($address)")
            hid.connect(dev)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connectDevice ($address): ${e.message}")
            false
        }
    }

    fun getBondedDevices(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return list
        try {
            for (dev in adapter.bondedDevices) {
                list.add(
                    mapOf(
                        "name" to (dev.name ?: "Unknown Device"),
                        "address" to dev.address
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading bonded devices: ${e.message}")
        }
        return list
    }

    fun findBondedTv(): BluetoothDevice? {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return null
        return try {
            val bonded = adapter.bondedDevices
            bonded.firstOrNull {
                val n = it.name?.lowercase() ?: ""
                (n.contains("tv") || n.contains("oneplus") || n.contains("series")) &&
                !n.contains("buds") && !n.contains("headset") && !n.contains("ear")
            } ?: bonded.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "findBondedTv error: ${e.message}")
            null
        }
    }

    fun autoConnectBondedTv() {
        val hid = bluetoothHidDevice ?: return
        val tv = findBondedTv() ?: return
        try {
            if (hid.getConnectionState(tv) != BluetoothProfile.STATE_CONNECTED) {
                Log.d(TAG, "Auto-connecting in background to: ${tv.name} (${tv.address})")
                hid.connect(tv)
            }
        } catch (e: Exception) {
            Log.e(TAG, "autoConnectBondedTv error: ${e.message}")
        }
    }

    fun sendKey(keyName: String) {
        val hid = bluetoothHidDevice
        if (hid == null) {
            Log.w(TAG, "Cannot sendKey '$keyName': HID profile not initialized")
            return
        }

        var device = connectedDevice
        val isActuallyConnected = device != null && 
            hid.getConnectionState(device) == BluetoothProfile.STATE_CONNECTED

        if (!isActuallyConnected) {
            Log.w(TAG, "Device not active. Fast reconnecting before sending '$keyName'...")
            val tv = device ?: findBondedTv()
            if (tv != null) {
                connectedDevice = tv
                notifyState("CONNECTING", tv.name ?: tv.address, tv.address)
                try {
                    hid.connect(tv)
                } catch (e: Exception) {
                    Log.e(TAG, "Reconnection failed: ${e.message}")
                }
                // Queue the key press immediately after the connection handshake
                mainHandler.postDelayed({
                    if (hid.getConnectionState(tv) == BluetoothProfile.STATE_CONNECTED) {
                        dispatchKey(tv, keyName)
                    } else {
                        Log.w(TAG, "Fast reconnect pending for TV")
                    }
                }, 350)
                return
            } else {
                notifyState("DISCONNECTED", null, null)
                return
            }
        }

        dispatchKey(device!!, keyName)
    }

    private fun dispatchKey(device: BluetoothDevice, keyName: String) {
        Log.d(TAG, "Dispatching HID key '$keyName' to ${device.name ?: device.address}")
        try {
            when (keyName.uppercase()) {
                // Keyboard Usages
                "DPAD_UP" -> sendKeyboardReport(device, KEY_UP)
                "DPAD_DOWN" -> sendKeyboardReport(device, KEY_DOWN)
                "DPAD_LEFT" -> sendKeyboardReport(device, KEY_LEFT)
                "DPAD_RIGHT" -> sendKeyboardReport(device, KEY_RIGHT)
                "OK" -> sendKeyboardReport(device, KEY_ENTER)

                // Consumer Usages
                "POWER" -> sendConsumerReport(device, USAGE_POWER)
                "BACK" -> sendConsumerReport(device, USAGE_BACK)
                "HOME" -> sendConsumerReport(device, USAGE_HOME)
                "MENU" -> sendConsumerReport(device, USAGE_MENU)
                "VOLUME_UP" -> sendConsumerReport(device, USAGE_VOLUME_UP)
                "VOLUME_DOWN" -> sendConsumerReport(device, USAGE_VOLUME_DOWN)
                "MUTE" -> sendConsumerReport(device, USAGE_MUTE)
                "PLAY_PAUSE" -> sendConsumerReport(device, USAGE_PLAY_PAUSE)
                "ASSISTANT" -> sendConsumerReport(device, USAGE_VOICE_SEARCH)
                "CAMERA" -> {
                    Log.i(TAG, "Camera key triggered via Bluetooth HID")
                }
                "SETTINGS" -> sendConsumerReport(device, USAGE_SETTINGS)
                "YOUTUBE" -> sendConsumerReport(device, USAGE_YOUTUBE)
                else -> Log.w(TAG, "Unknown key '$keyName' requested for HID")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException in dispatchKey '$keyName': ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception in dispatchKey '$keyName': ${e.message}")
        }
    }

    private fun sendKeyboardReport(device: BluetoothDevice, scanCode: Byte) {
        val hid = bluetoothHidDevice ?: return
        val reportDown = byteArrayOf(0, 0, scanCode, 0, 0, 0, 0, 0)
        val reportUp = byteArrayOf(0, 0, 0, 0, 0, 0, 0, 0)

        try {
            val sent = hid.sendReport(device, REPORT_ID_KEYBOARD.toInt(), reportDown)
            if (!sent) {
                Log.w(TAG, "sendKeyboardReport down returned false (link might be inactive)")
                if (hid.getConnectionState(device) != BluetoothProfile.STATE_CONNECTED) {
                    connectedDevice = null
                    notifyState("DISCONNECTED", null, null)
                    autoConnectBondedTv()
                }
                return
            }
            mainHandler.postDelayed({
                try {
                    hid.sendReport(device, REPORT_ID_KEYBOARD.toInt(), reportUp)
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending key up: ${e.message}")
                }
            }, 50)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException sending keyboard report: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception sending keyboard report: ${e.message}")
        }
    }

    private fun sendConsumerReport(device: BluetoothDevice, usage: Short) {
        val hid = bluetoothHidDevice ?: return
        val reportDown = byteArrayOf((usage.toInt() and 0xFF).toByte(), ((usage.toInt() shr 8) and 0xFF).toByte())
        val reportUp = byteArrayOf(0, 0)

        try {
            val sent = hid.sendReport(device, REPORT_ID_CONSUMER.toInt(), reportDown)
            if (!sent) {
                Log.w(TAG, "sendConsumerReport down returned false (link might be inactive)")
                if (hid.getConnectionState(device) != BluetoothProfile.STATE_CONNECTED) {
                    connectedDevice = null
                    notifyState("DISCONNECTED", null, null)
                    autoConnectBondedTv()
                }
                return
            }
            mainHandler.postDelayed({
                try {
                    hid.sendReport(device, REPORT_ID_CONSUMER.toInt(), reportUp)
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending consumer report release: ${e.message}")
                }
            }, 50)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException sending consumer report: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Exception sending consumer report: ${e.message}")
        }
    }

    private fun notifyState(state: String, deviceName: String?, deviceAddress: String? = null) {
        mainHandler.post {
            onConnectionStateListener?.invoke(state, deviceName, deviceAddress)
        }
    }
}
