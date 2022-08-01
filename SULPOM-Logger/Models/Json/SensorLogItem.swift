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

class SensorLogItem: Encodable {
    enum TypeId: String {
        case MAG_RAW            = "MAG_RAW";
        case MAG_AUTOCAL        = "MAG_AUTOCAL";
        case ACCEL_RAW          = "ACCEL_RAW";
        case ACCEL_AUTOCAL      = "ACCEL_AUTOCAL";
        case GYRO_RAW           = "GYRO_RAW";
        case GYRO_AUTOCAL       = "GYRO_AUTOCAL";
        case Q_MAG_ACCEL        = "Q_MAG_ACCEL";
        case Q_9AXIS            = "Q_9AXIS";
        case LINEAR_ACCEL       = "LINEAR_ACCEL";
        case GYRO_BIAS          = "GYRO_BIAS";
        case TEMPERATURE        = "TEMPERATURE";
        case PRESSURE           = "PRESSURE";
        case TIMESTAMP_FULL     = "TIMESTAMP_FULL";

        case UNKNOWN            = "UNKNOWN";
        
        static func from(_ value: String) -> Self {
            return Self(rawValue: value) ?? .UNKNOWN;
        }
    }
    
    let id: String;
    let typeId: String;
    let ts: UInt32;
    let appTs: String;
    let values: [Float];
    
    init(id: String, typeId: TypeId, ts: UInt32, appDate: Date, values: [Float]) {
        self.id = id;
        self.typeId = typeId.rawValue;
        self.ts = ts;
        self.appTs = DateString.iso(date: appDate);
        self.values = values;
    }
}
