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

protocol DeviceDelegate: AnyObject {
    /// Called when a peripheral specific error occurs.
    /// - Parameters:
    ///   - error: The raw error object.
    ///   - type: The type of error.
    func onError(_ device: Device, error: Error, type: PniPeripheral.ErrorType);
    
    /// Called when a new RSSI reading is available.
    /// - Parameters:
    ///   - rssi: New RSSI reading.
    func onReadRSSI(_ device: Device, rssi: Float);
    
    /// Called when the BLE connection was lost and is attempting to be reconnected.
    func onReconnecting(_ device: Device);
    
    /// Called when the lost BLE connection has been successfully reconnected.
    func onReconnected(_ device: Device);
    
    /// Called when the app has disconnected from the sensor and won't reconnect.
    /// This won't be called if the user first issues a disconnect.
    func onDisconnected(_ device: Device);
    
    /// Called when a new battery reading is available. This is only available on `SULPOM` devices.
    /// - Parameters:
    ///   - percent: The updated battery percentage.
    func onGetBatteryLevel(_ device: Device, percent: Int)
}

// Optional methods.
extension DeviceDelegate {
    func onGetBatteryLevel(_ device: Device, percent: Int) { }
}

/// Container used to hold a peripheral with its parsed manufacterer data.
/// The peripheral shold belong to either a `SULPOM` or `LPOM` sensor.
class Device: PniPeripheralDelegate, FactoryServiceDelegate {
    // MARK: Constants
    
    /// PNI Sensor's BLE company Id.
    static let COMPANY_ID: UInt16 = 0x04A1;
    
    /// Number of seconds to wait for the device to successfully reconnect.
    private static let RECONNECT_TIMEOUT: Double = 60 * 10;
    
    /// The connection state of the device.
    enum State {
        /// The device is connected.
        case CONNECTED;
        /// The device is disconnected.
        case DISCONNECTED;
        /// The device is attempting to reconnect.
        case RECONNECTING;
    }
    
    
    // MARK: Member variables

    /// Device instance which can be connected to.
    private(set) var peripheral: PniPeripheral;
    
    /// The manufacturer data of the device.
    public let data: [UInt8];
    
    /// The company id of the device. This comes from the manufacturer data.
    public let companyId: UInt16;
    
    /// The id of the device. This comes from the manufacturer data.
    public let id: String;
    
    /// Contains various firmare information. This comes from the manufacturer data.
    public let firmware: Firmware
    
    /// The central manager instance that created the peripheral.
    private let centralManager: PniCentralManager;
    private var reconnectTimeout: DispatchWorkItem?;
    var isConnecting = false;
    
    let uuids: PniUUIDs;
    
    public weak var delegate: DeviceDelegate?;
    
    /// If true, then the device will attempt to auto-reconnect to the peripheral if connection is lost.
    public var willTryToReconnect: Bool = true;
    
    /// Last read RSSI value.
    private(set) var rssi: Float;
    
    /// The current device connection state.
    private(set) var state: State;
    
    // BLE services.
    private(set) lazy var logService = LogService(device: self);
    private(set) lazy var factoryService = FactoryService(peripheral, uuids: uuids.factory, firmware: firmware);
    
    
    // MARK: Methods
    
    
    public init(peripheral: PniPeripheral, centralManager: PniCentralManager, rssi: Float, manufacturerData data: [UInt8]) {
        self.peripheral = peripheral;
        self.centralManager = centralManager;
        self.rssi = rssi;
        self.data = data;
        
        let version: UInt16
        if (data.count >= 6) {
            companyId = data.getUInt16(0);
            version = data.getUInt16(2);
            
            if (data.count >= 8) {
                id = "\(data.getUInt32(4))";
            } else {
                id = "Unknown";
            }
        } else {
            version = 0;
            companyId = 0;
            id = "Unknown";
        }
        
        let typeId: Firmware.TypeId
        if (data.count >= 9) {
            typeId = Firmware.TypeId.from(type: data[8]);
        } else {
            typeId = .UNKNOWN;
        }
        self.firmware = Firmware(typeId: typeId, version: version)
        
        if (data.count == 9) {
            uuids = PniUUIDs(version: .R01);
        } else if (data.count > 9) {
            let protocolVersion: PniUUIDs.ProtocalVersion
            switch (data[9]) {
            case 3:
                protocolVersion = .R03
            case 4:
                protocolVersion = .R04
            default:
                protocolVersion = .R02
            }
            uuids = PniUUIDs(version: protocolVersion);
        } else {
            uuids = PniUUIDs(version: .R01);
        }
        
        if (peripheral.isConnected) {
            state = .CONNECTED;
        } else {
            state = .DISCONNECTED;
        }
        peripheral.delegate = self;
    }
    
    /// Startup the device.
    public func start() {
        peripheral.startReadingRSSI(interval: 1);
        
        peripheral.register(service: logService)
        peripheral.register(service: factoryService)
        
        factoryService.delegate = self;
        factoryService.start(); // Start ASAP for battery readings.
    }
    
    /// Stops the device.
    public func stop() {
        peripheral.stopReadingRssi();
        factoryService.stopReadingBatteryLevel();
        peripheral.clearServices();
    }
    
    /// Attempt to disconnect from BLE.
    public func disconnect() {
        if (state != .DISCONNECTED) {
            state = .DISCONNECTED;
            
            reconnectTimeout?.cancel();
            reconnectTimeout = nil;
            willTryToReconnect = false;
            stop();

            print("Disconnecting...");
            centralManager.cancelConnection(toPeripheral: peripheral);
        }
    }
    
    /// Attempt to cancel the device reconnection process.
    public func cancelReconnection() {
        state = .DISCONNECTED;
        centralManager.cancelConnection(toPeripheral: peripheral);
        reconnectTimeout?.cancel();
        reconnectTimeout = nil;
        delegate?.onDisconnected(self);
    }
    

    // MARK: PniPeripheralDelegate
    
    
    func onError(error: Error, type: PniPeripheral.ErrorType) {
        delegate?.onError(self, error: error, type: type);
    }
    
    func onReadRSSI(rssi: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.rssi = rssi;
        }
        
        delegate?.onReadRSSI(self, rssi: rssi);
    }
    
    // MARK: FactoryServiceDelegate
    
    func onStart(service: FactoryService) {
        print("Factory service started");
    }
    
    func onGetBatteryLevel(percent: Int) {
        delegate?.onGetBatteryLevel(self, percent: percent)
    }
    
    
    // MARK: PniCentralManagerDelegate
    // NOTE: This currentlly doesn't receive direct updates from PniCentralManagerDelegate. Other delegates are
    // responsible for routing calls to these methods.
    

    func onStateUpdated(_ centralManager: PniCentralManager, state: CBManagerState) {
        if (state == .poweredOff) {
            self.state = .DISCONNECTED;
            reconnectTimeout?.cancel();
            reconnectTimeout = nil;
            stop();
            delegate?.onDisconnected(self);
        }
    }
    
    func onDiscovered(peripheral: PniPeripheral, name: String?, manufacturerData: [UInt8]?, rssi: Float) { }
    
    func onConnected(toPeripheral peripheral: PniPeripheral) {
        guard (peripheral.identifier == self.peripheral.identifier) else { return }
        reconnectTimeout?.cancel();
        reconnectTimeout = nil;
        
        print("Reconnected to device: ", peripheral.identifier);
        state = .CONNECTED;
        
        // The old peripheral is dead and has no services, so over write it.
        self.peripheral = peripheral;
        peripheral.delegate = self;
        
        start();
        delegate?.onReconnected(self);
    }
    
    func onConnectionFailed(toPeripheral peripheral: PniPeripheral) {
        guard (peripheral.identifier == self.peripheral.identifier) else { return }
        print("Failed to reconnect.");
        delegate?.onDisconnected(self);
    }
    
    func onDisconnected(fromPeripheral peripheral: PniPeripheral, error: Error?) {
        guard (peripheral.identifier == self.peripheral.identifier) else { return }
        stop();
        if let error: Error = error {
            print("🛑 PniCentralManager -> Lost connection to device: '\(peripheral.identifier)'. Error:", error);

            if (willTryToReconnect) {
                state = .RECONNECTING;
                
                // These are all invalid!
                logService.stop();
                factoryService.stop();
                delegate?.onReconnecting(self);
                
                let workItem: DispatchWorkItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }

                    // Give up on reconnecting.
                    self.centralManager.cancelConnection(toPeripheral: self.peripheral);
       
                    self.state = .DISCONNECTED;
                    self.delegate?.onDisconnected(self);
                }
                reconnectTimeout = workItem;
                centralManager.connect(toPeripheral: peripheral);
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.RECONNECT_TIMEOUT, execute: workItem);
            } else {
                state = .DISCONNECTED;
                delegate?.onDisconnected(self);
            }
        } else {
            if (state != .DISCONNECTED) {
                delegate?.onDisconnected(self); // Sometimes SULPOM locks up and then silently disconnects. Notify if this happens.
            }
            state = .DISCONNECTED;
            print("✅ PniCentralManager -> Disconnected safely from: '\(peripheral.identifier)'.");
        }
    }
}
