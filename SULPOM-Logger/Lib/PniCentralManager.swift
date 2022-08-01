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

protocol PniCentralManagerDelegate: AnyObject {
    /// Called when the central manager's state is either requested or updates itself.
    func onStateUpdated(_ centralManager: PniCentralManager, state: CBManagerState);
    
    /// Callback invoked when a new peripheral is discovered while scanning.
    /// - Parameter peripheral: Discovered peripheral.
    /// - Parameter name: The peripheral's name if it exists.
    /// - Parameter manufacturerData: The peripheral's manufacturer data if it has any.
    /// - Parameter rssi: RSSI reading on discovery.
    func onDiscovered(peripheral: PniPeripheral, name: String?, manufacturerData: [UInt8]?, rssi: Float);
    
    /// Called when the central manager connects to a peripheral.
    /// - Parameter peripheral: Peripheral that was connected to.
    func onConnected(toPeripheral peripheral: PniPeripheral);
    
    /// Called when central manager failed to create a connection with a peripheral.
    /// - Parameter peripheral: Peripheral that failed to connect.
    func onConnectionFailed(toPeripheral peripheral: PniPeripheral);
    
    /// Called when a peripheral disconnects.
    /// - Parameters:
    ///   - peripheral: The disconnected peripheral.
    ///   - error: The disconnect error or `nil` if the connection was manually disconnected.
    func onDisconnected(fromPeripheral peripheral: PniPeripheral, error: Error?);
}

/// Nice wrapper for scanning for and initiating a connection
/// to a bluetooth device!
class PniCentralManager: NSObject, CBCentralManagerDelegate {
    // MARK: Member Variables
    
    /// Object to received central manager notifications.
    public weak var delegate: PniCentralManagerDelegate?;
    
    /// Used to manage discovered or connected remote peripheral devices (represented by CBPeripheral objects),
    /// including scanning for, discovering, and connecting to advertising peripherals.
    private lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: Self.queue); // CoreBluetooth changes this to `serial`.
    
    static let shared: PniCentralManager = {
        #if IOS_SIMULATOR
        return Fake_PniCentralManager(delegate: nil);
        #else
        return PniCentralManager(delegate: nil);
        #endif
    }();
    
    lazy var generalLogger = OSLog("CentralManager");
    
    public var state: CBManagerState {
        get { centralManager.state }
    }
    
    @available(iOS 13.0, *)
    public var authorization: CBManagerAuthorization {
        get { centralManager.authorization }
    }
    static let queue = DispatchQueue(label: "com.pnisensor.ble-queue");
    
    
    // MARK: Methods
    
    
    /// Initialize the central manager.
    /// - Parameter delegate: Pass this in at initialization to ensure it receives tartup notifications.
    public init(delegate: PniCentralManagerDelegate?) {
        self.delegate = delegate;
        super.init();
        
        // Redundent, but this triggers lazy initialization!
        centralManager.delegate = self;
    }
    
    /// Calling this will start the BLE device scanning process.
    /// Passing nil indicates that we are looking for any peripheral with any service.
    /// Otherwise pass an array of CBSerbices in first param and it will
    /// filter for only peripherals with those services in its advertisement data.
    /// - Parameter withServices: Optional array of service UUIDs.
    public func startScan(withServices: [String]?) {
        guard (checkState()) else { return }
        
        var uuids: [CBUUID]? = nil;
        if let services: [String] = withServices {
            uuids = [];
            for service: String in services {
                uuids?.append(CBUUID(string: service));
            }
        }

        os_log("Scanning started.", log: generalLogger, type: .debug);
        centralManager.scanForPeripherals(withServices: uuids);
    }

    /// Stops the BLE device scanning process. Also invalidates all timers and puts the UI in its starting
    /// state (but keeps any listed devices since its still posible to connect to them)
    public func stopScan() {
        guard (state == .poweredOn) else {
            print("Can't stop central scan, ble isn't on!");
            return;
        }
        
        os_log("Scanning stopped.", log: generalLogger, type: .debug);
        centralManager.stopScan();
    }

    /// Attempt to connect to the given peripheral.
    /// - Parameter peripheral: Device to connect to.
    public func connect(toPeripheral peripheral: PniPeripheral) {
        guard (checkState()) else { return }
        
        os_log("Connecting to: '%{public}s'.", log: generalLogger, type: .debug, "\(peripheral.identifier.uuidString.prefix(8))");
        centralManager.connect(peripheral.instance, options: nil);
    }
    
    /// Disconnect from the specified peripheral.
    /// - Parameter peripheral: Device to disconnect from.
    public func cancelConnection(toPeripheral peripheral: PniPeripheral) {
        os_log("Cancelling connection: '%{public}s'.", log: generalLogger, type: .debug, "\(peripheral.identifier.uuidString.prefix(8))");
        centralManager.cancelPeripheralConnection(peripheral.instance);
    }
    
    /// Check the BLE state. Returns true if ready to go. Returns false otherwise.
    private func checkState() -> Bool {
        switch (centralManager.state) {
        case .poweredOn:
            os_log("State: 'poweredOn'.", log: generalLogger, type: .debug);
            return true
        case .poweredOff:
            os_log("🟡 State: 'poweredOff'.", log: generalLogger, type: .info);
        case .unsupported:
            os_log("🟡 State: 'unsupported'.", log: generalLogger, type: .info);
        case .unauthorized:
            if #available(iOS 13.0, *) {
                switch (centralManager.authorization) {
                case .notDetermined:
                    os_log("🟡 State: 'unauthorized (notDetermined)'.", log: generalLogger, type: .info);
                case .restricted:
                    os_log("🟡 State: 'unauthorized (restricted)'.", log: generalLogger, type: .info);
                case .denied:
                    os_log("🟡 State: 'unauthorized (denied)'.", log: generalLogger, type: .info);
                case .allowedAlways:
                    os_log("🟡 State: 'unauthorized (allowedAlways)'.", log: generalLogger, type: .info);
                @unknown default:
                    os_log("🟡 State: 'unauthorized (unknown (%d))'.", log: generalLogger, type: .info, centralManager.authorization.rawValue);
                }
            } else {
                os_log("🟡 State: 'unauthorized'.", log: generalLogger, type: .info);
            }
        case .resetting:
            os_log("🟡 State: 'resetting'.", log: generalLogger, type: .info);
        case .unknown:
            fallthrough;
        @unknown default:
            os_log("🟡 State: 'unknown (%d)'.", log: generalLogger, type: .info, centralManager.state.rawValue);
        }
        return false
    }


    // MARK: - CBCentralManagerDelegate
  

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("State updated.", log: generalLogger, type: .debug);
        _ = checkState();
        delegate?.onStateUpdated(self, state: centralManager.state);
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate?.onDiscovered(
            peripheral: PniPeripheral(peripheral: peripheral),
            name: advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            manufacturerData: (advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data)?.bytes,
            rssi: Float(truncating: RSSI));
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("🟢 Connected to: '%{public}s'.", log: generalLogger, type: .debug, "\(peripheral.identifier.uuidString.prefix(8))");
        delegate?.onConnected(toPeripheral: PniPeripheral(peripheral: peripheral));
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error: Error = error {
            os_log("🛑 Failed to connected to: '%{public}s', reason: '%{public}s'.", log: generalLogger, type: .error,
                   "\(peripheral.identifier.uuidString.prefix(8))", error.localizedDescription);
        } else {
            os_log("🛑 Failed to connected to: '%{public}s'.", log: generalLogger, type: .error, "\(peripheral.identifier.uuidString.prefix(8))");
        }
        
        delegate?.onConnectionFailed(toPeripheral: PniPeripheral(peripheral: peripheral))
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let err = error as? CBError {
            os_log("🛑 Disconnected from: '%{public}s', error: '%{public}s' (%d).", log: generalLogger, type: .info, "\(peripheral.identifier.uuidString.prefix(8))", err.localizedDescription, err.errorCode);
        } else {
            os_log("🟢 Disconnected from: '%{public}s'.", log: generalLogger, type: .debug, "\(peripheral.identifier.uuidString.prefix(8))");
        }
        delegate?.onDisconnected(fromPeripheral: PniPeripheral(peripheral: peripheral), error: error);
    }
}
