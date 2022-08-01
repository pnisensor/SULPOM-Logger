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

class FakeLogService {
    let SERVICE_UUID: CBUUID;
    let CHAR_UUID: CBUUID;
    
    typealias LogId = LogService.LogId;
    
    private weak var fakePeripheral: Fake_DevicePeripheral?;
    
    private var isLogging: Bool = false;
    private var startDateLog: Date = Date();
    
    // Enabled log flags.
    private var q9axis_logging: Bool = false;
    private var q6ma_logging: Bool = false;
    private var la_logging: Bool = false;
    private var gyroBias_logging: Bool = false;
    private var timestampFull_logging: Bool = false;
    private var temperature_logging: Bool = false;
    
    private var magRaw_logging: Bool = false;
    private var magAutocal_logging: Bool = false;
    private var accelRaw_logging: Bool = false;
    private var accelAutocal_logging: Bool = false;
    private var gyroRaw_logging: Bool = false;
    private var gyroAutocal_logging: Bool = false;

    private var pressure_logging = false;
    
    // Specific log type timestamps.
    private var timestampFull_date: Date = Date();
    private var temperature_date: Date = Date();
    
    private var odrRate: Double = 1 / 30; // Rate to send logs in seconds.
    private let sendResponseToWrite: Bool
    private var notificationsEnabled: Bool = false;
    
    init(fakePeripheral: Fake_DevicePeripheral, uuids: PniUUIDs.Log) {
        self.fakePeripheral = fakePeripheral;
        self.SERVICE_UUID = uuids.svc;
        self.CHAR_UUID = uuids.char;
        self.sendResponseToWrite = (fakePeripheral.protocolVersion == .R03 || fakePeripheral.protocolVersion == .R04)
    }
    
    func takeOwnership(fakePeripheral: Fake_DevicePeripheral) {
        self.fakePeripheral = fakePeripheral;
    }
    
    public func handleNotifyValue(isEnabled: Bool, characteristic: Fake_CBCharacteristic) {
        notificationsEnabled = isEnabled;
    }
    
    public func handleRead(characteristic: Fake_CBCharacteristic) {
        fakePeripheral?.sendResponse(characteristic, bytes: getTimestampFull())
    }
    
    public func handleWrite(characteristic: Fake_CBCharacteristic, value: [UInt8], type: CBCharacteristicWriteType) {
        // A value of 0 sets the rate to 30Hz default.
        odrRate = (value[0] == 0) ? 1 / 30 : 1 / Double(value[0]);
        
        if (value.count == 2 && value[1] == 0x00) {
            // Turn off everything.
            isLogging = false;
            
            q9axis_logging = false;
            q6ma_logging = false;
            la_logging = false;
            gyroBias_logging = false;
            timestampFull_logging = false;
            temperature_logging = false;
            
            magRaw_logging = false;
            magAutocal_logging = false;
            accelRaw_logging = false;
            accelAutocal_logging = false;
            gyroRaw_logging = false;
            gyroAutocal_logging = false;
            pressure_logging = false;
            
            print("Logging was stopped!");
        } else {
            isLogging = true;
            for index: Int in 1 ..< value.count {
                let byte: UInt8 = value[index];
                switch (byte) {
                case LogId.QUATERNION_9AXIS:
                    q9axis_logging = true;
                case LogId.QUATERNION_MAG_ACCEL:
                    q6ma_logging = true;
                case LogId.LINEAR_ACCEL:
                    la_logging = true;
                case LogId.GYRO_BIAS:
                    gyroBias_logging = true;
                case LogId.TIMESTAMP_FULL:
                    timestampFull_logging = true;
                case LogId.TEMPERATURE:
                    temperature_logging = true;
                case LogId.PRESSURE:
                    pressure_logging = true;
                case LogId.MAG_RAW:
                    magRaw_logging = true;
                case LogId.MAG_AUTOCAL:
                    magAutocal_logging = true;
                case LogId.ACCEL_RAW:
                    accelRaw_logging = true;
                case LogId.ACCEL_AUTOCAL:
                    accelAutocal_logging = true;
                case LogId.GYRO_RAW:
                    gyroRaw_logging = true;
                case LogId.GYRO_AUTOCAL:
                    gyroAutocal_logging = true;
                default:
                    print("(Fake) Unhandled log type enabled: \(byte).");
                }
            }
        }
        
        fake_queue.async { [weak self] in
            guard let self = self else { return }
            if (self.sendResponseToWrite && self.notificationsEnabled) {
                let bytes: [UInt8] = [LogId.RESPONSE] + value
                self.fakePeripheral?.sendResponseUnqueued(characteristic, bytes: bytes)
            }
            if (self.isLogging) {
                print("Logging has started!");
                self.sendLogs();
            }
        }
    }
    
    private func sendLogs() {
        guard (isLogging) else { return }
        guard let char = fakePeripheral?.getChar(uuid: CHAR_UUID), (char._isNotifying) else { return }
        
        guard (notificationsEnabled) else {
            fake_queue.asyncAfter(deadline: .now() + odrRate) { [weak self] in
                self?.sendLogs();
            }
            return
        }
        
        if (q9axis_logging) {
            fakePeripheral?.sendResponse(char, bytes: getQ9axis())
        }
        
        if (q6ma_logging) {
            fakePeripheral?.sendResponse(char, bytes: getQma6())
        }
        
        if (la_logging) {
            fakePeripheral?.sendResponse(char, bytes: getLinearAccel())
        }
        
        if (gyroBias_logging) {
            fakePeripheral?.sendResponse(char, bytes: getGyroBias())
        }
        
        if (magRaw_logging) {
            fakePeripheral?.sendResponse(char, bytes: getMagRaw())
        }
        if (magAutocal_logging) {
            fakePeripheral?.sendResponse(char, bytes: getMagAutocal())
        }
        
        if (accelRaw_logging) {
            fakePeripheral?.sendResponse(char, bytes: getAccelRaw())
        }
        if (accelAutocal_logging) {
            fakePeripheral?.sendResponse(char, bytes: getAccelAutocal())
        }
        
        if (gyroRaw_logging) {
            fakePeripheral?.sendResponse(char, bytes: getGyroRaw())
        }
        if (gyroAutocal_logging) {
            fakePeripheral?.sendResponse(char, bytes: getGyroAutocal())
        }
        
        if (pressure_logging) {
            fakePeripheral?.sendResponse(char, bytes: getPressure())
        }
        
        // Full timestamp once every 5 seconds.
        if (timestampFull_logging && timestampFull_date.timeIntervalSinceNow * -1 >= 5) {
            timestampFull_date = Date();
            fakePeripheral?.sendResponse(char, bytes: getTimestampFull())
        }
        
        // Temperature once every second.
        if (temperature_logging && temperature_date.timeIntervalSinceNow * -1 >= 1) {
            temperature_date = Date();
            fakePeripheral?.sendResponse(char, bytes: getTemperature())
        }
        
        
        fake_queue.asyncAfter(deadline: .now() + odrRate) { [weak self] in
            self?.sendLogs();
        };
    }
    
    private func getTs() -> UInt32 {
        let ts: NSNumber = NSNumber(value: startDateLog.timeIntervalSinceNow * -1 * 1000000);
        return UInt32(truncating: ts);
    }
    
    private func getTimestampFull() -> [UInt8] {
        let ts: NSNumber = NSNumber(value: startDateLog.timeIntervalSinceNow * -1 * 1000000);
        let tsBytes: [UInt8] = UInt64(truncating: ts).bytes;
        
        return [
            LogId.TIMESTAMP_FULL, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            tsBytes[4], tsBytes[5], tsBytes[6], tsBytes[7],
        ];
    }
    
    private func getTemperature() -> [UInt8] {
        let value: Float = Float.random(in: 22 ..< 27)
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        let valueBytes: [UInt8] = value.bytes;
        
        return [
            LogId.TEMPERATURE, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            valueBytes[0], valueBytes[1], valueBytes[2], valueBytes[3],
        ];
    }
    
    private func getQuaternion24Bit(id: UInt8, index: Int) -> [UInt8] {
        let q0: Float = fakeQuaternion[index].0;
        let q1: Float = fakeQuaternion[index].1;
        let q2: Float = fakeQuaternion[index].2;
        let q3: Float = fakeQuaternion[index].3;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        let scale: Double = 8388607;
        
        let x: Int32 = Int32(Double(q0) * scale);
        let xBytes: [UInt8] = x.bytes;
        
        let y: Int32 = Int32(Double(q1) * scale);
        let yBytes: [UInt8] = y.bytes;
        
        let z: Int32 = Int32(Double(q2) * scale);
        let zBytes: [UInt8] = z.bytes;
        
        let w: Int32 = Int32(Double(q3) * scale);
        let wBytes: [UInt8] = w.bytes;
        
        return [
            id, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2],
            yBytes[0], yBytes[1], yBytes[2],
            zBytes[0], zBytes[1], zBytes[2],
            wBytes[0], wBytes[1], wBytes[2],
        ];
    }
    
    private var q9axis_index: Int = 0;
    private func getQ9axis() -> [UInt8] {
        if (q9axis_index >= fakeQuaternion.count) {
            q9axis_index = 0;
        }
        let bytes = getQuaternion24Bit(id: LogId.QUATERNION_9AXIS, index: q9axis_index);
        q9axis_index += 1;
        return bytes;
    }
    
    private var q6ma_index: Int = 0;
    private func getQma6() -> [UInt8] {
        if (q6ma_index >= fakeQuaternion.count) {
            q6ma_index = 0;
        }
        
        let bytes = getQuaternion24Bit(id: LogId.QUATERNION_MAG_ACCEL, index: q6ma_index);
        q6ma_index += 1;
        return bytes;
    }
    
    private var la_index: Int = 0;
    private func getLinearAccel() -> [UInt8] {
        if (la_index >= fakeLinearAccel.count) {
            la_index = 0;
        }
        let la0: Float = fakeLinearAccel[la_index].0;
        let la1: Float = fakeLinearAccel[la_index].1;
        let la2: Float = fakeLinearAccel[la_index].2;
        la_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = la0.bytes;
        let yBytes: [UInt8] = la1.bytes;
        let zBytes: [UInt8] = la2.bytes;
        
        return [
            LogId.LINEAR_ACCEL, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2], xBytes[3],
            yBytes[0], yBytes[1], yBytes[2], yBytes[3],
            zBytes[0], zBytes[1], zBytes[2], zBytes[3],
        ];
    }
    
    private var gyroBias_index: Int = 0;
    private func getGyroBias() -> [UInt8] {
        if (gyroBias_index >= fakeGyroBias.count) {
            gyroBias_index = 0;
        }
        let gb0: Float = fakeGyroBias[gyroBias_index].0;
        let gb1: Float = fakeGyroBias[gyroBias_index].1;
        let gb2: Float = fakeGyroBias[gyroBias_index].2;
        gyroBias_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = gb0.bytes;
        let yBytes: [UInt8] = gb1.bytes;
        let zBytes: [UInt8] = gb2.bytes;
        
        return [
            LogId.GYRO_BIAS, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2], xBytes[3],
            yBytes[0], yBytes[1], yBytes[2], yBytes[3],
            zBytes[0], zBytes[1], zBytes[2], zBytes[3],
        ];
    }
    
    private var magRaw_index: Int = 0;
    private func getMagRaw() -> [UInt8] {
        // Use maxwell raw mag for now...
        if (magRaw_index >= fakeMagRaw.count) {
            magRaw_index = 0;
        }
        let m0: Int32 = fakeMagRaw[magRaw_index].0;
        let m1: Int32 = fakeMagRaw[magRaw_index].1;
        let m2: Int32 = fakeMagRaw[magRaw_index].2;
        magRaw_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = m0.bytes;
        let yBytes: [UInt8] = m1.bytes;
        let zBytes: [UInt8] = m2.bytes;
        
        return [
            LogId.MAG_RAW, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2],
            yBytes[0], yBytes[1], yBytes[2],
            zBytes[0], zBytes[1], zBytes[2],
        ];
    }
    
    private var magAutocal_index: Int = 0;
    private func getMagAutocal() -> [UInt8] {
        if (magAutocal_index >= fakeMagAutocal.count) {
            magAutocal_index = 0;
        }
        let m0: Float = fakeMagAutocal[magAutocal_index].0;
        let m1: Float = fakeMagAutocal[magAutocal_index].1;
        let m2: Float = fakeMagAutocal[magAutocal_index].2;
        magAutocal_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = m0.bytes;
        let yBytes: [UInt8] = m1.bytes;
        let zBytes: [UInt8] = m2.bytes;
        
        return [
            LogId.MAG_AUTOCAL, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2], xBytes[3],
            yBytes[0], yBytes[1], yBytes[2], yBytes[3],
            zBytes[0], zBytes[1], zBytes[2], zBytes[3],
        ];
    }
    
    private var accelRaw_index: Int = 0;
    private func getAccelRaw() -> [UInt8] {
        if (accelRaw_index >= fakeAccelRaw.count) {
            accelRaw_index = 0;
        }
        let a0: Int16 = fakeAccelRaw[accelRaw_index].0;
        let a1: Int16 = fakeAccelRaw[accelRaw_index].1;
        let a2: Int16 = fakeAccelRaw[accelRaw_index].2;
        accelRaw_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = a0.bytes;
        let yBytes: [UInt8] = a1.bytes;
        let zBytes: [UInt8] = a2.bytes;
        
        return [
            LogId.ACCEL_RAW, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1],
            yBytes[0], yBytes[1],
            zBytes[0], zBytes[1],
        ];
    }
    
    private var accelAutocal_index: Int = 0;
    private func getAccelAutocal() -> [UInt8] {
        if (accelAutocal_index >= fakeAccelAutocal.count) {
            accelAutocal_index = 0;
        }
        let a0: Float = fakeAccelAutocal[accelAutocal_index].0;
        let a1: Float = fakeAccelAutocal[accelAutocal_index].1;
        let a2: Float = fakeAccelAutocal[accelAutocal_index].2;
        accelAutocal_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = a0.bytes;
        let yBytes: [UInt8] = a1.bytes;
        let zBytes: [UInt8] = a2.bytes;
        
        return [
            LogId.ACCEL_AUTOCAL, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2], xBytes[3],
            yBytes[0], yBytes[1], yBytes[2], yBytes[3],
            zBytes[0], zBytes[1], zBytes[2], zBytes[3],
        ];
    }
    
    private var gyroRaw_index: Int = 0;
    private func getGyroRaw() -> [UInt8] {
        if (gyroRaw_index >= fakeGyroRaw.count) {
            gyroRaw_index = 0;
        }
        let g0: Int16 = fakeGyroRaw[gyroRaw_index].0;
        let g1: Int16 = fakeGyroRaw[gyroRaw_index].1;
        let g2: Int16 = fakeGyroRaw[gyroRaw_index].2;
        gyroRaw_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = g0.bytes;
        let yBytes: [UInt8] = g1.bytes;
        let zBytes: [UInt8] = g2.bytes;
        
        return [
            LogId.GYRO_RAW, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1],
            yBytes[0], yBytes[1],
            zBytes[0], zBytes[1],
        ];
    }
    
    private var gyroAutocal_index: Int = 0;
    private func getGyroAutocal() -> [UInt8] {
        if (gyroAutocal_index >= fakeGyroAutocal.count) {
            gyroAutocal_index = 0;
        }
        let g0: Float = fakeGyroAutocal[gyroAutocal_index].0;
        let g1: Float = fakeGyroAutocal[gyroAutocal_index].1;
        let g2: Float = fakeGyroAutocal[gyroAutocal_index].2;
        gyroAutocal_index += 1;
        
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let xBytes: [UInt8] = g0.bytes;
        let yBytes: [UInt8] = g1.bytes;
        let zBytes: [UInt8] = g2.bytes;
        
        return [
            LogId.GYRO_AUTOCAL, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            xBytes[0], xBytes[1], xBytes[2], xBytes[3],
            yBytes[0], yBytes[1], yBytes[2], yBytes[3],
            zBytes[0], zBytes[1], zBytes[2], zBytes[3],
        ];
    }
    
    private var pressure: Float = 1000;
    private var increasePressure = true;
    private func getPressure() -> [UInt8] {
        let ts = getTs()
        let tsBytes: [UInt8] = ts.bytes;
        
        let pressureBytes = pressure.bytes;
        
        let bytes = [
            LogId.PRESSURE, 0,
            tsBytes[0], tsBytes[1], tsBytes[2], tsBytes[3],
            pressureBytes[0], pressureBytes[1], pressureBytes[2], pressureBytes[3],
        ]
        
        if (pressure >= 1050) {
            increasePressure = false;
        } else if (pressure <= 950) {
            increasePressure = true;
        }
        if (increasePressure) {
            pressure += 0.65;
        } else {
            pressure -= 0.95;
        }
        
        return bytes;
    }
}

#endif // IOS_SIMULATOR
