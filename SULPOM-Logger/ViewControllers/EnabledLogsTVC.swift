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


class EnabledLogsTVC: UITableViewController {
    private enum Sections {
        static let general: Int     = 0;
        static let sulpom: Int      = 1;
        static let controls: Int    = 4;
    }
    
    // MARK: Member Variables
    private class Row {
        let name: String;
        var selected: Bool;
        private let onChange: (Bool) -> Void;
        
        init(name: String, selected: Bool, onChange: @escaping (Bool) -> Void) {
            self.name = name;
            self.selected = selected;
            self.onChange = onChange;
        }
        
        func update(_ selected: Bool) {
            self.selected = selected;
            onChange(selected);
        }
    }
    
    private var rows: [Row] = [];
    private var sulpomRows: [Row] = [];

    
    // MARK: Methods
    
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        tableView.tableFooterView = UIView();
        
        rows = [
            Row(name: "Quaternion 9-Axis", selected: ConnectedDevices.shared.enabled.quaternion9axis) { v in
                ConnectedDevices.shared.enabled.quaternion9axis = v;
                AppSettings.Log.Enabled.quaternion9axis = v;
            },
            Row(name: "Quaternion Mag-Accel", selected: ConnectedDevices.shared.enabled.quaternionMagAccel) { v in
                ConnectedDevices.shared.enabled.quaternionMagAccel = v;
                AppSettings.Log.Enabled.quaternionMagAccel = v;
            },
            Row(name: "Linear Acceleration", selected: ConnectedDevices.shared.enabled.linearAccel) { v in
                ConnectedDevices.shared.enabled.linearAccel = v;
                AppSettings.Log.Enabled.linearAccel = v;
            },
            Row(name: "Gyro Bias", selected: ConnectedDevices.shared.enabled.gyroBias) { v in
                ConnectedDevices.shared.enabled.gyroBias = v;
                AppSettings.Log.Enabled.gyroBias = v;
            },
            Row(name: "Magnetometer Raw", selected: ConnectedDevices.shared.enabled.magRaw) { v in
                ConnectedDevices.shared.enabled.magRaw = v;
                AppSettings.Log.Enabled.magRaw = v;
            },
            Row(name: "Magnetometer Autocal", selected: ConnectedDevices.shared.enabled.magAutocal) { v in
                ConnectedDevices.shared.enabled.magAutocal = v;
                AppSettings.Log.Enabled.magAutocal = v;
            },
            Row(name: "Accelerometer Raw", selected: ConnectedDevices.shared.enabled.accelRaw) { v in
                ConnectedDevices.shared.enabled.accelRaw = v;
                AppSettings.Log.Enabled.accelRaw = v;
            },
            Row(name: "Accelerometer Autocal", selected: ConnectedDevices.shared.enabled.accelAutocal) { v in
                ConnectedDevices.shared.enabled.accelAutocal = v;
                AppSettings.Log.Enabled.accelAutocal = v;
            },
            Row(name: "Gyroscope Raw", selected: ConnectedDevices.shared.enabled.gyroRaw) { v in
                ConnectedDevices.shared.enabled.gyroRaw = v;
                AppSettings.Log.Enabled.gyroRaw = v;
            },
            Row(name: "Gyroscope Autocal", selected: ConnectedDevices.shared.enabled.gyroAutocal) { v in
                ConnectedDevices.shared.enabled.gyroAutocal = v;
                AppSettings.Log.Enabled.gyroAutocal = v;
            },
            Row(name: "Temperature", selected: ConnectedDevices.shared.enabled.temperature) { v in
                ConnectedDevices.shared.enabled.temperature = v;
                AppSettings.Log.Enabled.temperature = v;
            },
        ];
        
        if (ConnectedDevices.shared.includeSulpomLogs) {
            sulpomRows = [
                Row(name: "Pressure", selected: ConnectedDevices.shared.enabled.pressure) { v in
                    ConnectedDevices.shared.enabled.pressure = v;
                    AppSettings.Log.Enabled.pressure = v;
                },
            ]
        }
    }
    
    deinit {
        PniLogs.logViewRemoved(title: title, className: "\(Self.self)");
    }
    
    
    // MARK: TableView Overrides
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == Sections.general) {
            return rows.count;
        } else if (section == Sections.sulpom) {
            return sulpomRows.count;
        } else if (section == Sections.controls) {
            return 1;
        }
        return 0;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentCell: UITableViewCell;
        switch (indexPath.section) {
        case Sections.general:
            currentCell = tableView.dequeueReusableCell(withIdentifier: SelectedLogCell.IDENTIFIER, for: indexPath);
            if let currentCell = currentCell as? SelectedLogCell {
                let row = rows[indexPath.row];
                currentCell.setCell(name: row.name, selected: row.selected, onUpdate: row.update);
            }
        case Sections.sulpom:
            currentCell = tableView.dequeueReusableCell(withIdentifier: SelectedLogCell.IDENTIFIER, for: indexPath);
            if let currentCell = currentCell as? SelectedLogCell {
                let row = sulpomRows[indexPath.row];
                currentCell.setCell(name: row.name, selected: row.selected, onUpdate: row.update);
            }
        case Sections.controls:
            currentCell = UITableViewCell();
            currentCell.textLabel?.text = "Unselect All";
            if #available(iOS 13.0, *) {
                currentCell.textLabel?.textColor = .link
            } else {
                currentCell.textLabel?.textColor = UIColor(displayP3Red: 0, green: 0.478, blue: 1, alpha: 1);
            }
        default:
            currentCell = UITableViewCell();
        }
        
        return currentCell;
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == Sections.controls) {
            return true;
        }
        return false;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == Sections.controls) {
            tableView.deselectRow(at: indexPath, animated: true);
            for row in rows.enumerated() {
                if (row.element.selected) {
                    row.element.update(false);
                    if let cell = tableView.cellForRow(at: IndexPath(row: row.offset, section: Sections.general)) as? SelectedLogCell {
                        cell.selected_switch.setOn(false, animated: true);
                    }
                }
            }
            for row in sulpomRows.enumerated() {
                if (row.element.selected) {
                    row.element.update(false);
                    if let cell = tableView.cellForRow(at: IndexPath(row: row.offset, section: Sections.sulpom)) as? SelectedLogCell {
                        cell.selected_switch.setOn(false, animated: true);
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == Sections.sulpom && !ConnectedDevices.shared.includeSulpomLogs) {
            return Sizes.TableViewHeader.hiddenGrouped
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
}
