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

class FakeFactoryService {
    let SERVICE_UUID: CBUUID;
    let CHAR_UUID: CBUUID;
    
    private weak var fakePeripheral: Fake_DevicePeripheral?;
    
    private typealias Commands = FactoryService.Commands
    private typealias BatteryInfoIds = FactoryService.BatteryInfoIds

    var batteryLevel: Int32 = 100;
    var isCharging = false;

    
    init(fakePeripheral: Fake_DevicePeripheral, uuids: PniUUIDs.Factory) {
        self.fakePeripheral = fakePeripheral;
        self.SERVICE_UUID = uuids.svc;
        self.CHAR_UUID = uuids.char;
    }
    
    func takeOwnership(fakePeripheral: Fake_DevicePeripheral) {
        self.fakePeripheral = fakePeripheral;
    }
    
    public func handleNotifyValue(isEnabled: Bool, characteristic: Fake_CBCharacteristic) {
        // Nothing right now.
    }
    
    public func handleWrite(characteristic: Fake_CBCharacteristic, value: [UInt8], type: CBCharacteristicWriteType) {
        let commandId: UInt8 = value[0];
        
        // This will only be partially implemented for now...
        switch (commandId) {
        case Commands.GET_BATTERY_INFO:
            getBatteryInfo(characteristic: characteristic, value: value);
        default:
            print("(Fake) Unhandled factory command: ", commandId);
        }
    }
    
    private func getBatteryInfo(characteristic: Fake_CBCharacteristic, value: [UInt8]) {
        let bytes: [UInt8];
        let batteryInfoType: UInt8 = value[1];
        switch (batteryInfoType) {
        case BatteryInfoIds.CAPACITY_PERCENT:
            bytes = [Commands.GET_BATTERY_INFO_RESP, BatteryInfoIds.CAPACITY_PERCENT] + batteryLevel.bytes;
            
            if (batteryLevel == 100) {
                isCharging = false;
            } else if (batteryLevel == 0) {
                isCharging = true;
            }
            
            if (isCharging) {
                batteryLevel += 1;
            } else {
                batteryLevel -= 1;
            }
        default:
            print("(Fake) Unhandled factory get batteryInfo: ", batteryInfoType);
            return;
        }
        
        fakePeripheral?.sendResponse(characteristic, bytes: bytes, delay: 0.05)
    }
}

#endif // IOS_SIMULATOR
