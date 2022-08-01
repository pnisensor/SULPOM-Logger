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
import UIKit

/// Container for connected devices. Note that if a device disconnects, then it must be manully removed.
class ConnectedDevices: Collection, LogServiceDelegate {
    static let shared = ConnectedDevices();
    
    private init() {
        // Keep these in the order they were added.
        devices.sortByRssi = false;
        
        if (rate > 200) {
            // Max ODR in firmware is 200.
            rate = 200;
        }
    }
    
    private var devices = Devices();
    
    /// The number of devices.
    public var count: Int {
        get { devices.count }
    }
    
    /// The sample rate (in Hz) for logging over BLE.
    var rate: UInt8 = AppSettings.Log.rate;
    
    /// The logs to enable when BLE logging starts.
    let enabled = EnabledLogs();
    
    /// Is at least one device a SULPOM?
    private(set) var includeSulpomLogs = false;
    
    /// Is logging currently started?
    private(set) var isLogging = false;
    private var logs: [SensorLogItem] = [];
    var logCount: Int {
        get { logs.count }
    }
    private var loggingStartDate = Date();
    private(set) var headers: SensorLogHeaders = SensorLogHeaders(sensors: [], appDate: Date());
    private let jsonWriter = SensorLogWriter();
    
    
    // MARK: Methods
    
    
    /// Add a device to the collection. If a device with the same id exists, then it will be replaced.
    @discardableResult
    func add(_ device: Device) -> Int {
        device.logService.delegate = self;
        device.logService.start();
        if (!includeSulpomLogs && device.firmware.typeId.isSulpom()) {
            includeSulpomLogs = true;
        }
        return devices.append(device: device);
    }
    
    /// Remove a device at the given index from te collection.
    func remove(at idx: Int) {
        devices.remove(at: idx);
        includeSulpomLogs = false;
        for device in devices {
            if (device.firmware.typeId.isSulpom()) {
                includeSulpomLogs = true;
                break;
            }
        }
    }
    
    /// Lookup the index of a device in the collection. This will return -1 if the
    /// device is not found.
    func indexOf(_ device: Device) -> Int {
        return devices.indexOf(device: device);
    }
    
    /// Starts BLE logging. This will use the set sample rate (in Hz) and the enabled logs.
    func startLogging() {
        logs = [];
        loggingStartDate = Date();
        
        let headerSensors = devices.map {
            SensorLogHeaders.Sensor(firmware: $0.firmware.name, serialNumber: $0.id);
        }
        headers = SensorLogHeaders(sensors: headerSensors, appDate: loggingStartDate);
        if (nstStreaming.isEnabled) {
            if let data = try? SensorLogWriter.encoder.encode(headers) {
                NstStreaming.shared.sendJson(channel: "loggingStarted", jsonMsgData: data)
            } else {
                NstStreaming.shared.sendJson(channel: "loggingStarted", jsonMsg: "{}");
            }
        }
        
        for device in devices {
            device.logService.enableLogs(rate: rate, logTypes: enabledList);
        }
        isLogging = true;
    }
    
    /// Stops BLE logging.
    func stopLogging() {
        isLogging = false;
        for device in devices {
            device.logService.stopLogs();
        }
        
        if (nstStreaming.isEnabled) {
            NstStreaming.shared.sendJson(channel: "loggingStopped", jsonMsg: "{}")
        }
    }
    
    /// Export the current sensor log. Note that the log will be deleted if no references remain to
    /// the exported TemporaryFile object.
    func exportLog(cb: @escaping SensorLogWriterCb) {
        jsonWriter.writeJson(
            date: loggingStartDate, items: logs, headers: headers, cb: cb)
    }
    
    private func addLogItem(_ item: SensorLogItem) {
        logs.append(item);
        if (nstStreaming.isEnabled) {
            if let data = try? SensorLogWriter.encoder.encode(item) {
                NstStreaming.shared.sendJson(channel: item.id, jsonMsgData: data)
            }
        }
    }
    
    
    // MARK: - Collection methods

    
    /// '[]' operator overload. Allows indexing into the array of devices.
    /// - Parameter index: The index to use in the device array.
    public subscript(index: Int) -> Device {
        get { devices[index] }
    }
    
    // Upper bounds of the collection.
    public var startIndex: Int {
        return devices.startIndex;
    };
    
    // Lower bounds of the collection.
    public var endIndex: Int {
        return devices.endIndex;
    };

    // Method that returns the next index when iterating.
    public func index(after i: Int) -> Int {
        return devices.index(after: i)
    }
    
    
    // MARK: LogServiceDelegate
    
    
    func onStart(_ service: LogService) {
        // TODO...
    }
    
    func onMagRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .MAG_RAW, ts: log.ts, appDate: appDate,
                                 values: values)
        addLogItem(item)
    }
    func onMagAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .MAG_AUTOCAL, ts: log.ts, appDate: appDate,
                                 values: values)
        addLogItem(item)
    }
    func onAccelRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .ACCEL_RAW, ts: log.ts, appDate: appDate,
                                 values: values)
        addLogItem(item)
    }
    func onAccelAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .ACCEL_AUTOCAL, ts: log.ts, appDate: appDate,
                                 values: values)
        addLogItem(item)
    }
    func onGyroRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .GYRO_RAW, ts: log.ts, appDate: appDate,
                                 values: values)
        addLogItem(item)
    }
    func onGyroAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .GYRO_AUTOCAL, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onQuaternionMagAccel(_ service: LogService, log: QuaternionLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z, log.w]
        let item = SensorLogItem(id: service.deviceId, typeId: .Q_MAG_ACCEL, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onQuaternion9Axis(_ service: LogService, log: QuaternionLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z, log.w]
        let item = SensorLogItem(id: service.deviceId, typeId: .Q_9AXIS, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onLinearAccel(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .LINEAR_ACCEL, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onGyroBias(_ service: LogService, log: SensorLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.x, log.y, log.z]
        let item = SensorLogItem(id: service.deviceId, typeId: .GYRO_BIAS, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onTemperature(_ service: LogService, log: TemperatureLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.degrees]
        let item = SensorLogItem(id: service.deviceId, typeId: .TEMPERATURE, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onTimestampFull(_ service: LogService, log: TimestampFullLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [Float(log.upper)]
        let item = SensorLogItem(id: service.deviceId, typeId: .TIMESTAMP_FULL, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    func onPressure(_ service: LogService, log: PressureLog, appDate: Date) {
        guard (isLogging) else { return }
        let values = [log.hPaValue]
        let item = SensorLogItem(id: service.deviceId, typeId: .PRESSURE, ts: log.ts,
                                 appDate: appDate, values: values)
        addLogItem(item)
    }
    
    class EnabledLogs {
        var quaternion9axis: Bool = AppSettings.Log.Enabled.quaternion9axis;
        var quaternionMagAccel: Bool = AppSettings.Log.Enabled.quaternionMagAccel;
        var linearAccel: Bool = AppSettings.Log.Enabled.linearAccel;
        var gyroBias: Bool = AppSettings.Log.Enabled.gyroBias;
        var magRaw: Bool = AppSettings.Log.Enabled.magRaw;
        var magAutocal: Bool = AppSettings.Log.Enabled.magAutocal;
        var accelRaw: Bool = AppSettings.Log.Enabled.accelRaw;
        var accelAutocal: Bool = AppSettings.Log.Enabled.accelAutocal;
        var gyroRaw: Bool = AppSettings.Log.Enabled.gyroRaw;
        var gyroAutocal: Bool = AppSettings.Log.Enabled.gyroAutocal;
        var temperature: Bool = AppSettings.Log.Enabled.temperature;
        var pressure: Bool = AppSettings.Log.Enabled.pressure;

        fileprivate init() { }
    }
    
    class NstStreamingSettings {
        var isEnabled = AppSettings.Log.NstStreaming.isEnabled;
        var url = AppSettings.Log.NstStreaming.url;
        var apiKey = AppSettings.Log.NstStreaming.apiKey;
        var autoConnect = AppSettings.Log.NstStreaming.autoConnect;
    }
    let nstStreaming = NstStreamingSettings();
    
    class NstUploadSettings {
        var isEnabled = AppSettings.Log.NstUpload.isEnabled;
        var apiKey = AppSettings.Log.NstUpload.apiKey;
    }
    let nstUpload = NstUploadSettings();
    
    var enabledList: [LogService.LogType] {
        var types: [LogService.LogType] = [];
        
        if (enabled.magRaw) { types.append(.MAG_RAW) }
        if (enabled.magAutocal) { types.append(.MAG_AUTOCAL) }
        if (enabled.accelRaw) { types.append(.ACCEL_RAW) }
        if (enabled.accelAutocal) { types.append(.ACCEL_AUTOCAL) }
        if (enabled.gyroRaw) { types.append(.GYRO_RAW) }
        if (enabled.gyroAutocal) { types.append(.GYRO_AUTOCAL) }
        if (enabled.quaternionMagAccel) { types.append(.QUATERNION_MAG_ACCEL) }
        if (enabled.quaternion9axis) { types.append(.QUATERNION_9AXIS) }
        if (enabled.linearAccel) { types.append(.LINEAR_ACCEL) }
        if (enabled.gyroBias) { types.append(.GYRO_BIAS) }
        if (enabled.temperature) { types.append(.TEMPERATURE) }
        if (enabled.pressure && includeSulpomLogs) { types.append(.PRESSURE) }
        return types;
    }
}
