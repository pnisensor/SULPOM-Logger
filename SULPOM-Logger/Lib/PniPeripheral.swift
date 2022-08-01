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

protocol PniPeripheralDelegate: AnyObject {
    /// Contains a peripheral specific error.
    /// - Parameter error: Error object.
    func onError(error: Error, type: PniPeripheral.ErrorType);
    
    /// Provides the latest RSSI reading.
    /// * Callback of either `readRSSI` or `startReadingRSSI`.
    /// - Parameter rssi: Latest RSSI reading.
    func onReadRSSI(rssi: Float);
}

/// Nice wrapper for interacting with a connected Bluetooth device.
class PniPeripheral: NSObject, CBPeripheralDelegate {
    enum ErrorType {
        case READ_RSSI;
        case DISCOVER_SERVICES;
        case DISCOVER_CHARACTERISTICS;
        case UPDATE_NOTIFICATION_STATE;
        case UPDATE_VALUE;
    }
    
    
    // MARK: Member Variables
    
    private let peripheral: CBPeripheral;

    /// Object that will recieve delegate notifications from the module.
    public weak var delegate: PniPeripheralDelegate?;

    /// Checks to see if the devie is still connected. If so return true, else return false.
    public var isConnected: Bool {
        get { peripheral.state == .connected }
    }
    
    /// The unique identifier of the peripheral.
    public var identifier: UUID {
        get { peripheral.identifier }
    }
    
    /// Get the underlying peripheral instance.
    public var instance: CBPeripheral {
        get { peripheral }
    }

    private var isReadingRSSI: Bool = false;
    
    lazy var generalLogger = OSLog("Peripheral(\("\(identifier.uuidString.prefix(8))"))");
    
    private(set) var registeredServices: [CBUUID: IPniService] = [:]
    
    // MARK: Methods

    
    /// Initialize the wrapper.
    /// - Parameter peripheral: CoreBluetooth peripheral to wrap.
    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral;
        super.init();
        
        self.peripheral.delegate = self;
    }
    
    deinit {
        isReadingRSSI = false;
    }
    
    /// Register a service to receive updates. Services are responsible for handling
    /// BLE CBService and CBCharacteristic notifications.
    /// - Parameter service: The service to register.
    func register(service: IPniService) {
        registeredServices[service.uuid] = service;
    }
    
    /// Clears all registered services. Services will need to be re-registered
    /// if they are needed.
    func clearServices() {
        registeredServices = [:]
    }

    /// Get the current RSSI reading.
    /// * The result of this will callback `onReadRSSI`.
    public func readRSSI() {
        guard (isConnected) else {
            print("Trying to read rssi on non connected peripheral.");
            return;
        }
        
        peripheral.readRSSI();
    }
    
    /// Calling this will have the module poll for the rssi at the given time interval.
    /// This doesn't do anything if the module is already polling.
    /// * The results of this will callback `onReadRSSI`.
    /// - Parameter interval: Time interval in seconds to poll for the rssi at.
    public func startReadingRSSI(interval: Double) {
        guard (isConnected) else {
            print("Trying to read rssi on non connected peripheral.");
            return;
        }
        
        if (!isReadingRSSI) {
            isReadingRSSI = true;
            readiRssiContinuously(interval: interval);
        }
    }
    
    /// Calling this will tell the module to stop polling for rssi value.
    public func stopReadingRssi() {
        isReadingRSSI = false;
    }

    /// Discover the services that the device supports.
    /// * The result of this will callback `onDiscoverServices`.
    /// - Parameter uuids: The uuids of services to discover. Pass nil to find all services.
    public func discoverServices(uuids: [CBUUID]?) {
        guard (isConnected) else {
            print("Trying to discover services on non connected peripheral.");
            return;
        }
        
        peripheral.discoverServices(uuids);
    }

    /// Discover the characteristics that the service supports.
    /// * The result of this will callback `onDiscoverCharacteristics`.
    /// - Parameter uuids: The uuids of characteristics to discover. Pass nil to find all characteristics.
    /// - Parameter service: Service to discover characteristics for.
    public func discoverCharacteristics(uuids: [CBUUID]?, service: CBService) {
        guard (isConnected) else {
            print("Trying to discover characteristics on non connected peripheral.");
            return;
        }
        
        peripheral.discoverCharacteristics(uuids, for: service);
    }

    /// Either enable or disable notifications on the given characteristic.
    /// * The result of this will callback `onSetNotifyValue`.
    /// * Actual notificationos will be delivered to `onData`.
    /// - Parameter isEnabled: Should notifications be enabled or disabled?
    /// - Parameter characteristic: The characteristic to change the notify value of.
    public func setNotifyValue(isEnabled: Bool, characteristic: CBCharacteristic) {
        guard (isConnected) else {
            print("Trying to change notify value on non connected peripheral.");
            return;
        }
        peripheral.setNotifyValue(isEnabled, for: characteristic);
    }

    /// Given an array of bytes, this will write that array to the characteristic.
    /// * The result of this might callback `onData` if notifications are enabled.
    /// - Parameters:
    ///   - characteristic: The characteristic to be written to.
    ///   - value: Array of bytes to write.
    ///   - type: The type of write to make.
    public func writeValue(characteristic: CBCharacteristic, value: [UInt8], type: CBCharacteristicWriteType) {
        guard (isConnected) else {
            print("Trying to write to non connected peripheral.");
            return;
        }
        peripheral.writeValue(Data(value), for: characteristic, type: type);
    }
    
    /// Request to read the value from the given characteristic.
    /// * The result of this will callback `onData`.
    /// - Parameter characteristic: Characterist to read data from.
    public func readValue(for characteristic: CBCharacteristic) {
        guard (isConnected) else {
            print("Trying to read value on non connected peripheral.");
            return;
        }
        
        peripheral.readValue(for: characteristic);
    }
    
    /// Read the RSSI value each time `interval` seconds pass.
    /// - Parameter interval: Number of seconds to wait.
    private func readiRssiContinuously(interval: Double) {
        if (isReadingRSSI && isConnected) {
            readRSSI();
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + interval) { [weak self] in
                self?.readiRssiContinuously(interval: interval);
            };
        }
    }
    

    // MARK: CBPeripheralDelegate


    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error: Error = error {
            print("🛑 Error reading RSSI: \(error.localizedDescription)");
            delegate?.onError(error: error, type: .READ_RSSI);
            return;
        }
        delegate?.onReadRSSI(rssi: Float(truncating: RSSI));
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error: Error = error {
            os_log("🛑 Failed to discover services: '%{public}s'.", log: generalLogger, type: .error, error.localizedDescription);
            delegate?.onError(error: error, type: .DISCOVER_SERVICES);
            return;
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            if let registeredService = registeredServices[service.uuid] {
                registeredService.handleServiceDiscovered(service: service)
            } else {
                print("Unknown service discovered: ", service.uuid);
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error: Error = error {
            os_log("🛑 Failed to discover characteristics for service '%{public}s': '%{public}s'.", log: generalLogger,
                   type: .error, service.uuid.description, error.localizedDescription);
            delegate?.onError(error: error, type: .DISCOVER_CHARACTERISTICS);
            return;
        }
        
        guard let characteristics = service.characteristics else { return }
        if let registeredService = registeredServices[service.uuid] {
            registeredService.handleCharacteristicsDiscovered(characteristics: characteristics)
        } else {
            print("Characteristics discovered for unnown service: ", service.uuid);
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error: Error = error {
            os_log("🛑 Failed to update notification state for characteristic '%{public}s': '%{public}s'.", log: generalLogger,
                   type: .error, characteristic.uuid.description, error.localizedDescription);
            delegate?.onError(error: error, type: .UPDATE_NOTIFICATION_STATE);
            return;
        }
        
        guard let service = characteristic.service else { return }
        if let registeredService = registeredServices[service.uuid] {
            registeredService.handleSetNotifyValue(forCharacteristic: characteristic)
        } else {
            print("Notify value updated for unknown service: ", service.uuid);
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error: Error = error {
            os_log("🛑 Failed to update value for characteristic '%{public}s': '%{public}s'.", log: generalLogger,
                   type: .error, characteristic.uuid.description, error.localizedDescription);
            delegate?.onError(error: error, type: .UPDATE_VALUE);
            return;
        }
        
        guard let service = characteristic.service else { return }
        let bytes: [UInt8] = characteristic.value?.bytes ?? [];
        if let registeredService = registeredServices[service.uuid] {
            registeredService.handleData(fromCharacteristic: characteristic, bytes: bytes)
        } else {
            print("Unknown service '\(service.uuid)' sending data: \(bytes)");
        }
    }
}
