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

class LogRateTVC: UITableViewController {
    let rates: [UInt8] = {
        var values: [UInt8] = [0x01];
        var index: UInt = 5;
        while index < 201 {
            values.append(UInt8(index));
            index += 5;
        }
        return values;
    }();
    
    private var rows: [(rate: UInt8, selected: Bool)] = [];
    private var firstScroll: Bool = true
    
    // MARK: Methods
    
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        tableView.tableFooterView = UIView();
        
        for rate in rates.enumerated() {
            let selected = (rate.element == ConnectedDevices.shared.rate);
            rows.append((rate: rate.element, selected: selected));
        }
    }
    
    deinit {
        PniLogs.logViewRemoved(title: title, className: "\(Self.self)");
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        for row in rows.enumerated() {
            if (firstScroll && row.element.rate == ConnectedDevices.shared.rate) {
                firstScroll = false;
                tableView.scrollToRow(at: IndexPath(row: row.offset, section: 0), at: .middle, animated: false);
            }
        }
    }
    
    
    // MARK: TableView Overrides
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return rows.count;
        }
        return 0;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "LogRateCell", for: indexPath);
        
        let currentRow = rows[indexPath.row];
        currentCell.textLabel?.text = "\(currentRow.rate) Hz";
        currentCell.accessoryType = currentRow.selected ? .checkmark : .none;
        return currentCell;
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        for i in 0 ..< rows.count {
            if (i == indexPath.row) {
                if (rows[i].rate == ConnectedDevices.shared.rate) {
                    return false;
                }
                return true;
            }
        }
        return true;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);

        for i in 0 ..< rows.count {
            if (i == indexPath.row) {
                rows[i].selected = true;
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark;
                ConnectedDevices.shared.rate = rows[i].rate;
                AppSettings.Log.rate = ConnectedDevices.shared.rate;
            } else if (rows[i].selected) {
                rows[i].selected = false;
                tableView.cellForRow(at: IndexPath(row: i, section: indexPath.section))?.accessoryType = .none;
            }
        }
    }
}
