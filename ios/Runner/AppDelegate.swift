import Flutter
import UIKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    private var methodChannel: FlutterMethodChannel?
    
    private var mouseReportCharacteristic: CBMutableCharacteristic?
    private var keyboardReportCharacteristic: CBMutableCharacteristic?
    
    private var connectedCentral: CBCentral?
    private var isAdvertising = false

    // Composite HID Report Descriptor (Mouse Report ID 1 + Keyboard Report ID 2)
    private let hidDescriptorBytes: [UInt8] = [
        // --- MOUSE (Report ID 1) ---
        0x05, 0x01, // USAGE_PAGE (Generic Desktop)
        0x09, 0x02, // USAGE (Mouse)
        0xA1, 0x01, // COLLECTION (Application)
        0x85, 0x01, //   REPORT_ID (1)
        0x09, 0x01, //   USAGE (Pointer)
        0xA1, 0x00, //   COLLECTION (Physical)
        // 3 Buttons (Left, Right, Middle)
        0x05, 0x09, //     USAGE_PAGE (Button)
        0x19, 0x01, //     USAGE_MINIMUM (1)
        0x29, 0x03, //     USAGE_MAXIMUM (3)
        0x15, 0x00, //     LOGICAL_MINIMUM (0)
        0x25, 0x01, //     LOGICAL_MAXIMUM (1)
        0x95, 0x03, //     REPORT_COUNT (3)
        0x75, 0x01, //     REPORT_SIZE (1)
        0x81, 0x02, //     INPUT (Data,Var,Abs)
        // Padding (5 bits)
        0x95, 0x01, //     REPORT_COUNT (1)
        0x75, 0x05, //     REPORT_SIZE (5)
        0x81, 0x03, //     INPUT (Cnst,Var,Abs)
        // Movement (X, Y, Wheel)
        0x05, 0x01, //     USAGE_PAGE (Generic Desktop)
        0x09, 0x30, //     USAGE (X)
        0x09, 0x31, //     USAGE (Y)
        0x09, 0x38, //     USAGE (Wheel)
        0x15, 0x81, //     LOGICAL_MINIMUM (-127)
        0x25, 0x7F, //     LOGICAL_MAXIMUM (127)
        0x75, 0x08, //     REPORT_SIZE (8)
        0x95, 0x03, //     REPORT_COUNT (3)
        0x81, 0x06, //     INPUT (Data,Var,Rel)
        0xC0,       //   END_COLLECTION
        0xC0,       // END_COLLECTION

        // --- KEYBOARD (Report ID 2) ---
        0x05, 0x01, // USAGE_PAGE (Generic Desktop)
        0x09, 0x06, // USAGE (Keyboard)
        0xA1, 0x01, // COLLECTION (Application)
        0x85, 0x02, //   REPORT_ID (2)
        // Modifier byte
        0x05, 0x07, //   USAGE_PAGE (Keyboard/Keypad)
        0x19, 0xE0, //   USAGE_MINIMUM (224)
        0x29, 0xE7, //   USAGE_MAXIMUM (231)
        0x15, 0x00, //   LOGICAL_MINIMUM (0)
        0x25, 0x01, //   LOGICAL_MAXIMUM (1)
        0x75, 0x01, //   REPORT_SIZE (1)
        0x95, 0x08, //   REPORT_COUNT (8)
        0x81, 0x02, //   INPUT (Data,Var,Abs)
        // Reserved byte
        0x95, 0x01, //   REPORT_COUNT (1)
        0x75, 0x08, //   REPORT_SIZE (8)
        0x81, 0x03, //   INPUT (Cnst,Var,Abs)
        // 6 Keycode bytes
        0x95, 0x06, //   REPORT_COUNT (6)
        0x75, 0x08, //   REPORT_SIZE (8)
        0x15, 0x00, //   LOGICAL_MINIMUM (0)
        0x25, 0x65, //   LOGICAL_MAXIMUM (101)
        0x05, 0x07, //   USAGE_PAGE (Keyboard/Keypad)
        0x19, 0x00, //   USAGE_MINIMUM (0)
        0x29, 0x65, //   USAGE_MAXIMUM (101)
        0x81, 0x00, //   INPUT (Data,Ary,Abs)
        0xC0        // END_COLLECTION
    ]

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let messenger = self.registrar(forPlugin: "ClickPadHidPlugin")?.messenger() {
            setupMethodChannel(binaryMessenger: messenger)
        }
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupMethodChannel(binaryMessenger: FlutterBinaryMessenger) {
        if methodChannel != nil { return }
        methodChannel = FlutterMethodChannel(name: "com.nawalokatech.clickpad/bluetooth_hid", binaryMessenger: binaryMessenger)
        
        methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            switch call.method {
            case "makeDiscoverable":
                self.startAdvertising()
                result(true)
            case "openBluetoothSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                    result(true)
                } else {
                    result(false)
                }
            case "getConnectedHost":
                if let central = self.connectedCentral {
                    result(["name": "Connected Desktop", "address": central.identifier.uuidString])
                } else {
                    result(nil)
                }
            case "sendMouseReport":
                if let args = call.arguments as? [String: Any] {
                    let button = args["button"] as? Int ?? 0
                    let dx = args["dx"] as? Int ?? 0
                    let dy = args["dy"] as? Int ?? 0
                    let wheel = args["wheel"] as? Int ?? 0
                    self.sendMouseReport(button: button, dx: dx, dy: dy, wheel: wheel)
                    result(true)
                } else {
                    result(false)
                }
            case "sendKeyboardReport":
                if let args = call.arguments as? [String: Any] {
                    let modifier = args["modifier"] as? Int ?? 0
                    let keycode = args["keycode"] as? Int ?? 0
                    self.sendKeyboardReport(modifier: modifier, keycode: keycode)
                    result(true)
                } else {
                    result(false)
                }
            case "disconnect":
                self.connectedCentral = nil
                self.notifyStateChange(isConnected: false, deviceName: "")
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            setupGattServices()
        }
    }

    private func setupGattServices() {
        guard let peripheralManager = peripheralManager else { return }
        peripheralManager.removeAllServices()

        // 1. Device Information Service (0x180A)
        let infoService = CBMutableService(type: CBUUID(string: "180A"), primary: true)
        let mfgChar = CBMutableCharacteristic(type: CBUUID(string: "2A29"), properties: [.read], value: Data("NawalokaTech".utf8), permissions: [.readable])
        let modelChar = CBMutableCharacteristic(type: CBUUID(string: "2A24"), properties: [.read], value: Data("ClickPad-HID".utf8), permissions: [.readable])
        infoService.characteristics = [mfgChar, modelChar]
        peripheralManager.add(infoService)

        // 2. Battery Service (0x180F)
        let batteryService = CBMutableService(type: CBUUID(string: "180F"), primary: true)
        let batteryLevelChar = CBMutableCharacteristic(type: CBUUID(string: "2A19"), properties: [.read], value: Data([100]), permissions: [.readable])
        batteryService.characteristics = [batteryLevelChar]
        peripheralManager.add(batteryService)

        // 3. HID Service (0x1812)
        let hidService = CBMutableService(type: CBUUID(string: "1812"), primary: true)
        
        // Protocol Mode (0x2A4E)
        let protocolModeChar = CBMutableCharacteristic(type: CBUUID(string: "2A4E"), properties: [.read, .writeWithoutResponse], value: Data([0x01]), permissions: [.readable, .writeable])

        // HID Information (0x2A4A)
        let hidInfoChar = CBMutableCharacteristic(type: CBUUID(string: "2A4A"), properties: [.read], value: Data([0x01, 0x01, 0x00, 0x02]), permissions: [.readable])

        // Report Map / Descriptor (0x2A4B)
        let reportMapChar = CBMutableCharacteristic(type: CBUUID(string: "2A4B"), properties: [.read], value: Data(hidDescriptorBytes), permissions: [.readable])

        // HID Control Point (0x2A4C)
        let controlPointChar = CBMutableCharacteristic(type: CBUUID(string: "2A4C"), properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])

        // Mouse Input Report (0x2A4D)
        let mouseReport = CBMutableCharacteristic(type: CBUUID(string: "2A4D"), properties: [.read, .notify], value: nil, permissions: [.readable])
        let mouseReportRef = CBMutableDescriptor(type: CBUUID(string: "2908"), value: Data([0x01, 0x01])) // Report ID 1, Type Input
        mouseReport.descriptors = [mouseReportRef]
        mouseReportCharacteristic = mouseReport

        // Keyboard Input Report (0x2A4D)
        let keyboardReport = CBMutableCharacteristic(type: CBUUID(string: "2A4D"), properties: [.read, .notify], value: nil, permissions: [.readable])
        let keyboardReportRef = CBMutableDescriptor(type: CBUUID(string: "2908"), value: Data([0x02, 0x01])) // Report ID 2, Type Input
        keyboardReport.descriptors = [keyboardReportRef]
        keyboardReportCharacteristic = keyboardReport

        hidService.characteristics = [protocolModeChar, hidInfoChar, reportMapChar, controlPointChar, mouseReport, keyboardReport]
        peripheralManager.add(hidService)
    }

    private func startAdvertising() {
        guard let peripheralManager = peripheralManager, peripheralManager.state == .poweredOn else { return }
        if isAdvertising { peripheralManager.stopAdvertising() }
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "1812")],
            CBAdvertisementDataLocalNameKey: "ClickPad"
        ]
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        connectedCentral = central
        notifyStateChange(isConnected: true, deviceName: "Connected Desktop (\(central.identifier.uuidString.prefix(8)))")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if connectedCentral?.identifier == central.identifier {
            connectedCentral = nil
            notifyStateChange(isConnected: false, deviceName: "")
        }
    }

    private func notifyStateChange(isConnected: Bool, deviceName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod("onConnectionChanged", arguments: [
                "isConnected": isConnected,
                "deviceName": deviceName,
                "deviceAddress": self?.connectedCentral?.identifier.uuidString ?? ""
            ])
        }
    }

    private func sendMouseReport(button: Int, dx: Int, dy: Int, wheel: Int) {
        guard let peripheralManager = peripheralManager,
              let char = mouseReportCharacteristic else { return }
        
        let b = UInt8(button & 0xFF)
        let x = UInt8(bitPattern: Int8(clamping: dx))
        let y = UInt8(bitPattern: Int8(clamping: dy))
        let w = UInt8(bitPattern: Int8(clamping: wheel))
        
        let reportData = Data([b, x, y, w])
        peripheralManager.updateValue(reportData, for: char, onSubscribedCentrals: nil)
    }

    private func sendKeyboardReport(modifier: Int, keycode: Int) {
        guard let peripheralManager = peripheralManager,
              let char = keyboardReportCharacteristic else { return }
        
        let mod = UInt8(modifier & 0xFF)
        let key = UInt8(keycode & 0xFF)
        
        let pressData = Data([mod, 0, key, 0, 0, 0, 0, 0])
        peripheralManager.updateValue(pressData, for: char, onSubscribedCentrals: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            let releaseData = Data([0, 0, 0, 0, 0, 0, 0, 0])
            peripheralManager.updateValue(releaseData, for: char, onSubscribedCentrals: nil)
        }
    }
}
