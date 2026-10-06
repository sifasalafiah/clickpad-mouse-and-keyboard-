package com.nawalokatech.clickpad

import android.Manifest
import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nawalokatech.clickpad/bluetooth_hid"
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var connectedHost: BluetoothDevice? = null
    private var methodChannel: MethodChannel? = null

    // Pre-allocated ByteArray to eliminate GC pressure during rapid mouse/keyboard inputs
    private val mouseReportBuffer = ByteArray(4)
    private val keyboardReportBuffer = ByteArray(8)

    private val discoveredDevicesMap = HashMap<String, String>()

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (BluetoothDevice.ACTION_FOUND == action) {
                val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                device?.let {
                    try {
                        if (hasBluetoothPermission()) {
                            val name = it.name ?: "Nearby Bluetooth Device (${it.address})"
                            discoveredDevicesMap[it.address] = name
                            
                            // Real-time push to Flutter
                            Handler(Looper.getMainLooper()).post {
                                methodChannel?.invokeMethod("onDeviceDiscovered", mapOf(
                                    "name" to name,
                                    "address" to it.address
                                ))
                            }
                        }
                    } catch (e: Exception) {}
                }
            } else if (BluetoothDevice.ACTION_BOND_STATE_CHANGED == action) {
                val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                val bondState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE)
                if (bondState == BluetoothDevice.BOND_BONDED && device != null) {
                    connectedHost = device
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        try {
                            bluetoothHidDevice?.connect(device)
                        } catch (e: Exception) {}
                        // HID state callback onConnectionStateChanged will call notifyStateChange when connected
                    } else {
                        notifyStateChange(true, device.name ?: "Connected Device", device.address)
                    }
                }
            }
        }
    }

    // Composite HID Report Descriptor for Mouse (Report ID 1) & Keyboard (Report ID 2)
    private val hidDescriptor = byteArrayOf(
        // --- MOUSE (Report ID 1) ---
        0x05.toByte(), 0x01.toByte(), // USAGE_PAGE (Generic Desktop)
        0x09.toByte(), 0x02.toByte(), // USAGE (Mouse)
        0xa1.toByte(), 0x01.toByte(), // COLLECTION (Application)
        0x85.toByte(), 0x01.toByte(), //   REPORT_ID (1)
        0x09.toByte(), 0x01.toByte(), //   USAGE (Pointer)
        0xa1.toByte(), 0x00.toByte(), //   COLLECTION (Physical)
        // 3 Buttons (Left, Right, Middle)
        0x05.toByte(), 0x09.toByte(), //     USAGE_PAGE (Button)
        0x19.toByte(), 0x01.toByte(), //     USAGE_MINIMUM (1)
        0x29.toByte(), 0x03.toByte(), //     USAGE_MAXIMUM (3)
        0x15.toByte(), 0x00.toByte(), //     LOGICAL_MINIMUM (0)
        0x25.toByte(), 0x01.toByte(), //     LOGICAL_MAXIMUM (1)
        0x95.toByte(), 0x03.toByte(), //     REPORT_COUNT (3)
        0x75.toByte(), 0x01.toByte(), //     REPORT_SIZE (1)
        0x81.toByte(), 0x02.toByte(), //     INPUT (Data,Var,Abs)
        // Padding (5 bits)
        0x95.toByte(), 0x01.toByte(), //     REPORT_COUNT (1)
        0x75.toByte(), 0x05.toByte(), //     REPORT_SIZE (5)
        0x81.toByte(), 0x03.toByte(), //     INPUT (Cnst,Var,Abs)
        // Movement (X, Y, Wheel)
        0x05.toByte(), 0x01.toByte(), //     USAGE_PAGE (Generic Desktop)
        0x09.toByte(), 0x30.toByte(), //     USAGE (X)
        0x09.toByte(), 0x31.toByte(), //     USAGE (Y)
        0x09.toByte(), 0x38.toByte(), //     USAGE (Wheel)
        0x15.toByte(), 0x81.toByte(), //     LOGICAL_MINIMUM (-127)
        0x25.toByte(), 0x7f.toByte(), //     LOGICAL_MAXIMUM (127)
        0x75.toByte(), 0x08.toByte(), //     REPORT_SIZE (8)
        0x95.toByte(), 0x03.toByte(), //     REPORT_COUNT (3)
        0x81.toByte(), 0x06.toByte(), //     INPUT (Data,Var,Rel)
        0xc0.toByte(),                //   END_COLLECTION
        0xc0.toByte(),                // END_COLLECTION

        // --- KEYBOARD (Report ID 2) ---
        0x05.toByte(), 0x01.toByte(), // USAGE_PAGE (Generic Desktop)
        0x09.toByte(), 0x06.toByte(), // USAGE (Keyboard)
        0xa1.toByte(), 0x01.toByte(), // COLLECTION (Application)
        0x85.toByte(), 0x02.toByte(), //   REPORT_ID (2)
        // Modifier byte (LCtrl, LShift, LAlt, LGui, RCtrl, RShift, RAlt, RGui)
        0x05.toByte(), 0x07.toByte(), //   USAGE_PAGE (Keyboard/Keypad)
        0x19.toByte(), 0xe0.toByte(), //   USAGE_MINIMUM (224)
        0x29.toByte(), 0xe7.toByte(), //   USAGE_MAXIMUM (231)
        0x15.toByte(), 0x00.toByte(), //   LOGICAL_MINIMUM (0)
        0x25.toByte(), 0x01.toByte(), //   LOGICAL_MAXIMUM (1)
        0x75.toByte(), 0x01.toByte(), //   REPORT_SIZE (1)
        0x95.toByte(), 0x08.toByte(), //   REPORT_COUNT (8)
        0x81.toByte(), 0x02.toByte(), //   INPUT (Data,Var,Abs)
        // Reserved byte
        0x95.toByte(), 0x01.toByte(), //   REPORT_COUNT (1)
        0x75.toByte(), 0x08.toByte(), //   REPORT_SIZE (8)
        0x81.toByte(), 0x03.toByte(), //   INPUT (Cnst,Var,Abs)
        // 6 Keycode bytes
        0x95.toByte(), 0x06.toByte(), //   REPORT_COUNT (6)
        0x75.toByte(), 0x08.toByte(), //   REPORT_SIZE (8)
        0x15.toByte(), 0x00.toByte(), //   LOGICAL_MINIMUM (0)
        0x25.toByte(), 0x65.toByte(), //   LOGICAL_MAXIMUM (101)
        0x05.toByte(), 0x07.toByte(), //   USAGE_PAGE (Keyboard/Keypad)
        0x19.toByte(), 0x00.toByte(), //   USAGE_MINIMUM (0)
        0x29.toByte(), 0x65.toByte(), //   USAGE_MAXIMUM (101) -> 0x65
        0x81.toByte(), 0x00.toByte(), //   INPUT (Data,Ary,Abs)
        0xc0.toByte()                 // END_COLLECTION
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        checkAndRequestBluetoothPermissions()

        try {
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
            }
            registerReceiver(bluetoothReceiver, filter)
        } catch (e: Exception) {}

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "makeDiscoverable" -> {
                    try {
                        if (hasBluetoothPermission()) {
                            bluetoothAdapter?.setName("ClickPad")
                            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
                                putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
                            }
                            startActivity(intent)
                            startBleAdvertising()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openBluetoothSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "disconnect" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            connectedHost?.let {
                                bluetoothHidDevice?.disconnect(it)
                            }
                        }
                        connectedHost = null
                        notifyStateChange(false, "", "")
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getPairedDevices" -> {
                    val pairedList = ArrayList<Map<String, String>>()
                    try {
                        if (hasBluetoothPermission()) {
                            // 1. Bonded / Paired Devices
                            bluetoothAdapter?.bondedDevices?.forEach { device ->
                                pairedList.add(mapOf(
                                    "name" to (device.name ?: "Paired Device (${device.address})"),
                                    "address" to device.address
                                ))
                            }
                            // 2. Discovered Devices
                            discoveredDevicesMap.forEach { (address, name) ->
                                val exists = pairedList.any { it["address"] == address }
                                if (!exists) {
                                    pairedList.add(mapOf("name" to name, "address" to address))
                                }
                            }
                            // Trigger fresh discovery scan
                            bluetoothAdapter?.cancelDiscovery()
                            bluetoothAdapter?.startDiscovery()
                        }
                    } catch (e: Exception) {}
                    result.success(pairedList)
                }
                "pairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null && hasBluetoothPermission()) {
                        try {
                            bluetoothAdapter?.cancelDiscovery()

                            val device = bluetoothAdapter?.getRemoteDevice(address)
                            if (device != null) {
                                if (device.bondState == BluetoothDevice.BOND_BONDED) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                        val connectedDevices = bluetoothHidDevice?.getConnectedDevices()
                                        val isAlreadyConnected = connectedDevices?.any { it.address == address } == true
                                        if (isAlreadyConnected) {
                                            connectedHost = device
                                            notifyStateChange(true, device.name ?: "Connected Device", device.address)
                                            result.success("connected")
                                        } else {
                                            try {
                                                bluetoothHidDevice?.connect(device)
                                            } catch (e: Exception) {}
                                            result.success("connecting_started")
                                        }
                                    } else {
                                        connectedHost = device
                                        notifyStateChange(true, device.name ?: "Connected Device", device.address)
                                        result.success("connected")
                                    }
                                } else {
                                    val bondingStarted = device.createBond()
                                    result.success(if (bondingStarted) "bonding_started" else "failed")
                                }
                            } else {
                                result.success("device_not_found")
                            }
                        } catch (e: Exception) {
                            result.success("error: ${e.message}")
                        }
                    } else {
                        result.success("no_permission")
                    }
                }
                "getConnectedHost" -> {
                    try {
                        if (hasBluetoothPermission()) {
                            if (connectedHost == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                val connectedDevices = bluetoothHidDevice?.getConnectedDevices()
                                if (!connectedDevices.isNullOrEmpty()) {
                                    connectedHost = connectedDevices[0]
                                }
                            }
                            if (connectedHost != null) {
                                result.success(mapOf(
                                    "name" to (connectedHost?.name ?: "Connected Desktop"),
                                    "address" to (connectedHost?.address ?: "")
                                ))
                                return@setMethodCallHandler
                            }
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "sendMouseReport" -> {
                    if (bluetoothAdapter?.isDiscovering == true && hasBluetoothPermission()) {
                        try {
                            bluetoothAdapter?.cancelDiscovery()
                        } catch (e: Exception) {}
                    }

                    val buttonMask = call.argument<Int>("button") ?: 0
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    val wheel = call.argument<Int>("wheel") ?: 0

                    mouseReportBuffer[0] = buttonMask.toByte()
                    mouseReportBuffer[1] = dx.toByte()
                    mouseReportBuffer[2] = dy.toByte()
                    mouseReportBuffer[3] = wheel.toByte()

                    sendHidReport(1, mouseReportBuffer)
                    result.success(true)
                }
                "sendKeyboardReport" -> {
                    val modifier = call.argument<Int>("modifier") ?: 0
                    val keycode = call.argument<Int>("keycode") ?: 0

                    keyboardReportBuffer[0] = modifier.toByte()
                    keyboardReportBuffer[1] = 0
                    keyboardReportBuffer[2] = keycode.toByte()
                    keyboardReportBuffer[3] = 0
                    keyboardReportBuffer[4] = 0
                    keyboardReportBuffer[5] = 0
                    keyboardReportBuffer[6] = 0
                    keyboardReportBuffer[7] = 0

                    sendHidReport(2, keyboardReportBuffer)

                    Handler(Looper.getMainLooper()).postDelayed({
                        keyboardReportBuffer[0] = 0
                        keyboardReportBuffer[2] = 0
                        sendHidReport(2, keyboardReportBuffer)
                    }, 20)

                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private var lastConnectedAddress: String? = null
    private var isHidAppRegistered = false

    private fun reconnectLastDevice() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || !hasBluetoothPermission()) return

        if (lastConnectedAddress == null) {
            try {
                lastConnectedAddress = getSharedPreferences("clickpad_prefs", Context.MODE_PRIVATE)
                    .getString("last_device_address", null)
            } catch (e: Exception) {}
        }

        val targetAddress = lastConnectedAddress ?: connectedHost?.address ?: return
        try {
            val device = bluetoothAdapter?.getRemoteDevice(targetAddress) ?: return
            connectedHost = device

            val connectedDevices = bluetoothHidDevice?.getConnectedDevices()
            val isAlreadyConnected = connectedDevices?.any { it.address == targetAddress } == true

            if (isAlreadyConnected) {
                notifyStateChange(true, device.name ?: "Connected Device", device.address)
            } else {
                bluetoothHidDevice?.connect(device)
            }
        } catch (e: Exception) {}
    }

    override fun onResume() {
        super.onResume()
        if (hasBluetoothPermission()) {
            if (bluetoothHidDevice == null) {
                initBluetoothHid()
            } else if (!isHidAppRegistered) {
                registerHidApp()
            } else {
                val connectedDevices = bluetoothHidDevice?.getConnectedDevices()
                if (!connectedDevices.isNullOrEmpty()) {
                    connectedHost = connectedDevices[0]
                    notifyStateChange(true, connectedHost?.name ?: "Connected Device", connectedHost?.address ?: "")
                } else {
                    notifyStateChange(false, "", "")
                }
            }
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(bluetoothReceiver)
        } catch (e: Exception) {}
        super.onDestroy()
    }

    private fun hasBluetoothPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun checkAndRequestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE
            )
            val missingPermissions = permissions.filter {
                checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
            }

            if (missingPermissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), 101)
            } else {
                initBluetoothHid()
            }
        } else {
            initBluetoothHid()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 101) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                initBluetoothHid()
            }
        }
    }

    private fun initBluetoothHid() {
        if (hasBluetoothPermission()) {
            try {
                bluetoothAdapter?.setName("ClickPad")
            } catch (e: Exception) {}
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && hasBluetoothPermission()) {
            try {
                bluetoothAdapter?.getProfileProxy(applicationContext, object : BluetoothProfile.ServiceListener {
                    override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                        if (profile == BluetoothProfile.HID_DEVICE) {
                            bluetoothHidDevice = proxy as BluetoothHidDevice
                            registerHidApp()
                        }
                    }

                    override fun onServiceDisconnected(profile: Int) {
                        if (profile == BluetoothProfile.HID_DEVICE) {
                            bluetoothHidDevice = null
                            isHidAppRegistered = false
                        }
                    }
                }, BluetoothProfile.HID_DEVICE)
            } catch (e: Exception) {}
        }
    }

    private fun registerHidApp() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && hasBluetoothPermission()) {
            try {
                // Set adapter name & start continuous background advertising silently
                try {
                    bluetoothAdapter?.name = "ClickPad"
                    startBleAdvertising()
                } catch (e: Exception) {}

                val sdpSettings = BluetoothHidDeviceAppSdpSettings(
                    "ClickPad",
                    "Bluetooth Touchpad",
                    "ClickPad",
                    0xC0.toByte(), // Mouse Subclass
                    hidDescriptor
                )

                bluetoothHidDevice?.registerApp(
                    sdpSettings,
                    null,
                    null,
                    Executors.newSingleThreadExecutor(),
                    object : BluetoothHidDevice.Callback() {
                        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
                            super.onAppStatusChanged(pluggedDevice, registered)
                            isHidAppRegistered = registered
                        }

                        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
                            super.onConnectionStateChanged(device, state)
                            if (state == BluetoothProfile.STATE_CONNECTED) {
                                if (device != null) {
                                    connectedHost = device
                                    lastConnectedAddress = device.address
                                    try {
                                        getSharedPreferences("clickpad_prefs", Context.MODE_PRIVATE)
                                            .edit()
                                            .putString("last_device_address", device.address)
                                            .apply()
                                    } catch (e: Exception) {}
                                }
                                try {
                                    bluetoothAdapter?.cancelDiscovery()
                                    notifyStateChange(true, device?.name ?: "Connected Device", device?.address ?: "")
                                } catch (e: Exception) {}
                            } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                                notifyStateChange(false, "", "")
                            }
                        }
                    }
                )
            } catch (e: Exception) {}
        }
    }

    private fun notifyStateChange(isConnected: Boolean, deviceName: String, deviceAddress: String = "") {
        Handler(Looper.getMainLooper()).post {
            methodChannel?.invokeMethod("onConnectionChanged", mapOf(
                "isConnected" to isConnected,
                "deviceName" to deviceName,
                "deviceAddress" to (if (deviceAddress.isNotEmpty()) deviceAddress else (connectedHost?.address ?: ""))
            ))
        }
    }

    private fun sendHidReport(reportId: Int, data: ByteArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && hasBluetoothPermission()) {
            try {
                var host = connectedHost
                if (host == null && bluetoothHidDevice != null) {
                    val connectedDevices = bluetoothHidDevice?.getConnectedDevices()
                    if (!connectedDevices.isNullOrEmpty()) {
                        host = connectedDevices[0]
                        connectedHost = host
                    }
                }
                if (host == null && lastConnectedAddress != null) {
                    try {
                        host = bluetoothAdapter?.getRemoteDevice(lastConnectedAddress)
                        connectedHost = host
                    } catch (e: Exception) {}
                }

                host?.let {
                    val sent = bluetoothHidDevice?.sendReport(it, reportId, data)
                    if (sent == false) {
                        bluetoothHidDevice?.connect(it)
                    }
                }
            } catch (e: Exception) {}
        }
    }

    private fun startBleAdvertising() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && hasBluetoothPermission()) {
            try {
                bluetoothAdapter?.setName("ClickPad")
                val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
                val settings = android.bluetooth.le.AdvertiseSettings.Builder()
                    .setAdvertiseMode(android.bluetooth.le.AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                    .setConnectable(true)
                    .setTimeout(0)
                    .setTxPowerLevel(android.bluetooth.le.AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                    .build()

                val data = android.bluetooth.le.AdvertiseData.Builder()
                    .setIncludeDeviceName(true)
                    .build()

                advertiser?.startAdvertising(settings, data, object : android.bluetooth.le.AdvertiseCallback() {
                    override fun onStartSuccess(settingsInEffect: android.bluetooth.le.AdvertiseSettings?) {
                        super.onStartSuccess(settingsInEffect)
                    }
                })
            } catch (e: Exception) {}
        }
    }
}
