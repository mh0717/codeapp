//
//  PYDebugMenu.swift
//  Code
//
//  Created by huima on 2025/5/9.
//

import SwiftUI

struct PYDebugMenu: View {

    @EnvironmentObject var App: MainApp
    @EnvironmentObject var subIapManager: SubIapManager

    var body: some View {
        Section("PYUI Debug Menu") {
            Button("Bluetooth") {
                bm = BLEService()
                bm?.onInitialized()
                
                ideServiceManager.onInitialized()
                CalendarService().onInitialized()
            }
        }
    }
}

struct IDECommandMessage: HandyJSON {
    public init() {
        
    }
    
    public var uuid: Int = 0
    public var method: String = ""
    public var params: [String: Any]?
    public var response: Any?
    public var error: String?
}

protocol IDEService {
    func onInitialized()
}

class BaseIDEServiceManager: IDEService {
    var context: SwiftyZeroMQ.Context?
    var shellSocket: SwiftyZeroMQ.Socket?
    var shellQueue = DispatchQueue(label: "BaseIDEServiceManager_QUEUE")
    var commandHandlerMap = [String: (IDECommandMessage) -> Void]()
    
    private var currCommand: IDECommandMessage?
    private var currTimer: Timer?
    
    func startCommand(_ command: IDECommandMessage) {
        assert(self.currCommand == nil)
        self.currCommand = command
        self.currTimer?.invalidate()
        DispatchQueue.main.async {
            self.currTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
                if self.currCommand != nil {
                    var command = self.currCommand!
                    command.response = NSNull()
                    command.error = "timeout"
                    self.currCommand = nil
                    self.replyShell(command)
                }
                self.currTimer?.invalidate()
                self.currTimer = nil
            })
        }
    }
    
    func endCommand(_ command: IDECommandMessage) {
        assert(self.currCommand?.uuid == command.uuid)
        self.currCommand = nil
        self.currTimer?.invalidate()
        self.currTimer = nil
        replyShell(command)
    }
    
    func onInitialized() {
        do {
            context = try SwiftyZeroMQ.Context()
            shellSocket = try context?.socket(.reply)
            try shellSocket?.bind("tcp://*:5556")
        } catch {
            print("BLEService error: \(error)")
        }
        
        shellQueue.async {
            while true {
                guard let frames = try? self.shellSocket?.recvMultipart(),
                      let frame = frames.first,
                      let jsonStr = String(data: frame, encoding: .utf8) else {
                    continue
                }
                print("shellSocket recv: \(jsonStr)")
                if let command = IDECommandMessage.deserialize(from: jsonStr) {
                    self.handleCommand(command)
                } else {
                    try? self.shellSocket?.send(string: "{\"error\":\"not json\", \"response\": null}")
                }
            }
        }
    }
    
    func replyShell(_ command: IDECommandMessage) {
        if let cmdJson = command.toJSONString() {
            print("shellSocket send: \(cmdJson)")
            do {
                try shellSocket?.send(string: cmdJson)
            } catch {
                print("replyShell error: \(error)")
            }
        }
    }
    
    func handleCommand(_ command: IDECommandMessage) {
        if let handler = commandHandlerMap[command.method] {
            handler(command)
        } else {
            var command = command
            command.response = NSNull()
            command.error = "not implemented"
            replyShell(command)
        }
    }
    
    func registryCommandHandler(name: String, handler: @escaping (IDECommandMessage) -> Void) {
        commandHandlerMap[name] = handler
    }
}

var ideServiceManager = BaseIDEServiceManager()

fileprivate var bm: BLEService?


//fileprivate var bm: BluetoothManager?

import CoreBluetooth
import SwiftyZeroMQ
import HandyJSON

fileprivate struct CommandMessage: HandyJSON {
    public init() {
        
    }
    
    public var method: String = ""
    public var params: Any?
    public var response: Any?
    public var error: String?
}

class BLEService: NSObject, IDEService, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var context: SwiftyZeroMQ.Context?
    var shellSocket: SwiftyZeroMQ.Socket?
    var shellQueue = DispatchQueue(label: "IDEServiceShellQueue")
    
    var devices = [CBPeripheral]()
    var noteReplyDevices = [CBPeripheral]()
    var currDevice: CBPeripheral?
    private var currTimer: Timer?
    private var scanTimer: Timer?
    
    private var currCommand: CommandMessage? {
        didSet {
            if currCommand != nil {
                currTimer?.invalidate()
                DispatchQueue.main.async {
                    self.currTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
                        if self.currCommand != nil {
                            var command = self.currCommand!
                            command.response = NSNull()
                            self.currCommand = nil
                            self.replyShell(command)
                        }
                        self.currTimer?.invalidate()
                        self.currTimer = nil
                    })
                }
            } else {
                self.currTimer?.invalidate()
                self.currTimer = nil
            }
        }
    }
    
    func onInitialized() {
        do {
            context = try SwiftyZeroMQ.Context()
            shellSocket = try context?.socket(.reply)
            try shellSocket?.bind("tcp://*:5555")
        } catch {
            print("BLEService error: \(error)")
        }
        
        shellQueue.async {
            while true {
                guard let frame = try? self.shellSocket?.recv() else {
                    continue
                }
                print("shellSocket recv: \(frame)")
                if let command = CommandMessage.deserialize(from: frame) {
                    self.handleCommand(command)
                } else {
                    try? self.shellSocket?.send(string: "{\"error\":\"not json\"}")
                }
            }
        }
    }
    
    private func replyShell(_ command: CommandMessage) {
        if let cmdJson = command.toJSONString() {
            print("shellSocket send: \(cmdJson)")
            do {
                try shellSocket?.send(string: cmdJson)
            } catch {
                print("replyShell error: \(error)")
            }
        }
    }
    
    fileprivate func handleCommand(_ command: CommandMessage) {
        if command.method == "openAdapter" {
            if centralManager != nil {
                var command = command
                command.response = true
                replyShell(command)
            } else {
                currCommand = command
                centralManager = CBCentralManager(delegate: self, queue: nil)
            }
            return
        }
        
        
        if command.method == "getState" {
            var command = command
            command.response = stateString()
            replyShell(command)
            return
        }
        
        if command.method == "startScan" {
            devices.clear()
            noteReplyDevices.clear()
            
            scanTimer?.invalidate()
            DispatchQueue.main.async {
                self.scanTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
                    self.scanTimer?.invalidate()
                    self.scanTimer = nil
                    if self.currCommand?.method == "findNextDevice" {
                        var command = self.currCommand!
                        self.currCommand = nil
                        command.response = NSNull()
                        self.replyShell(command)
                    }
                    self.centralManager?.stopScan()
                })
            }
            
            var command = command
            command.response = isAvaliable()
            replyShell(command)
            
            var serviceUUIDs: [CBUUID]? = nil
            var options: [String: Any]? = nil
            if let params = command.params as? [String: Any] {
                if let uuids = params["ids"] as? [String] {
                    serviceUUIDs = uuids.map {CBUUID(string: $0)}
                }
                options = params["options"] as? [String: Any]
            }
            DispatchQueue.main.async {
                self.centralManager?.scanForPeripherals(withServices: serviceUUIDs, options: options)
            }
            return
        }
        
        if command.method == "stopScan" {
            self.scanTimer?.invalidate()
            self.scanTimer = nil
            var command = command
            command.response = isAvaliable()
            replyShell(command)
            DispatchQueue.main.async {
                self.centralManager?.stopScan()
            }
            return
        }
        
        if command.method == "findNextDevice" {
            if !isAvaliable() {
                var command = command
                command.response = false
                replyShell(command)
                return
            }
            
            if !noteReplyDevices.isEmpty {
                var command = command
                let device = noteReplyDevices.removeFirst()
                command.response = [device.identifier.uuidString, device.name ?? "", device.rssi?.intValue ?? 0]
                replyShell(command)
                return
            }
            
            if scanTimer == nil {
                var command = command
                command.response = NSNull()
                replyShell(command)
                return
            }
            
            currCommand = command
            
            return
        }
        
        if command.method == "connectDevice" {
            var uuid: String?
            var options: [String: Any]?
            if let params = command.params as? String {
                uuid = params
            } else if let params = command.params as? [Any] {
                uuid = params.first as? String
                options = params.last as? [String: Any]
            }
            
            guard let uuid,  let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
                var command = command
                command.response = false
                replyShell(command)
                return
            }
            
            if device.state == .connected {
                var command = command
                command.response = true
                replyShell(command)
                return
            }
            
            self.currCommand = command
            DispatchQueue.main.async {
                self.centralManager?.connect(device, options: options)
            }
            
            return
        }
        
        if command.method == "disconnectDevice" {
            guard let uuid = command.params as? String,
                  let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
                var command = command
                command.response = false
                replyShell(command)
                return
            }
            
            device.delegate = nil
            var command = command
            command.response = true
            replyShell(command)
            DispatchQueue.main.async {
                self.centralManager?.cancelPeripheralConnection(device)
            }
            return
        }
        
        if command.method == "getDeviceState" {
            var command = command
            guard let uuid = command.params as? String,
                  let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
                command.response = false
                command.error = "unknown device"
                replyShell(command)
                return
            }
            var state: String = "unknown"
            switch device.state {
            case .disconnected:
                state = "disconnected"
            case .connecting:
                state = "connecting"
            case .connected:
                state = "connected"
            case .disconnecting:
                state = "disconnecting"
            }
            command.response = state
            replyShell(command)
            return
        }
        
        if command.method == "readDeviceRSSI" {
            var command = command
            guard let uuid = command.params as? String,
                  let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
                command.response = false
                command.error = "unknown device"
                replyShell(command)
                return
            }
            var state: String = "unknown"
            switch device.state {
            case .disconnected:
                state = "disconnected"
            case .connecting:
                state = "connecting"
            case .connected:
                state = "connected"
            case .disconnecting:
                state = "disconnecting"
            }
            command.response = state
            replyShell(command)
            return
        }
        
        if command.method == "getServices" {
            var command = command
            guard let uuid = command.params as? String,
                  let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
                command.response = false
                replyShell(command)
                return
            }
            
            device.delegate = nil
            self.currCommand = command
            DispatchQueue.main.async {
                device.readRSSI()
            }
            return
        }
        
        if command.method == "getCharacteristics" {
            var command = command
            guard let params = command.params as? [String],
                  let uuid = params.first,
                  let sid = params.last,
                  let device = devices.first(where: {$0.identifier.uuidString == uuid}),
                  let service = device.services?.first(where: {$0.uuid.uuidString == sid}) else {
                command.response = false
                command.error = "not found)"
                replyShell(command)
                return
            }
            
            device.delegate = self
            self.currCommand = command
            DispatchQueue.main.async {
                device.discoverCharacteristics(nil, for: service)
            }
        }
        
        if command.method == "readValue" {
            guard let params = command.params as? [String],
                  params.count >= 3,
                  let device = devices.first(where: {$0.identifier.uuidString == params[0]}),
                  let service = device.services?.first(where: {$0.uuid.uuidString == params[1]}),
                  let chr = service.characteristics?.first(where: {$0.uuid.uuidString == params[2]}) else {
                var command = command
                command.response = false
                command.error = "not found)"
                replyShell(command)
                return
            }
            
            device.delegate = self
            self.currCommand = command
            DispatchQueue.main.async {
                device.readValue(for: chr)
            }
            return
        }
        
        if command.method == "writeValue" {
            guard let params = command.params as? [String],
                  params.count >= 5,
                  let data = Data(base64Encoded: params[3]),
                  let device = devices.first(where: {$0.identifier.uuidString == params[0]}),
                  let service = device.services?.first(where: {$0.uuid.uuidString == params[1]}),
                  let chr = service.characteristics?.first(where: {$0.uuid.uuidString == params[2]}) else {
                var command = command
                command.response = false
                command.error = "not found"
                replyShell(command)
                return
            }
            
            let writeType = params[4]
            
            if writeType != "response" {
                var command = command
                command.response = true
                replyShell(command)
                DispatchQueue.main.async {
                    device.writeValue(data, for: chr, type: .withoutResponse)
                }
                return
            }
            
            
            device.delegate = self
            self.currCommand = command
            DispatchQueue.main.async {
                device.writeValue(data, for: chr, type: .withResponse)
            }
            return
        }
        
    }
    
    private func isAvaliable() -> Bool {
        guard let centralManager else {
            return false
        }
        return centralManager.state == .poweredOn
    }
    
    private func stateString() -> String {
        var state = "unknown"
        if centralManager == nil {
            return "unknown"
        }
        switch centralManager!.state {
        case .unknown:
            state = "unknown"
        case .poweredOn:
            state = "poweredOn"
            print("蓝牙已开启，开始扫描设备")
            // 开始扫描设备：centralManager.scanForPeripherals(...)
        case .unauthorized:
            state = "unauthorized"
            // 未授权，提示用户去设置
//            showPermissionAlert()
        case .poweredOff:
            state = "poweredOff"
            print("请打开蓝牙")
        case .unsupported:
            state = "unsupported"
            print("设备不支持蓝牙")
        case .resetting:
            state = "resetting"
        
        @unknown default:
            state = "unknown"
        }
        print(state)
        return state
    }
    
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let currCommand, currCommand.method == "openAdapter" {
            self.currCommand = nil
            var command = currCommand
            command.response = isAvaliable()
            replyShell(command)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.devices.removeAll(where: {$0.identifier == peripheral.identifier})
        self.devices.append(peripheral)
        
        if let currCommand, currCommand.method == "findNextDevice" {
            self.currCommand = nil
            var command = currCommand
            command.response = [peripheral.identifier.uuidString, peripheral.name ?? "", RSSI.intValue]
            replyShell(command)
        } else {
            noteReplyDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard var command = currCommand, command.method == "connectDevice" else {
            return
        }
        
        var uuid: String?
        if let params = command.params as? String {
            uuid = params
        } else if let params = command.params as? [Any] {
            uuid = params.first as? String
        }
        
        guard let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
            return
        }
        
        if device != peripheral {
            devices.remove(device)
            devices.append(peripheral)
        }
        
        self.currCommand = nil
        command.response = true
        replyShell(command)
        return
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard var command = currCommand, command.method == "connectDevice" else {
            return
        }
        
        var uuid: String?
        if let params = command.params as? String {
            uuid = params
        } else if let params = command.params as? [Any] {
            uuid = params.first as? String
        }
        
        guard let device = devices.first(where: {$0.identifier.uuidString == uuid}) else {
            return
        }
        
        self.currCommand = nil
        command.response = false
        if let error {
            command.error = error.localizedDescription
        }
        
        replyShell(command)
        return
    }

//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?)
//
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?)
//
//    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral)
//
//    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        guard var command = self.currCommand,
              command.method == "readDeviceRSSI",
              let uuid = command.params as? String,
              uuid == peripheral.identifier.uuidString else {
            return
        }
        
        self.currCommand = nil
        command.response = RSSI.intValue
        if let error {
            command.error = error.localizedDescription
        }
        replyShell(command)
        return
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard var command = self.currCommand,
                command.method == "getServices",
                let uuid = command.params as? String,
                uuid == peripheral.identifier.uuidString else {
            return
        }
        
        let sids = peripheral.services?.map({[$0.uuid.uuidString, $0.isPrimary]})
        command.response = sids
        if let error {
            command.error = error.localizedDescription
        }
        self.currCommand = nil
        replyShell(command)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard var command = self.currCommand,
              command.method == "getCharacteristics",
              let params = command.params as? [String],
                  let uuid = params.first,
                  let sid = params.last,
            peripheral.identifier.uuidString == uuid,
        service.uuid.uuidString == sid else {
            return
        }
        
        let chars = service.characteristics?.map({ item in
            [
                "uuid": item.uuid.uuidString,
                "properties": [
                    item.properties.contains(.broadcast),
                    item.properties.contains(.read),
                    item.properties.contains(.writeWithoutResponse),
                    item.properties.contains(.write),
                    item.properties.contains(.notify),
                    item.properties.contains(.indicate),
                    item.properties.contains(.authenticatedSignedWrites),
                    item.properties.contains(.notifyEncryptionRequired),
                    item.properties.contains(.indicateEncryptionRequired),
                ],
                "value": (item.value != nil ? item.value!.base64EncodedString() : NSNull()) as Any,
            ]
        })
        
        command.response = chars
        if let error {
            command.error = error.localizedDescription
        }
        self.currCommand = nil
        replyShell(command)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard var command = self.currCommand, command.method == "readValue",
              let params = command.params as? [String],
              characteristic.uuid.uuidString == params[2]  else {
            return
        }
        let response: Any = characteristic.value?.base64EncodedString() ?? NSNull()
        if let error {
            command.response = response
            command.error = error.localizedDescription
        } else {
            command.response = response
        }
        self.currCommand = nil
        replyShell(command)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard var command = self.currCommand, command.method == "writeValue",
              let params = command.params as? [String],
              characteristic.uuid.uuidString == params[2]  else {
            return
        }
        
        if let error {
            command.response = false
            command.error = error.localizedDescription
        } else {
            command.response = true
        }
        self.currCommand = nil
        replyShell(command)
    }
}


//private struct HeaderMessage: HandyJSON {
//    public init() {
//        
//    }
//    
//    public var parentId: String?
//    public var id: String?
//    public var type: String = ""
//}
//
//
//
//class BluetoothManager: NSObject, CBCentralManagerDelegate {
//    var centralManager: CBCentralManager!
//    var context: SwiftyZeroMQ.Context?
//    
//    private var publisherSocket: SwiftyZeroMQ.Socket?
//    private var subscriberSocket: SwiftyZeroMQ.Socket?
//    
//    var publisherQueue: DispatchQueue = DispatchQueue(label: "publisherQueue")
//    var subscriberQueue = DispatchQueue(label: "subscriberQueue")
//    
//    private var publisherIP = "tcp://*:5555"
//    private var subscriberIP = "tcp://127.0.0.1:5556"
//
//    override init() {
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//        setupZeroMQ()
//    }
//    
//    private func setupZeroMQ() {
//        do {
//            self.context = try SwiftyZeroMQ.Context()
//            self.publisherSocket = try context?.socket(.publish)
//            try self.publisherSocket?.bind(publisherIP)
//            self.subscriberSocket = try context?.socket(.subscribe)
//            try self.subscriberSocket?.connect(subscriberIP)
//            try self.subscriberSocket?.setSubscribe("")
//        } catch {
//            print("zeromq setup error: \(error)")
//        }
//        
//        subscriberQueue.async {
//            while (true) {
//                guard let frame = try? self.subscriberSocket?.recvMultipart() else {
//                    continue
//                }
//                let headerJson = String(data: frame[0], encoding: .utf8)
//                let header = HeaderMessage.deserialize(from: headerJson)
//                let commandJson = String(data: frame[1], encoding: .utf8)
//                let command = CommandMessage.deserialize(from: commandJson)
//                
//                if let command {
//                    self.handleCommand(command)
//                }
//            }
//        }
//    }
//    
//    private func sendCommand(header: HeaderMessage, command: CommandMessage) {
//        let headerJson = try? JSONSerialization.data(withJSONObject: header.toJSON(), options: [])
//        let commandJson = try? JSONSerialization.data(withJSONObject: command.toJSON())
//        publisherQueue.async {
//            try? self.publisherSocket?.sendMultipart(parts: [
//                headerJson!,
//                commandJson!
//            ])
//        }
//    }
//    
//    private func stateString() -> String {
//        var state = "unknown"
//        switch centralManager.state {
//        case .unknown:
//            state = "unknown"
//        case .poweredOn:
//            state = "poweredOn"
//            print("蓝牙已开启，开始扫描设备")
//            // 开始扫描设备：centralManager.scanForPeripherals(...)
//        case .unauthorized:
//            state = "unauthorized"
//            // 未授权，提示用户去设置
//            showPermissionAlert()
//        case .poweredOff:
//            state = "poweredOff"
//            print("请打开蓝牙")
//        case .unsupported:
//            state = "unsupported"
//            print("设备不支持蓝牙")
//        case .resetting:
//            state = "resetting"
//        
//        @unknown default:
//            state = "unknown"
//        }
//        print(state)
//        return state
//    }
//    
//    private func handleCommand(_ command: CommandMessage) {
//        if command.command == "startScan" {
//            self.centralManagerDidUpdateState(self.centralManager)
//            
//            var serviceUUIDs: [CBUUID]? = nil
//            var options: [String: Any]? = nil
//            if let args = command.args as? [String: Any] {
//                if let uuids = args["serviceUUIDs"] as? [String] {
//                    serviceUUIDs = uuids.map {CBUUID(string: $0)}
//                }
//                options = args["options"] as? [String: Any]
//            }
//            DispatchQueue.main.async {
//                self.centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
//            }
//        } else if command.command == "stopScan" {
//            DispatchQueue.main.async {
//                self.centralManager.stopScan()
//            }
//        }
//    }
//
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        let state = stateString()
//        
//        let header = try? JSONSerialization.data(withJSONObject: HeaderMessage().toJSON(), options: [])
//        var commandMsg = CommandMessage()
//        commandMsg.command = "didUpdateState"
//        commandMsg.args = state
//        let command = try? JSONSerialization.data(withJSONObject: commandMsg.toJSON())
//        publisherQueue.async {
//            try? self.publisherSocket?.sendMultipart(parts: [
//                header!,
//                command!
//            ])
//        }
//    }
//
//    private func showPermissionAlert() {
//        let alert = UIAlertController(
//            title: "需要蓝牙权限",
//            message: "请在设置中允许使用蓝牙",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
//            if let url = URL(string: UIApplication.openSettingsURLString) {
//                UIApplication.shared.open(url)
//            }
//        })
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
//        // 获取当前视图控制器并显示弹窗
//        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        
//    }
//}

import EventKit

class CalendarService: IDEService {
    func onInitialized() {
        ideServiceManager.registryCommandHandler(name: "addPhoneCalendar") { command in
            var command = command
            guard let title = command.params?["title"] as? String,
                  let startTime = command.params?["startTime"] as? Double else {
               
                command.error = "params error"
                ideServiceManager.replyShell(command)
                return
            }
                  
            let allDay = command.params?["allDay"] as? Bool ?? false
            let description = command.params?["description"] as? String
            let location = command.params?["location"] as? String
            let endTime = command.params?["endTime"] as? Double
            let alarm = command.params?["alarm"] as? Bool ?? true
            let alarmOffset = command.params?["alarmOffset"] as? Double ?? 0
            
            
            ideServiceManager.startCommand(command)
            Task {
                do {
                    let success = try await self.addPhoneCalendar(
                        title: title,
                        startTime: startTime,
                        allDay: allDay,
                        description: description,
                        location: location,
                        endTime: endTime,
                        alarm: alarm,
                        alarmOffset: alarmOffset
                    )
                    command.response = true
                } catch {
                    command.response = false
                    command.error = error.localizedDescription
                }
                ideServiceManager.endCommand(command)
            }
        }
        
        ideServiceManager.registryCommandHandler(name: "addPhoneRepeatCalendar") { command in
            var command = command
            guard let title = command.params?["title"] as? String,
                  let startTime = command.params?["startTime"] as? Double else {
               
                command.error = "params error"
                ideServiceManager.replyShell(command)
                return
            }
                  
            let allDay = command.params?["allDay"] as? Bool ?? false
            let description = command.params?["description"] as? String
            let location = command.params?["location"] as? String
            let endTime = command.params?["endTime"] as? Double
            let alarm = command.params?["alarm"] as? Bool ?? true
            let alarmOffset = command.params?["alarmOffset"] as? Double ?? 0
            let repeatInterval = command.params?["repeatInterval"] as? String ?? "month"
            let repeatEndTime = command.params?["repeatEndTime"] as? Double
            
            ideServiceManager.startCommand(command)
            Task {
                do {
                    let success = try await self.addPhoneRepeatCalendar(
                        title: title,
                        startTime: startTime,
                        allDay: allDay,
                        description: description,
                        location: location,
                        endTime: endTime,
                        alarm: alarm,
                        alarmOffset: alarmOffset,
                        repeatInterval: repeatInterval,
                        repeatEndTime: repeatEndTime
                    )
                    command.response = true
                } catch {
                    command.response = false
                    command.error = error.localizedDescription
                }
                ideServiceManager.endCommand(command)
            }
        }
    }

    func addPhoneCalendar(
        title: String,
        startTime: TimeInterval,
        allDay: Bool = false,
        description: String? = nil,
        location: String? = nil,
        endTime: TimeInterval? = nil,
        alarm: Bool = true,
        alarmOffset: TimeInterval = 0
    ) async throws -> Bool {
        // 1. 获取事件存储权限
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            // 请求权限
            let granted = try await eventStore.requestAccess(to: .event)
            guard granted else {
                throw CalendarError.permissionDenied
            }
        case .restricted, .denied:
            throw CalendarError.permissionDenied
        case .authorized:
            break
        @unknown default:
            break
        }
        
        // 2. 创建事件对象
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date(timeIntervalSince1970: startTime)
        
        // 处理结束时间
        let endDate = endTime != nil ? Date(timeIntervalSince1970: endTime!) : event.startDate
        event.endDate = allDay ? Calendar.current.date(byAdding: .day, value: 1, to: endDate!)! : endDate
        event.isAllDay = allDay
        
        // 可选属性
        if let description = description { event.notes = description }
        if let location = location { event.location = location }
        
        // 3. 处理提醒
        if alarm {
            let alarm = EKAlarm(relativeOffset: -alarmOffset) // 负数表示提前量
            event.addAlarm(alarm)
        }
        
        // 4. 保存到默认日历
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
        
        return true
    }
    
    func addPhoneRepeatCalendar(
        title: String,
        startTime: TimeInterval,
        allDay: Bool = false,
        description: String? = nil,
        location: String? = nil,
        endTime: TimeInterval? = nil,
        alarm: Bool = true,
        alarmOffset: TimeInterval = 0,
        repeatInterval: String = "month",
        repeatEndTime: TimeInterval? = nil
    ) async throws -> Bool {
        // 1. 获取事件存储权限
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            // 请求权限
            let granted = try await eventStore.requestAccess(to: .event)
            guard granted else {
                throw CalendarError.permissionDenied
            }
        case .restricted, .denied:
            throw CalendarError.permissionDenied
        case .authorized:
            break
        @unknown default:
            break
        }
        
        // 2. 创建事件对象
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = Date(timeIntervalSince1970: startTime)
        
        // 处理结束时间
        let endDate = endTime != nil ? Date(timeIntervalSince1970: endTime!) : event.startDate
        event.endDate = allDay ? Calendar.current.date(byAdding: .day, value: 1, to: endDate!)! : endDate
        event.isAllDay = allDay
        
        // 可选属性
        if let description = description { event.notes = description }
        if let location = location { event.location = location }
        
        // 3. 处理提醒
        if alarm {
            let alarm = EKAlarm(relativeOffset: -alarmOffset)
            event.addAlarm(alarm)
        }
        
        // 4. 处理重复规则
        let validIntervals = ["day", "week", "month", "year"]
        guard validIntervals.contains(repeatInterval) else {
            throw CalendarError.invalidRecurrence
        }
        
        // 检查每月重复的日期有效性
        if repeatInterval == "month" {
            let startDay = Calendar.current.component(.day, from: event.startDate)
            guard startDay <= 28 else {
                throw CalendarError.invalidDayForMonthlyRecurrence
            }
        }
        
        // 创建重复规则
        let frequency: EKRecurrenceFrequency = {
            switch repeatInterval {
            case "day": return .daily
            case "week": return .weekly
            case "month": return .monthly
            case "year": return .yearly
            default: fatalError("Already validated")
            }
        }()
        
        var recurrenceEnd: EKRecurrenceEnd? = nil
        if let repeatEndTime = repeatEndTime {
            recurrenceEnd = EKRecurrenceEnd(end: Date(timeIntervalSince1970: repeatEndTime))
        }
        
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: 1,
            end: recurrenceEnd
        )
        event.addRecurrenceRule(recurrenceRule)
        
        // 5. 保存到默认日历
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
        
        return true
    }

    // 扩展错误类型
    enum CalendarError: Error, LocalizedError {
        case permissionDenied
        case invalidCalendar
        case saveFailed
        case invalidRecurrence
        case invalidDayForMonthlyRecurrence
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Permission to access the calendar was denied."
            case .invalidCalendar:
                return "The specified calendar is invalid."
            case .saveFailed:
                return "Failed to save the calendar changes."
            case .invalidRecurrence:
                return "Invalid recurrence interval. Valid values are day/week/month/year."
            case .invalidDayForMonthlyRecurrence:
                return "Day of month for monthly recurrence cannot exceed 28."
            }
        }
    }

//    // 自定义错误类型
//    enum CalendarError: Error, LocalizedError {
//        case permissionDenied
//        case invalidCalendar
//        case saveFailed
//        
//        var errorDescription: String? {
//            switch self {
//            case .permissionDenied:
//                return "Permission to access the calendar was denied."
//            case .invalidCalendar:
//                return "The specified calendar is invalid."
//            case .saveFailed:
//                return "Failed to save the calendar changes."
//            }
//        }
//    }
}
