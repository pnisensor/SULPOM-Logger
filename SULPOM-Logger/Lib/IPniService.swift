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

/// Objects that conform to this protocol can be registered by a PniPeripheral to receive
/// service and characteristic updates.
protocol IPniService: AnyObject {
    /// The uuid of the CBService which is wrapped.
    var uuid: CBUUID { get }
    
    /// Handles data output from the wrapped service.
    /// - Parameters:
    ///   - characteristic: The charactertic the data is from.
    ///   - bytes: The output bytes.
    func handleData(fromCharacteristic characteristic: CBCharacteristic, bytes: [UInt8])
    
    /// Handles discovery of the raw CBService.
    /// - Parameter service: The discovered service.
    func handleServiceDiscovered(service: CBService)
    
    /// Handles discovery of the CBCharacteristics. These will be from the wrapped CBService.
    /// - Parameter characteristics: The discovered characteristics.
    func handleCharacteristicsDiscovered(characteristics: [CBCharacteristic])
    
    /// Handles the notification state of a characteristic.
    /// - Parameter characteristic: The changed characteristic.
    func handleSetNotifyValue(forCharacteristic characteristic: CBCharacteristic)
}
