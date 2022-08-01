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
import CoreBluetooth
import os.log

public struct SensorLog {
    let ts: UInt32;
    let x: Float;
    let y: Float;
    let z: Float;
}

public struct QuaternionLog {
    let ts: UInt32;
    let x: Float;
    let y: Float;
    let z: Float;
    let w: Float;
}

public struct TemperatureLog {
    let ts: UInt32;
    let degrees: Float;
}

public struct TimestampFullLog {
    let ts: UInt32;
    let upper: UInt32;
}

public struct PressureLog {
    let ts: UInt32
    let hPaValue: Float
}


class LogService: IPniService {
    // MARK: Constants
    public let uuid: CBUUID;
    /// Read quaternion.
    private let NOTIFY_UUID: CBUUID;
    
    enum LogId {
        static let RESPONSE: UInt8                  = 0;
        static let MAG_RAW: UInt8                   = 1;
        static let TEMPERATURE: UInt8               = 7;
        static let ACCEL_RAW: UInt8                 = 15;
        static let GYRO_RAW: UInt8                  = 62;
        static let QUATERNION_MAG_ACCEL: UInt8      = 77;
        static let MAG_AUTOCAL: UInt8               = 93;
        static let ACCEL_AUTOCAL: UInt8             = 99;
        static let GYRO_AUTOCAL: UInt8              = 108;
        static let TIMESTAMP_FULL: UInt8            = 111;
        static let LINEAR_ACCEL: UInt8              = 202;
        static let QUATERNION_9AXIS: UInt8          = 204;
        static let GYRO_BIAS: UInt8                 = 205;
        
        // SULPOM Stuff
        static let PRESSURE: UInt8                  = 233;
    }
    
    enum LogType {
        case MAG_RAW;
        case MAG_AUTOCAL;
        case ACCEL_RAW;
        case ACCEL_AUTOCAL;
        case GYRO_RAW;
        case GYRO_AUTOCAL;
        case QUATERNION_MAG_ACCEL;
        case QUATERNION_9AXIS;
        case LINEAR_ACCEL;
        case GYRO_BIAS;
        case TEMPERATURE;
        case TIMESTAMP_FULL;
        case PRESSURE;
    }
    

    // MARK: Member Variables
    
    /// The object to receive notifications from this service.
    public weak var delegate: LogServiceDelegate?;
    private var isServiceReady: Bool = false;
    
    private let peripheral: PniPeripheral;
    private var notifyChar: CBCharacteristic?;
    private var isStartingUp: Bool = false; // Has the CBService been discovered since start was called?
    private var willEnableNotifications: Bool = true;
    
    private lazy var logger = OSLog("LogSvc(\("\(peripheral.identifier.uuidString.prefix(8))"))");
    private let filterLogs = true; // Only log timestamp full if enabled.
    private let protocolVersion: PniUUIDs.ProtocalVersion
    private var responseTimeout: DispatchWorkItem?
    private var command: [UInt8] = [];
    
    /// The id of the device this service belongs to.
    let deviceId: String;
    
    // MARK: Methods
    
    init(device: Device) {
        self.peripheral = device.peripheral;
        self.deviceId = device.id;
        uuid = device.uuids.log.svc;
        NOTIFY_UUID = device.uuids.log.char;
        protocolVersion = device.uuids.protocolVeraion;
    }
    
    /// Start the service up.
    func start(enableNotifications: Bool = true) {
        willEnableNotifications = enableNotifications;
        if (isServiceReady), let characteristic: CBCharacteristic = notifyChar {
            if (!characteristic.isNotifying && willEnableNotifications) {
                updateNotifyValue(characteristic, enabled: true)
            } else {
                delegate?.onStart(self);
            }
        } else {
            isStartingUp = true;
            peripheral.discoverServices(uuids: [uuid]);
        }
    }
    
    func stop(turnOffLogs: Bool = false) {
        isServiceReady = false;
        
        if (turnOffLogs) {
            stopLogs();
            // Don't disable notifications from here anymore.
            // Leave them on since we want to ensure the device sends a response.
        }
        
        if (protocolVersion == .R02 || !turnOffLogs) {
            if let characteristic: CBCharacteristic = notifyChar {
                updateNotifyValue(characteristic, enabled: false)
            }
        }
    }
    
    deinit {
        stop();
        print("\(Self.self) dtr.");
    }
        
    /// Set which log types should be enabled in the LPOM. Sending an empty list will turn off all logs.
    /// The list of active logs is cumulative until reset. It is not possible to turn off a single log.
    /// - Parameters:
    ///   - rate: Desired rate in Hz to receive logs at using ODR.
    ///   - logTypes: Array of log types to receive.
    public func enableLogs(rate: UInt8, logTypes: [LogType]) {
        guard (!logTypes.isEmpty) else {
            stopLogs();
            return;
        }
        
        var command: [UInt8] = [rate];
        for logType: LogType in logTypes {
            switch (logType) {
            case .MAG_RAW:
                command.append(LogId.MAG_RAW);
            case .MAG_AUTOCAL:
                command.append(LogId.MAG_AUTOCAL);
            case .ACCEL_RAW:
                command.append(LogId.ACCEL_RAW);
            case .ACCEL_AUTOCAL:
                command.append(LogId.ACCEL_AUTOCAL);
            case .GYRO_RAW:
                command.append(LogId.GYRO_RAW);
            case .GYRO_AUTOCAL:
                command.append(LogId.GYRO_AUTOCAL);
            case .QUATERNION_MAG_ACCEL:
                command.append(LogId.QUATERNION_MAG_ACCEL);
            case .QUATERNION_9AXIS:
                command.append(LogId.QUATERNION_9AXIS);
            case .LINEAR_ACCEL:
                command.append(LogId.LINEAR_ACCEL);
            case .GYRO_BIAS:
                command.append(LogId.GYRO_BIAS);
            case .TEMPERATURE:
                command.append(LogId.TEMPERATURE);
            case .TIMESTAMP_FULL:
                command.append(LogId.TIMESTAMP_FULL);
            case .PRESSURE:
                command.append(LogId.PRESSURE);
            }
        }
        
        if (command.count > 20) {
            print("⚠️ \(Self.self) -> More log IDs than can fit have been passed: ", command);
        }
        sendCommand(bytes: command);
        if (filterLogs) {
            os_log("Printed logs will be filtered.", log: logger, type: .debug);
        }
    }
    
    /// Stops all enabled logs.
    public func stopLogs() {
        let command: [UInt8] = [0, 0];
        sendCommand(bytes: command);
    }
    
    public func readFullTimestamp() {
        guard let notifyChar: CBCharacteristic = notifyChar, (isServiceReady) else {
            print("\(Self.self) -> Can't read timestamp since service hasn't been started.");
            return;
        }
        
        os_log(">> READ", log: logger, type: .debug);
        peripheral.readValue(for: notifyChar);
    }
    
    /// Unwrap the characteristic, then send the write request.
    /// - Parameter bytes: Bytes to write.
    private func sendCommand(bytes: [UInt8]) {
        guard let terminalChar: CBCharacteristic = notifyChar else {
            print("\(Self.self) -> Can't send command to log service.");
            return;
        }
        os_log(">> %s", log: logger, type: .debug, "\(bytes)");
        
        if (protocolVersion == .R03) {
            command = bytes;
            startTimeout()
        }
        peripheral.writeValue(characteristic: terminalChar, value: bytes, type: .withoutResponse);
    }
    
    private func updateNotifyValue(_ characteristic: CBCharacteristic, enabled: Bool) {
        os_log("Setting Notification state to '%@'.", log: logger, type: .debug,
               String(enabled));
        peripheral.setNotifyValue(isEnabled: enabled, characteristic: characteristic);
    }
    
    private func startTimeout() {
        stopTimeout();
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, (!self.command.isEmpty && self.notifyChar?.isNotifying == true && self.peripheral.isConnected) else { return }
            os_log("⚠️ The request did not reply in under 1 second. Attempting to resend...", log: self.logger, type: .debug);
            self.sendCommand(bytes: self.command)
        }
        responseTimeout = timeout;
        PniCentralManager.queue.asyncAfter(deadline: .now() + 0.8 , execute: timeout)
    }
    
    private func stopTimeout() {
        responseTimeout?.cancel();
        responseTimeout = nil;
    }

    private func bytesToSensorLog(bytes: [UInt8]) -> SensorLog {
        return SensorLog(
            ts: bytes.getUInt32(2),
            x: bytes.getFloat(6),
            y: bytes.getFloat(10),
            z: bytes.getFloat(14));
    }
    
    private func bytesToQLog(bytes: [UInt8]) -> QuaternionLog {
        let scale: Float = 8388607;
        return QuaternionLog(
            ts: bytes.getUInt32(2),
            x: Float(bytes.getInt24(6)) / scale,
            y: Float(bytes.getInt24(9)) / scale,
            z: Float(bytes.getInt24(12)) / scale,
            w: Float(bytes.getInt24(15)) / scale);
    }
    
    
    // MARK: Peripheral handlers
    

    func handleData(fromCharacteristic characteristic: CBCharacteristic, bytes: [UInt8]) {
        if (characteristic.uuid == NOTIFY_UUID) {
            if (!filterLogs) {
                os_log("<< %s", log: logger, type: .debug, "\(bytes)");
            }
            guard (!bytes.isEmpty) else { return }
            let timestamp = Date();
            
            // Decode the log and call the appropriate delegate with the result.
            // Improperly formatted logs, i.e. invalid length, will be lost.
            let logId: UInt8 = bytes[0];
            switch (logId) {
            case LogId.RESPONSE:
                if (filterLogs) {
                    os_log("<< %s", log: logger, type: .debug, "\(bytes)");
                }
                if (protocolVersion == .R03) {
                    stopTimeout();
                    if (!isServiceReady) {
                        // Now disable notifications...
                        if let characteristic: CBCharacteristic = notifyChar {
                            updateNotifyValue(characteristic, enabled: false)
                        }
                    }
                }
            case LogId.MAG_RAW:
                guard (bytes.count == 15) else { return }
                let log = SensorLog(
                    ts: bytes.getUInt32(2),
                    x: Float(bytes.getInt24(6)),
                    y: Float(bytes.getInt24(9)),
                    z: Float(bytes.getInt24(12)))
                delegate?.onMagRaw(self, log: log, appDate: timestamp);
            case LogId.MAG_AUTOCAL:
                guard (bytes.count == 18) else { return }
                let log = bytesToSensorLog(bytes: bytes)
                delegate?.onMagAutocal(self, log: log, appDate: timestamp);
            case LogId.ACCEL_RAW:
                guard (bytes.count == 12) else { return }
                let log = SensorLog(
                    ts: bytes.getUInt32(2),
                    x: Float(bytes.getInt16(6)),
                    y: Float(bytes.getInt16(8)),
                    z: Float(bytes.getInt16(10)))
                delegate?.onAccelRaw(self, log: log, appDate: timestamp);
            case LogId.ACCEL_AUTOCAL:
                guard (bytes.count == 18) else { return }
                let log = bytesToSensorLog(bytes: bytes)
                delegate?.onAccelAutocal(self, log: log, appDate: timestamp);
            case LogId.GYRO_RAW:
                guard (bytes.count == 12) else { return }
                let log = SensorLog(
                    ts: bytes.getUInt32(2),
                    x: Float(bytes.getInt16(6)),
                    y: Float(bytes.getInt16(8)),
                    z: Float(bytes.getInt16(10)))
                delegate?.onGyroRaw(self, log: log, appDate: timestamp);
            case LogId.GYRO_AUTOCAL:
                guard (bytes.count == 18) else { return }
                let log = bytesToSensorLog(bytes: bytes)
                delegate?.onGyroAutocal(self, log: log, appDate: timestamp);
            case LogId.QUATERNION_MAG_ACCEL:
                guard (bytes.count == 18) else { return }
                let log = bytesToQLog(bytes: bytes)
                delegate?.onQuaternionMagAccel(self, log: log, appDate: timestamp);
            case LogId.QUATERNION_9AXIS:
                guard (bytes.count == 18) else { return }
                let log = bytesToQLog(bytes: bytes)
                delegate?.onQuaternion9Axis(self, log: log, appDate: timestamp);
            case LogId.LINEAR_ACCEL:
                guard (bytes.count == 18) else { return }
                let log = bytesToSensorLog(bytes: bytes)
                delegate?.onLinearAccel(self, log: log, appDate: timestamp);
            case LogId.GYRO_BIAS:
                guard (bytes.count == 18) else { return }
                let log = bytesToSensorLog(bytes: bytes)
                delegate?.onGyroBias(self, log: log, appDate: timestamp);
            case LogId.TEMPERATURE:
                guard (bytes.count == 10) else { return }
                let log = TemperatureLog(ts: bytes.getUInt32(2), degrees: bytes.getFloat(6))
                delegate?.onTemperature(self, log: log, appDate: timestamp);
            case LogId.TIMESTAMP_FULL:
                guard (bytes.count == 10) else { return }
                if (filterLogs) {
                    os_log("<< %s (%.2f)", log: logger, type: .debug, "\(bytes)", Double(bytes.getUInt64(2)) / 1000000);
                }
                let log = TimestampFullLog(ts: bytes.getUInt32(2), upper: bytes.getUInt32(6));
                delegate?.onTimestampFull(self, log: log, appDate: timestamp);
            case LogId.PRESSURE:
                guard (bytes.count == 10) else { return }
                let log = PressureLog(ts: bytes.getUInt32(2), hPaValue: bytes.getFloat(6))
                delegate?.onPressure(self, log: log, appDate: timestamp);
            default:
                print("⚠️ \(Self.self) -> Unhandled log type: ", logId);
            }
        }
    }
    
    func handleServiceDiscovered(service: CBService) {
        if (isStartingUp && service.uuid == uuid) {
            isStartingUp = false;
            peripheral.discoverCharacteristics(uuids: [NOTIFY_UUID], service: service);
        }
    }
    
    func handleCharacteristicsDiscovered(characteristics: [CBCharacteristic]) {
        for characteristic: CBCharacteristic in characteristics {
            if (characteristic.uuid == NOTIFY_UUID) {
                // Save notify characteristic and enable notifications.
                notifyChar = characteristic;
                if (willEnableNotifications) {
                    updateNotifyValue(characteristic, enabled: true);
                } else {
                    // Service is ready!
                    isServiceReady = true;
                    delegate?.onStart(self);
                }
            }
        }
    }
    
    func handleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic) {
        os_log("Notification state set to '%@'.", log: logger, type: .debug,
               String(characteristic.isNotifying));
        if (characteristic.uuid == NOTIFY_UUID && characteristic.isNotifying) {
            // Service is ready!
            isServiceReady = true;
            delegate?.onStart(self);
        }
    }
}
