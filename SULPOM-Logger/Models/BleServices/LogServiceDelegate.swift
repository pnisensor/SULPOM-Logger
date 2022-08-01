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

protocol LogServiceDelegate: AnyObject {
    func onStart(_ service: LogService);
    func onMagRaw(_ service: LogService, log: SensorLog, appDate: Date);
    func onMagAutocal(_ service: LogService, log: SensorLog, appDate: Date);
    func onAccelRaw(_ service: LogService, log: SensorLog, appDate: Date);
    func onAccelAutocal(_ service: LogService, log: SensorLog, appDate: Date);
    func onGyroRaw(_ service: LogService, log: SensorLog, appDate: Date);
    func onGyroAutocal(_ service: LogService, log: SensorLog, appDate: Date);
    func onQuaternionMagAccel(_ service: LogService, log: QuaternionLog, appDate: Date);
    func onQuaternion9Axis(_ service: LogService, log: QuaternionLog, appDate: Date);
    func onLinearAccel(_ service: LogService, log: SensorLog, appDate: Date);
    func onGyroBias(_ service: LogService, log: SensorLog, appDate: Date);
    func onTemperature(_ service: LogService, log: TemperatureLog, appDate: Date);
    func onTimestampFull(_ service: LogService, log: TimestampFullLog, appDate: Date);
    func onPressure(_ service: LogService, log: PressureLog, appDate: Date);
}

// Optional methods. Print a warning if they are usedw/o implementation.
extension LogServiceDelegate {
    private func printWarning(obj: String = "\(Self.self)", fn: String = #function) {
        print("⚠️ '\(obj): \(LogServiceDelegate.self)' -> '\(fn)' is using default implementation which does nothing.")
    }
    func onMagRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onMagAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onAccelRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onAccelAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onGyroRaw(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onGyroAutocal(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onQuaternionMagAccel(_ service: LogService, log: QuaternionLog, appDate: Date) {
        printWarning()
    }
    func onQuaternion9Axis(_ service: LogService, log: QuaternionLog, appDate: Date) {
        printWarning()
    }
    func onLinearAccel(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onGyroBias(_ service: LogService, log: SensorLog, appDate: Date) {
        printWarning()
    }
    func onTemperature(_ service: LogService, log: TemperatureLog, appDate: Date) {
        printWarning()
    }
    func onTimestampFull(_ service: LogService, log: TimestampFullLog, appDate: Date) {
        printWarning()
    }
    func onPressure(_ service: LogService, log: PressureLog, appDate: Date) {
        printWarning()
    }
}
