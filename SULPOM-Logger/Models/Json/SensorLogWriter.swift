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

// TODO: either use this in write json or get rid of it...
fileprivate let serialQueue: DispatchQueue = DispatchQueue(label: "com.pnisensor.serial-log-json-queue");

typealias SensorLogWriterCb = (_ err: Error?, _ file: TemporaryFile?) -> Void;

class SensorLogWriter {
    static let encoder = JSONEncoder();

    public func writeJson(date: Date, items: [SensorLogItem], headers: SensorLogHeaders, cb: @escaping SensorLogWriterCb) {
        serialQueue.async {
            let dateStr = DateString.filename(date: date);
            
            let filename: String = "Sensor_Log_\(dateStr)";
            let tmpFile = TemporaryFile(encoding: .utf8, name: "\(filename).json");
            
            
            let data: Data
            do {
                data = try Self.encoder.encode(SensorLogJson(headers: headers, data: items));
            } catch let error {
                cb(error, nil);
                return;
            }
            _ = tmpFile.write(data: data);
            cb(nil, tmpFile);
        }
    }
}
