package com.oneplus.tvcompanion

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.wifi.WifiManager
import android.os.Bundle
import android.provider.Settings
import android.text.format.Formatter
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : AppCompatActivity() {

    private lateinit var dotStatus: View
    private lateinit var tvAccessibilityStatus: TextView
    private lateinit var tvIpAddress: TextView
    private lateinit var tvClientCount: TextView
    private lateinit var tvCurrentApp: TextView
    private lateinit var btnOpenAccessibility: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        dotStatus = findViewById(R.id.dotStatus)
        tvAccessibilityStatus = findViewById(R.id.tvAccessibilityStatus)
        tvIpAddress = findViewById(R.id.tvIpAddress)
        tvClientCount = findViewById(R.id.tvClientCount)
        tvCurrentApp = findViewById(R.id.tvCurrentApp)
        btnOpenAccessibility = findViewById(R.id.btnOpenAccessibility)

        btnOpenAccessibility.setOnClickListener {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general settings
                startActivity(Intent(Settings.ACTION_SETTINGS))
            }
        }

        // Start Foreground Service
        TvCompanionServerService.startService(this)

        // Listen for screen state updates
        TvAccessibilityService.onStateChangedListener = {
            runOnUiThread { updateUi() }
        }

        TvWebSocketServer.onClientsChangedListener = {
            runOnUiThread { updateUi() }
        }
    }

    override fun onResume() {
        super.onResume()
        updateUi()
    }

    private fun updateUi() {
        val isActive = TvAccessibilityService.isServiceActive
        if (isActive) {
            dotStatus.setBackgroundColor(Color.parseColor("#00E676")) // Green
            tvAccessibilityStatus.text = "Accessibility Service: ACTIVE ✅"
            tvAccessibilityStatus.setTextColor(Color.parseColor("#00E676"))
            btnOpenAccessibility.text = "Accessibility Enabled (Open Settings)"
        } else {
            dotStatus.setBackgroundColor(Color.parseColor("#FFB300")) // Amber
            tvAccessibilityStatus.text = "Accessibility Service: NOT ENABLED ⚠️"
            tvAccessibilityStatus.setTextColor(Color.parseColor("#FFB300"))
            btnOpenAccessibility.text = "Enable Accessibility in Settings"
        }

        val ip = getLocalIpAddress()
        tvIpAddress.text = "WebSocket Server: ws://$ip:8765"
        tvClientCount.text = "Connected Mobile Remotes: ${TvWebSocketServer.connectedClients.size}"

        val curPkg = TvAccessibilityService.currentPackage
        val focus = TvAccessibilityService.currentFocusedText
        tvCurrentApp.text = "Active Screen: ${if (curPkg.isNotEmpty()) curPkg else "TV Home"} | Focus: ${if (focus.isNotEmpty()) focus else "None"}"
    }

    private fun getLocalIpAddress(): String {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiIp = Formatter.formatIpAddress(wifiManager.connectionInfo.ipAddress)
            if (wifiIp != "0.0.0.0" && wifiIp.isNotEmpty()) {
                return wifiIp
            }

            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val iface = interfaces.nextElement()
                val addresses = iface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val addr = addresses.nextElement()
                    if (!addr.isLoopbackAddress && addr is Inet4Address) {
                        return addr.hostAddress ?: "127.0.0.1"
                    }
                }
            }
        } catch (e: Exception) {
            // ignore
        }
        return "127.0.0.1"
    }

    override fun onDestroy() {
        super.onDestroy()
        TvAccessibilityService.onStateChangedListener = null
        TvWebSocketServer.onClientsChangedListener = null
    }
}
