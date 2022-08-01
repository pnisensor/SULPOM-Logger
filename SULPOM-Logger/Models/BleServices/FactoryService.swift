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

import Foundation
import CoreBluetooth;
import os.log

class FactoryService: IPniService {
    // MARK: Constants
    public let uuid: CBUUID;
    private let TERMINAL_UUID: CBUUID;
    
    // Commands
    enum Commands {
        static let GET_BATTERY_INFO: UInt8          = 147;
        static let GET_BATTERY_INFO_RESP: UInt8     = 148;
    }
    
    enum BatteryInfoIds {
        static let CAPACITY_PERCENT: UInt8          = 46;
    }
    
    // MARK: Member Variables
    
    private var isServiceReady: Bool = false;
    public weak var delegate: FactoryServiceDelegate?;
    
    private let peripheral: PniPeripheral;
    private var terminalChar: CBCharacteristic?;
    private var isStartingUp: Bool = false; // Has the CBService been discovered since start was called?
    
    /// The frequency (in seconds) to receive battery updates.
    /// NOTE: The SULPOM sensor uses this as a keep alive packet and will timeout if
    /// 60 seconds passes with inactivity.
    public var readBatteryInterval: Double = {
        #if IOS_SIMULATOR
        return 1;
        #else
        return 20;
        #endif
    }()
    private var batteryLevelWorkItem: DispatchWorkItem?;
    private var willReadBattery = false;
    
    /// The most recent battery reading.
    public var lastBatteryLevel: Int = -1;
    private let isSulpom: Bool
    
    private lazy var logger = OSLog("FactorySvc(\("\(peripheral.identifier.uuidString.prefix(8))"))");
    
    
    // MARK: Methods
    
    
    init(_ peripheral: PniPeripheral, uuids: PniUUIDs.Factory, firmware: Firmware) {
        self.peripheral = peripheral;
        uuid = uuids.svc;
        TERMINAL_UUID = uuids.char;
        isSulpom = firmware.typeId.isSulpom()
    }
    
    deinit {
        stop();
        print("\(Self.self) dtr.");
    }
    
    /// Start the service up.
    public func start() {
        if (isServiceReady), let characteristic: CBCharacteristic = terminalChar {
            if (!characteristic.isNotifying) {
                updateNotifyValue(characteristic, enabled: true)
            } else {
                didStart();
            }
        } else {
            isStartingUp = true;
            peripheral.discoverServices(uuids: [uuid]);
        }
    }
    
    /// Stop the service.
    public func stop() {
        isServiceReady = false;
        stopReadingBatteryLevel();
        
        if let characteristic: CBCharacteristic = terminalChar {
            updateNotifyValue(characteristic, enabled: false)
        }
    }
    private func didStart() {
        delegate?.onStart(service: self);
        
        if (readBatteryInterval > 0) {
            startGettingBatteryLevel(interval: readBatteryInterval);
        }
    }
        
    /// Read the SULPOM's current battery capacity percentage once every `interval` seconds.
    /// This will only work for SULPOM firmware.
    public func startGettingBatteryLevel(interval: Double) {
        if (isSulpom && batteryLevelWorkItem == nil) {
            willReadBattery = true;
            getBatteryLevelContinuously(interval: interval);
        }
    }
    
    /// Stop reading the battery level.
    public func stopReadingBatteryLevel() {
        batteryLevelWorkItem?.cancel();
        batteryLevelWorkItem = nil;
        willReadBattery = false;
    }
    
    /// Unwrap the characteristic, then send the write request.
    /// - Parameter bytes: Bytes to write.
    private func sendCommand(bytes: [UInt8]) {
        guard let terminalChar: CBCharacteristic = terminalChar else {
            return;
        }
        #if DEBUG
        os_log(">> %s", log: logger, type: .debug, "\(bytes)");
        #endif
        
        peripheral.writeValue(characteristic: terminalChar, value: bytes, type: .withResponse);
    }
    
    private func updateNotifyValue(_ characteristic: CBCharacteristic, enabled: Bool) {
        os_log("Setting Notification state to '%@'.", log: logger, type: .debug, String(enabled));
        peripheral.setNotifyValue(isEnabled: enabled, characteristic: characteristic);
    }
    
    private func getBatteryLevel() {
        sendCommand(bytes: [Commands.GET_BATTERY_INFO, BatteryInfoIds.CAPACITY_PERCENT]);
    }
    
    private func getBatteryLevelContinuously(interval: Double) {
        guard (willReadBattery) else { return }
        getBatteryLevel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.getBatteryLevelContinuously(interval: interval);
        }
        batteryLevelWorkItem = workItem;
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + interval, execute: workItem);
    }
    
    
    // MARK: Peripheral handlers
    
    
    func handleData(fromCharacteristic characteristic: CBCharacteristic, bytes: [UInt8]) {
        if (characteristic.uuid == TERMINAL_UUID) {
            #if DEBUG
            os_log("<< %s", log: logger, type: .debug, "\(bytes)");
            #endif
            guard (!bytes.isEmpty) else { return }
            
            // Decode the response and call the appropriate delegate with the result.
            // Improperly formatted responses, i.e. invalid length, will be lost.
            let command: UInt8 = bytes[0];
            switch (command) {
            case Commands.GET_BATTERY_INFO_RESP:
                guard (bytes.count == 6) else { return }
                let batteryInfoId = bytes[1];
                switch (batteryInfoId) {
                case BatteryInfoIds.CAPACITY_PERCENT:
                    lastBatteryLevel = Int(bytes.getInt32(2))
                    delegate?.onGetBatteryLevel(percent: lastBatteryLevel);
                default:
                    print("Unknown get BatteryInfo id: '\(batteryInfoId)'.");
                }
            default:
                print("Unknown factory command: '\(command)'.");
            }
        }
    }
    
    func handleServiceDiscovered(service: CBService) {
        if (isStartingUp && service.uuid == uuid) {
            isStartingUp = false;
            peripheral.discoverCharacteristics(uuids: [TERMINAL_UUID], service: service);
        }
    }
    
    func handleCharacteristicsDiscovered(characteristics: [CBCharacteristic]) {
        for characteristic: CBCharacteristic in characteristics {
            // Save characteristics.
            if (characteristic.uuid == TERMINAL_UUID) {
                terminalChar = characteristic;
                updateNotifyValue(characteristic, enabled: true)
            }
        }
    }
    
    func handleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic) {
        os_log("Notification state set to '%@'.", log: logger, type: .debug,
               String(characteristic.isNotifying));
        if (characteristic.uuid == TERMINAL_UUID && characteristic.isNotifying) {
            // Service is ready!
            isServiceReady = true;
            didStart();
        }
    }
}
