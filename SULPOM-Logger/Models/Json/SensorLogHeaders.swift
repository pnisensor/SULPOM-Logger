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

class SensorLogHeaders: Encodable {
    struct Sensor: Encodable {
        var firmware: String;
        var serialNumber: String;
    }
    
    let appVersion: String;
    let deviceModel: String;
    let deviceName: String;
    let osVersion: String;
    let sensors: [Sensor];
    let appTs: String;
    
    init(sensors: [Sensor], appDate: Date) {
        self.appVersion = AppSettings.versionString;
        self.deviceModel = UIDevice.Model.current.description;
        self.deviceName = UIDevice.current.name;
        self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString;
        self.sensors = sensors;
        self.appTs = DateString.iso(date: appDate);
    }
}
