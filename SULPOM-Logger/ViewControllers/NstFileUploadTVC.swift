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

class NstFileUploadTVC: PniTableViewController {
    private enum Sections {
        static let enabled  = 0;
        static let settings = 1;
    }
    
    // MARK: UI Elements
    @IBOutlet weak var enabled_switch: UISwitch!
    @IBOutlet weak var apiKey_textField: PniTextField!
    
    // MARK: Member Variables
    private let settings = ConnectedDevices.shared.nstUpload;
    private var footerLabel: UILabel?
    
    
    // MARK: Methods
    
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        tableView.tableFooterView = UIView();
        
        apiKey_textField.addDoneButton()
        
        enabled_switch.isOn = settings.isEnabled;
        apiKey_textField.text = settings.apiKey;
    }
    
    private func createFooterLabel() -> UILabel {
        let paddingLeft: CGFloat = 20;
        let paddingRight: CGFloat = 60;
        let label: UILabel = UILabel(frame: CGRect(x: paddingLeft, y: 0, width: tableView.bounds.width - paddingRight, height: 0));
        
        let msg = "Enabling this will make the app attempt to upload the JSON Log to Nstrumenta when Export is tapped.";
        
        label.text = msg;
        label.textColor = .darkGray;
        label.numberOfLines = 0;
        label.textAlignment = .left;
        label.lineBreakMode = .byWordWrapping;
        label.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(13);
        label.autoresizingMask = [.flexibleHeight];
        
        return label;
    }
    
    
    // MARK: UI Methods
    
    
    @IBAction func enabled_switch_updated(_ sender: UISwitch) {
        settings.isEnabled = sender.isOn;
        AppSettings.Log.NstUpload.isEnabled = settings.isEnabled;
        tableView.updateTableView();
    }
    
    @IBAction func apiKey_textField_editingEnded(_ sender: PniTextField) {
        settings.apiKey = sender.text ?? ""
        AppSettings.Log.NstUpload.apiKey = settings.apiKey;
    }
    
    
    // MARK: TableView Overrides
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section > 0 && !settings.isEnabled) {
            return Sizes.TableViewHeader.hiddenGrouped
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false;
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section > 0 && !settings.isEnabled) {
            return Sizes.TableViewRow.hidden;
        }
        return super.tableView(tableView, heightForRowAt: indexPath);
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == tableView.numberOfSections - 1) {
            let size: CGSize;
            if let label = footerLabel {
                let paddingRight: CGFloat = 60;
                size = label.sizeThatFits(CGSize(width: tableView.bounds.width - paddingRight, height: .greatestFiniteMagnitude));
            } else {
                let label = createFooterLabel();
                footerLabel = label;
                size = label.sizeThatFits(CGSize(width: tableView.bounds.width, height: .greatestFiniteMagnitude));
            }
            let padding: CGFloat = 20.0;
            return size.height + padding;
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if (section == tableView.numberOfSections - 1) {
            let headerView = UITableViewHeaderFooterView();
            
            if let label = footerLabel {
                headerView.addSubview(label);
            } else {
                let label = createFooterLabel();
                footerLabel = label;
                headerView.addSubview(label);
            }
            return headerView;
        }
        return super.tableView(tableView, viewForFooterInSection: section)
    }
}
