//
//  Copyright © 2022 Protonex LLC dba PNI Sensor. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program.
//  If not, see <https://www.gnu.org/licenses/>.
//

#if IOS_SIMULATOR

import Foundation
import CoreBluetooth
import os.log

// Make this `serial` since CoreBluetooth changes concurrent queues to that on real devices.
let fake_queue: DispatchQueue = DispatchQueue(label: "com.pnisensor.fake-ble-queue");

class Fake_PniCentralManager: PniCentralManager {
    private static let SCAN_DELAY: Double = 0.15;
    private static let CONNECT_DELAY: Double = 1;
    
    private var _isBleOn: Bool = false;
    private var _scanWorkItem: DispatchWorkItem?;
    private var _connectWorkItem: DispatchWorkItem?;
    private var _state: CBManagerState = .unknown;
    
    private var _isScanning = false;
    private var devicePeriphIdx = 0;
    
    private let latestLpom: UInt16 = 61;
    private let latestSulpom: UInt16 = 24;
    
    private lazy var devicePeripherals: [Fake_DevicePeripheral] = [
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestSulpom,
            serialNumber: 1000000111,
            firmwareTypeId: 7,
            protocolVersion: .R04,
            companyId: Device.COMPANY_ID,
            rssi: -23),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom - 2,
            serialNumber: 1009000222,
            firmwareTypeId: 1,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -54),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1009000332,
            firmwareTypeId: 5,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -47),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestSulpom - 1,
            serialNumber: 1000000101,
            firmwareTypeId: 7,
            protocolVersion: .R03,
            companyId: Device.COMPANY_ID,
            rssi: -24,
            battery: (level: 0, charging: true)),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: 1,
            serialNumber: 1009000333,
            firmwareTypeId: 6,
            protocolVersion: .R04,
            companyId: Device.COMPANY_ID,
            rssi: -88),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1009000334,
            firmwareTypeId: 0,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -87),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1000900526,
            firmwareTypeId: 8,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -75),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1000900999,
            firmwareTypeId: 0x80,
            protocolVersion: .R04,
            companyId: Device.COMPANY_ID,
            rssi: -31),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1000900528,
            firmwareTypeId: 8,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -53),
        Fake_DevicePeripheral(
            uuid: generateUuid(),
            centralManager: self,
            version: latestLpom,
            serialNumber: 1000000112,
            firmwareTypeId: 1,
            protocolVersion: .R02,
            companyId: Device.COMPANY_ID,
            rssi: -108),
    ]
    
    override public private(set) var state: CBManagerState {
        get { return _state }
        set { _state = newValue }
    }
    
    override init(delegate: PniCentralManagerDelegate?) {
        super.init(delegate: delegate);
        generalLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "FakeCentralManager");
        
        // Just assume BLE is ready sometime after initialization is done.
        os_log("State updated.", log: generalLogger, type: .debug);
        os_log("State: 'poweredOn'.", log: generalLogger, type: .debug);
        fake_queue.async { [weak self] in
            guard let self = self else { return }
            self.state = .poweredOn;
            self.delegate?.onStateUpdated(self, state: self.state);
        }
    }
    
    override func startScan(withServices: [String]?) {
        // Callback with fake peripherals.
        os_log("Scanning started.", log: generalLogger, type: .debug);
        
        generatePeripherals();
        let workItem: DispatchWorkItem = DispatchWorkItem { [weak self] in
            self?.scanLoop();
        }
        _scanWorkItem = workItem;
        _isScanning = true;
        fake_queue.asyncAfter(deadline: .now() + Self.SCAN_DELAY, execute: workItem);
    }
        
    override func connect(toPeripheral peripheral: PniPeripheral) {
        if let peripheral = peripheral as? Fake_DevicePeripheral, (!peripheral.allowReconnect && peripheral.didDisconnect) {
            return;
        }
        
        let workItem: DispatchWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            if let peripheral = peripheral as? Fake_DevicePeripheral {
                peripheral.connect();
            }
            os_log("🟢 Connected to: '%{public}s'.", log: self.generalLogger, type: .debug, peripheral.identifier.description);
            self.delegate?.onConnected(toPeripheral: peripheral);
        });
        
        _connectWorkItem = workItem;
        os_log("Connecting to: '%{public}s'.", log: generalLogger, type: .debug, peripheral.instance.identifier.description);
        fake_queue.asyncAfter(deadline: .now() + Self.CONNECT_DELAY, execute: workItem);
    }
    
    override func centralManagerDidUpdateState(_ central: CBCentralManager) { /* Eat */ }
    override func cancelConnection(toPeripheral peripheral: PniPeripheral) {
        _connectWorkItem?.cancel();
        _connectWorkItem = nil;
        os_log("Cancelling connection: '%{public}s'.", log: generalLogger, type: .debug, peripheral.instance.identifier.description);
        if let peripheral = peripheral as? Fake_DevicePeripheral, (peripheral.isConnected) {
            peripheral.disconnect(safeDisconnect: true);
        }
    }
    override func stopScan() {
        _scanWorkItem?.cancel();
        _scanWorkItem = nil;
        _isScanning = false;
        os_log("Scanning stopped.", log: generalLogger, type: .debug);
    }
    
    public func disconnected(from peripheral: PniPeripheral, safeDisconnect: Bool) {
        let error: NSError? = (safeDisconnect) ? nil : NSError(domain: "Fake BLE disconnect error", code: 9001, userInfo: nil)
        if let err = error as? CBError {
            os_log("🛑 Disconnected from: '%{public}s', error: '%{public}s' (%d).", log: generalLogger, type: .info, "\(peripheral.identifier.uuidString.prefix(8))", err.localizedDescription, err.errorCode);
        } else {
            os_log("🟢 Disconnected from: '%{public}s'.", log: generalLogger, type: .debug, "\(peripheral.identifier.uuidString.prefix(8))");
        }
        
        fake_queue.async { [weak self] in
            // This delegate passing an error object means that BLE was not safely disconnected.
            self?.delegate?.onDisconnected(fromPeripheral: peripheral, error: error);
        }
    }
    
    private func scanLoop() {
        if (!_isScanning) { return; }
        
        var isDone = false;
        var wasAdded = false;
        if (devicePeriphIdx < devicePeripherals.count) {
            let peripheral = devicePeripherals[devicePeriphIdx];
            if let instance = peripheral.instance as? Fake_CBPeripheral, (instance._state == .disconnected) {
                delegate?.onDiscovered(peripheral: peripheral, name: nil, manufacturerData: peripheral.manufacturerData, rssi: Float(peripheral.rssi));
                wasAdded = true;
            }
            devicePeriphIdx += 1;
        } else {
            isDone = true;
        }
        
        if (!isDone) {
            let workItem: DispatchWorkItem = DispatchWorkItem { [weak self] in
                self?.scanLoop();
            }
            _scanWorkItem = workItem;
            if (wasAdded) {
                fake_queue.asyncAfter(deadline: .now() + Self.SCAN_DELAY, execute: workItem);
            } else {
                fake_queue.async(execute: workItem);
            }
        }
    }
    
    // Don't keep around old instances of peripherals. Connecting to them more than once creates strange exceptions
    // when LogService is deinitialized.
    private func generatePeripherals() {
        devicePeriphIdx = 0;
        
        // "Recreate" the peripherals when scanned.
        var devicePeripheralsRecreate: [Fake_DevicePeripheral] = [];
        for peripheral in devicePeripherals {
            if (peripheral.isConnected) {
                devicePeripheralsRecreate.append(peripheral)
            } else {
                devicePeripheralsRecreate.append(Fake_DevicePeripheral(peripheral: peripheral))
            }
        }
        devicePeripherals = devicePeripheralsRecreate;
    }
    
    private var uuidCounter = 0;
    private func generateUuid() -> String {
        var uuid = String(format: "%02x", uuidCounter)
        uuidCounter += 1;
        
        while (uuid.count < 8) {
            uuid = "0" + uuid;
        }
        while (uuid.count < 32) {
            uuid.append("0")
        }
        uuid.insert("-", at: uuid.index(uuid.startIndex, offsetBy: 8))
        uuid.insert("-", at: uuid.index(uuid.startIndex, offsetBy: 13))
        uuid.insert("-", at: uuid.index(uuid.startIndex, offsetBy: 18))
        uuid.insert("-", at: uuid.index(uuid.startIndex, offsetBy: 23))
        while (uuid.count > 36) {
            uuid.removeLast()
        }
        return uuid;
    }
}

#endif // IOS_SIMULATOR
