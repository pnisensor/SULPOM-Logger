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

class SelectedLogCell: UITableViewCell {
    // MARK: Constants
    public static let IDENTIFIER: String = "SelectedLogCell";
    
    // MARK: UI Elements
    @IBOutlet weak var name_label: UILabel!
    @IBOutlet weak var selected_switch: UISwitch!
    
    private var onUpdate: ((Bool) -> Void)?
    
    func setCell(name: String, selected: Bool, onUpdate: @escaping (Bool) -> Void) {
        name_label.text = name;
        selected_switch.isOn = selected;
        self.onUpdate = onUpdate
    }
    
    // MARK: UI Methods
    
    @IBAction func select_switch_updated(_ sender: UISwitch) {
        onUpdate?(sender.isOn);
    }
}
