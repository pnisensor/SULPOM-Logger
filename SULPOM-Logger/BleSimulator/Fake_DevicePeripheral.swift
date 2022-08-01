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

/// The point of this is to provide a mock implementation of a 'LPOM' device.
/// Use this to test app features when a physical device is not available.
class Fake_DevicePeripheral: PniPeripheral {
    private var _services: [Fake_CBService] = [];
    private var _isObserverSet = false;
    private let centralManager: Fake_PniCentralManager;
    private let uuids: PniUUIDs;
    let protocolVersion: PniUUIDs.ProtocalVersion;
    
    var uuid: String;
    var serialNumber: UInt32;
    var firmwareTypeId: UInt8;
    var firmwareType: Firmware.TypeId {
        get { Firmware.TypeId.from(type: firmwareTypeId) }
    }
    
    var companyId: UInt16;
    var simulateDisconnect = false;
    var timeToWaitForDisconnect: Double = 10;
    var allowReconnect = false;
    private(set) var didDisconnect = false;
    var version: UInt16;
    var initialRssi: Int
    var rssi: Int;
    
    lazy var logService = FakeLogService(fakePeripheral: self, uuids: uuids.log);
    lazy var factoryService = FakeFactoryService(fakePeripheral: self, uuids: uuids.factory);
    
    init(uuid: String, centralManager: Fake_PniCentralManager, version: UInt16, serialNumber: UInt32,
         firmwareTypeId: UInt8, protocolVersion: PniUUIDs.ProtocalVersion, companyId: UInt16, rssi: Int,
         battery: (level: Int32, charging: Bool)? = nil) {
        self.uuid = uuid;
        self.centralManager = centralManager;
        self.version = version;
        self.serialNumber = serialNumber;
        self.firmwareTypeId = firmwareTypeId;
        self.protocolVersion = protocolVersion;
        self.uuids = PniUUIDs(version: protocolVersion);
        self.companyId = companyId;
        self.rssi = rssi;
        self.initialRssi = rssi;
        
        let peripheral: CBPeripheral = Fake_CBPeripheral.createInstance(uuid) as! Fake_CBPeripheral;
        super.init(peripheral: peripheral);
        generalLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "FakeDevicePeripheral(\(identifier))");
        
        // Create fake services and characteristics!
        let logSvc: Fake_CBService = Fake_CBService.createInstance(logService.SERVICE_UUID.uuidString) as! Fake_CBService;
        var chars = [
            Fake_CBCharacteristic.createInstance(uuids.log.char.uuidString) as! Fake_CBCharacteristic,
        ];
        logSvc._characteristics = chars;
        for ele in chars {
            ele._service = logSvc;
        }
        _services.append(logSvc);
        
        let factorySvc: Fake_CBService = Fake_CBService.createInstance(factoryService.SERVICE_UUID.uuidString) as! Fake_CBService;
        chars = [
            Fake_CBCharacteristic.createInstance(factoryService.CHAR_UUID.uuidString) as! Fake_CBCharacteristic,
        ];
        factorySvc._characteristics = chars;
        for ele in chars {
            ele._service = factorySvc;
        }
        _services.append(factorySvc);
        
        if let battery = battery {
            factoryService.batteryLevel = battery.level;
            factoryService.isCharging = battery.charging;
        }
    }
    
    init(peripheral other: Fake_DevicePeripheral) {
        self.uuid = other.uuid;
        self.centralManager = other.centralManager;
        self.version = other.version;
        self.serialNumber = other.serialNumber;
        self.firmwareTypeId = other.firmwareTypeId;
        self.protocolVersion = other.protocolVersion;
        self.uuids = PniUUIDs(version: protocolVersion);
        self.companyId = other.companyId;
        self.rssi = other.rssi;
        self.initialRssi = other.initialRssi;
        
        let peripheral: CBPeripheral = other.instance;
        super.init(peripheral: peripheral);
        generalLogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "FakeDevicePeripheral(\(identifier))");
        
        // Create fake services and characteristics!
        let logSvc: Fake_CBService = Fake_CBService.createInstance(logService.SERVICE_UUID.uuidString) as! Fake_CBService;
        var chars = [
            Fake_CBCharacteristic.createInstance(uuids.log.char.uuidString) as! Fake_CBCharacteristic,
        ];
        logSvc._characteristics = chars;
        for ele in chars {
            ele._service = logSvc;
        }
        _services.append(logSvc);
        
        let factorySvc: Fake_CBService = Fake_CBService.createInstance(factoryService.SERVICE_UUID.uuidString) as! Fake_CBService;
        chars = [
            Fake_CBCharacteristic.createInstance(factoryService.CHAR_UUID.uuidString) as! Fake_CBCharacteristic,
        ];
        factorySvc._characteristics = chars;
        for ele in chars {
            ele._service = factorySvc;
        }
        _services.append(factorySvc);
        
        other.logService.takeOwnership(fakePeripheral: self);
        other.factoryService.takeOwnership(fakePeripheral: self);
        self.logService = other.logService;
        self.factoryService = other.factoryService;
    }
    
    var manufacturerData: [UInt8] {
        get {
            var bytes = companyId.bytes + version.bytes + serialNumber.bytes + [firmwareTypeId];
            if (protocolVersion == .R02) {
                bytes.append(2);
            } else if (protocolVersion == .R03 || protocolVersion == .R04) {
                bytes.append(3);
            }
            return bytes;
        }
    }
    
    public func connect() {
        if let peripheral: Fake_CBPeripheral = instance as? Fake_CBPeripheral {
            peripheral._state = .connected;
            
            if (simulateDisconnect) {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeToWaitForDisconnect) { [weak self] in
                    self?.disconnect(safeDisconnect: false);
                }
            }
        }
    }
    
    public func disconnect(safeDisconnect: Bool) {
        didDisconnect = true;
        if let peripheral: Fake_CBPeripheral = instance as? Fake_CBPeripheral {
            peripheral._state = .disconnected;
        }
        centralManager.disconnected(from: self, safeDisconnect: safeDisconnect);
    }
    
    public func getChar(uuid: CBUUID) -> Fake_CBCharacteristic? {
        for service: Fake_CBService in _services {
            if let characteristics: [Fake_CBCharacteristic] = service.characteristics as? [Fake_CBCharacteristic] {
                for characteristic: Fake_CBCharacteristic in characteristics {
                    if (uuid == characteristic.uuid) {
                        return characteristic;
                    }
                }
            }
        }
        return nil;
    }
    
    public func sendResponse(_ characteristic: Fake_CBCharacteristic, bytes: [UInt8]) {
        fake_queue.async { [weak self] in
            self?.sendResponseUnqueued(characteristic, bytes: bytes);
        }
    }
    
    public func sendResponse(_ characteristic: Fake_CBCharacteristic, bytes: [UInt8], delay: Double) {
        fake_queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.sendResponseUnqueued(characteristic, bytes: bytes);
        }
    }
    
    public func sendResponseUnqueued(_ characteristic: Fake_CBCharacteristic, bytes: [UInt8]) {
        characteristic._value = Data(bytes);
        
        guard let service = characteristic.service else { return }
        if let registeredService = registeredServices[service.uuid] {
            registeredService.handleData(fromCharacteristic: characteristic, bytes: bytes)
        } else {
            print("Unknown service '\(service.uuid)' sending data: \(bytes)");
        }
    }
    
    override func readRSSI() {
        guard (isConnected) else { return }

        fake_queue.async { [weak self] in
            guard let self = self else { return }
            self.rssi = self.initialRssi + Int.random(in: -8 ..< 8)
            self.delegate?.onReadRSSI(rssi: Float(self.rssi));
        }
    }
    
    override func discoverServices(uuids: [CBUUID]?) {
        guard (isConnected) else {
            print("\(Self.self) -> Trying to discover services on non connected peripheral.");
            return;
        }
        
        var bleServices: [Fake_CBService] = [];
        if let uuids = uuids {
            for uuid: CBUUID in uuids {
                for service: Fake_CBService in _services {
                    if (uuid == service.uuid) {
                        bleServices.append(service);
                    }
                }
            }
        } else {
            bleServices = _services; // Discover everything.
        }

        fake_queue.async { [weak self] in
            guard let self = self else { return }

            for service in bleServices {
                if let registeredService = self.registeredServices[service.uuid] {
                    registeredService.handleServiceDiscovered(service: service)
                } else {
                    print("Unknown service discovered: ", service.uuid);
                }
            }
        }
    }
    
    override func discoverCharacteristics(uuids: [CBUUID]?, service: CBService) {
        guard (isConnected) else {
            print("\(Self.self) -> Trying to discover characteristics on non connected peripheral.");
            return;
        }
        
        for svc: Fake_CBService in _services {
            guard let service: Fake_CBService = service as? Fake_CBService, (svc.uuid == service.uuid) else {
                continue;
            }
            
            var characteristics: [CBCharacteristic] = [];
            if let uuids = uuids {
                // Filter out unwanted characteristics
                if let chars = service.characteristics {
                    for char in chars {
                        for uuid: CBUUID in uuids {
                            if (uuid == char.uuid) {
                                characteristics.append(char);
                            }
                        }
                    }
                }
                service._characteristics = characteristics;
            } else {
                characteristics = service.characteristics ?? []
            }
            
            fake_queue.async { [weak self] in
                guard let self = self else { return }
                if let registeredService = self.registeredServices[service.uuid] {
                    registeredService.handleCharacteristicsDiscovered(characteristics: characteristics)
                } else {
                    print("Characteristics discovered for unnown service: ", service.uuid);
                }
            }
            break;
        }
    }
    
    override func setNotifyValue(isEnabled: Bool, characteristic: CBCharacteristic) {
        guard (isConnected) else {
            print("\(Self.self) -> Trying to change notify value on non connected peripheral.");
            return;
        }
        
        if let characteristic: Fake_CBCharacteristic = characteristic as? Fake_CBCharacteristic {
            characteristic._isNotifying = isEnabled;
            fake_queue.async { [weak self] in
                guard let self = self, let service = characteristic.service else { return }
                if let registeredService = self.registeredServices[service.uuid] {
                    registeredService.handleSetNotifyValue(forCharacteristic: characteristic)
                } else {
                    print("Notify value updated for unknown service: ", service.uuid);
                }
            }
            
            switch (characteristic.uuid) {
            case logService.CHAR_UUID:
                logService.handleNotifyValue(isEnabled: isEnabled, characteristic: characteristic);
            case factoryService.CHAR_UUID:
                factoryService.handleNotifyValue(isEnabled: isEnabled, characteristic: characteristic);
            default:
                print("\(Self.self) -> Unhandled set notification on: ", characteristic, isEnabled);
            }
        }
    }
    
    override func writeValue(characteristic: CBCharacteristic, value: [UInt8], type: CBCharacteristicWriteType) {
        guard (isConnected) else {
            print("\(Self.self) -> Trying to write to non connected peripheral.");
            return;
        }
        
        guard let characteristic: Fake_CBCharacteristic = characteristic as? Fake_CBCharacteristic else {
            return;
        }
        
        switch (characteristic.uuid) {
        case logService.CHAR_UUID:
            logService.handleWrite(characteristic: characteristic, value: value, type: type);
        case factoryService.CHAR_UUID:
            factoryService.handleWrite(characteristic: characteristic, value: value, type: type);
        default:
            print("\(Self.self) -> Unhandled write on: ", characteristic, value, type);
        }
    }

    override func readValue(for characteristic: CBCharacteristic) {
        guard (isConnected) else {
            print("\(Self.self) -> Trying to read value on non connected peripheral.");
            return;
        }
        
        guard let characteristic: Fake_CBCharacteristic = characteristic as? Fake_CBCharacteristic else {
            return;
        }
        
        switch (characteristic.uuid) {
        case logService.CHAR_UUID:
            logService.handleRead(characteristic: characteristic);
        default:
            print("\(Self.self) -> Unhandled read on: ", characteristic);
        }
    }
}

#endif // IOS_SIMULATOR
