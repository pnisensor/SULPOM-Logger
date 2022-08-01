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

/// Table view cell used to display a device scanned. Shows its Id, mcu host firmware version, and current RSSI.
class DeviceCell: UITableViewCell {
    // MARK: Constants
    public static let IDENTIFIER: String = "DeviceCell";
    
    // MARK: UI Elements
    @IBOutlet private weak var rssi_label     : UILabel!;
    @IBOutlet private weak var sensor_id_label: UILabel!;
    @IBOutlet weak var version_label: UILabel!
    @IBOutlet weak var batteryView: BatteryView!
    @IBOutlet weak var reconnect_label: UILabel!
    @IBOutlet weak var reconnect_indicator: UIActivityIndicatorView!
    
    
    // MARK: Methods

    /// Method that will set up the cell with the sensor information. If carPresence is defined, then
    /// this will be used instead of the MCU Host version string.
    /// - Parameter device: Discovred device to display in the cell
    public func setCell(device: Device, isConnected: Bool) {
        if (device.rssi == 127) {
            // Specific error code that indicates the RSSI was not available
            rssi_label.text = "???";
        } else {
            rssi_label.text = String(format: "%.5g", device.rssi);
        }
        
        sensor_id_label.text = device.id;
        version_label.text = device.firmware.name;
        
        if (isConnected) {
            switch (device.state) {
            case .CONNECTED:
                reconnect_label.isHidden = true;
                reconnect_indicator.stopAnimating()
                if (isConnected && device.firmware.typeId.isSulpom()) {
                    batteryView.isHidden = false;
                    batteryView.level = device.factoryService.lastBatteryLevel;
                } else {
                    batteryView.isHidden = true;
                }
            case .DISCONNECTED:
                reconnect_label.isHidden = false;
                reconnect_label.text = "Disconnected";
                reconnect_indicator.stopAnimating()
                rssi_label.text = "N/A";
            case .RECONNECTING:
                reconnect_label.isHidden = false;
                reconnect_label.text = "Reconnecting..."
                reconnect_indicator.startAnimating()
                batteryView.isHidden = true;
            }
        } else {
            reconnect_label.isHidden = true;
            batteryView.isHidden = true;
        }
    }
}
