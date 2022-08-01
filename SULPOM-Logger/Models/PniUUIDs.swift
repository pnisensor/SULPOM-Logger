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

/// Container for BLE service and characteristic uuid values.
class PniUUIDs {
    let eos: Eos
    let upgrade: Upgrade;
    let log: Log;
    let cal: Calibration;
    let factory: Factory;
    
    let protocolVeraion: ProtocalVersion;
    
    enum ProtocalVersion {
        case R01;
        case R02;
        case R03;
        case R04;
    }
    
    struct Eos {
        let svc: CBUUID
        let q: CBUUID
        let la: CBUUID
        let tare: CBUUID
    }
    
    struct Upgrade {
        let svc: CBUUID;
        let write: CBUUID;
        let notify: CBUUID;
    }
    
    struct Log {
        let svc: CBUUID;
        let char: CBUUID;
    }
    
    struct Calibration {
        let svc: CBUUID;
        let start: CBUUID;
        let sample: CBUUID;
        let read: CBUUID;
        let reset: CBUUID;
    }
    
    struct Factory {
        let svc: CBUUID;
        let char: CBUUID;
    }
    
    init(version: ProtocalVersion) {
        self.protocolVeraion = version;
        switch (version) {
        case .R01:
            eos = Eos(
                svc: CBUUID(string: "c00f357c-eb93-11e9-81b4-2a2ae2dbcce4"),
                q: CBUUID(string: "c00f3806-eb93-11e9-81b4-2a2ae2dbcce4"),
                la: CBUUID(string: "c00f4328-eb93-11e9-81b4-2a2ae2dbcce4"),
                tare: CBUUID(string: "35059b6c-1530-11ea-8d71-362b9e155667"))
            upgrade = Upgrade(
                svc: CBUUID(string: "c00f3bb2-eb93-11e9-81b4-2a2ae2dbcce4"),
                write: CBUUID(string: "c00f3cde-eb93-11e9-81b4-2a2ae2dbcce4"),
                notify: CBUUID(string: "c00f4094-eb93-11e9-81b4-2a2ae2dbcce4"));
            log = Log(
                svc: CBUUID(string: "c00f3950-eb93-11e9-81b4-2a2ae2dbcce4"),
                char: CBUUID(string: "c00f3a86-eb93-11e9-81b4-2a2ae2dbcce4"));
            cal = Calibration(
                svc: CBUUID(string: "b6db965c-1529-11ea-8d71-362b9e155667"),
                start: CBUUID(string: "b6db9af8-1529-11ea-8d71-362b9e155667"),
                sample: CBUUID(string: "b6db9c88-1529-11ea-8d71-362b9e155667"),
                read: CBUUID(string: "b6db9dc8-1529-11ea-8d71-362b9e155667"),
                reset: CBUUID(string: "e88dae70-7824-11ea-bc55-0242ac130003"));
            factory = Factory(
                svc: CBUUID(string: "32f6dee0-0f99-11ea-8d71-362b9e155667"),
                char: CBUUID(string: "32f6e1e2-0f99-11ea-8d71-362b9e155667"));
        case .R02, .R03, .R04:
            let base: String            = "11ea-8d71-362b9e155667";
            let logId: String           = "0001";
            let upgradeId: String       = "0002";
            let calId: String           = "0003";
            let factoryId: String       = "0004";
            let eosId: String           = "0005";
            
            eos = Eos(
                svc: CBUUID(string: "00000000-\(eosId)-\(base)"),
                q: CBUUID(string: "00000001-\(eosId)-\(base)"),
                la: CBUUID(string: "00000002-\(eosId)-\(base)"),
                tare: CBUUID(string: "00000003-\(eosId)-\(base)"));
            upgrade = Upgrade(
                svc: CBUUID(string: "00000000-\(upgradeId)-\(base)"),
                write: CBUUID(string: "00000001-\(upgradeId)-\(base)"),
                notify: CBUUID(string: "00000002-\(upgradeId)-\(base)"));
            log = Log(
                svc: CBUUID(string: "00000000-\(logId)-\(base)"),
                char: CBUUID(string: "00000001-\(logId)-\(base)"));
            cal = Calibration(
                svc: CBUUID(string: "00000000-\(calId)-\(base)"),
                start: CBUUID(string: "00000001-\(calId)-\(base)"),
                sample: CBUUID(string: "00000002-\(calId)-\(base)"),
                read: CBUUID(string: "00000003-\(calId)-\(base)"),
                reset: CBUUID(string: "00000004-\(calId)-\(base)"));
            factory = Factory(
                svc: CBUUID(string: "00000000-\(factoryId)-\(base)"),
                char: CBUUID(string: "00000001-\(factoryId)-\(base)"));
        }
    }
}
