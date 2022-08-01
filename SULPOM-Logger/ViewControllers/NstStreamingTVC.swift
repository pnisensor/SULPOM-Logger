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

class NstStreamingTVC: PniTableViewController, NstStreamingDelegate {
    private enum Sections {
        static let enabled  = 0;
        static let settings = 1;
        static let connect  = 2;
    }
    
    // MARK: UI Elements
    @IBOutlet weak var enabled_switch: UISwitch!
    @IBOutlet weak var url_textField: PniTextField!
    @IBOutlet weak var apiKey_textField: PniTextField!
    @IBOutlet weak var autoConnect_switch: UISwitch!
    @IBOutlet weak var connect_label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    
    // MARK: Member Variables
    private var footerLabel: UILabel?
    private let settings = ConnectedDevices.shared.nstStreaming;
    private let client = NstStreaming.shared
    

    // MARK: Methods

    
    override public func viewDidLoad() {
        super.viewDidLoad();
        
        client.delegate = self;
        
        for textField in [url_textField, apiKey_textField] {
            textField?.addDoneButton()
        }
        
        enabled_switch.isOn = settings.isEnabled
        url_textField.text = settings.url;
        apiKey_textField.text = settings.apiKey;
        autoConnect_switch.isOn = settings.autoConnect;
        updateNstStateUI()
    }
    
    func updateNstStateUI() {
        switch (client.state) {
            
        case .DISCONNECTED:
            connect_label.text = "Connect";
            connect_label.isEnabled = !settings.url.isEmpty && !settings.apiKey.isEmpty;
            if (indicator.isAnimating) {
                indicator.stopAnimating();
            }
        case .CONNECTING:
            connect_label.text = "Connecting...";
            connect_label.isEnabled = false;
            indicator.startAnimating();
        case .CONNECTED:
            connect_label.text = "Disconnect";
            connect_label.isEnabled = true;
            if (indicator.isAnimating) {
                indicator.stopAnimating();
            }
        case .DISCONNECTING:
            connect_label.text = "Disconnecting...";
            connect_label.isEnabled = false;
            indicator.startAnimating();
        }
    }
    
    private func createFooterLabel() -> UILabel {
        let paddingLeft: CGFloat = 20;
        let paddingRight: CGFloat = 60;
        let label: UILabel = UILabel(frame: CGRect(x: paddingLeft, y: 0, width: tableView.bounds.width - paddingRight, height: 0));
        
        let msg = "Logs will be live streamed over the Nstrumenta WebSocket while this feature is enabled and connected.";
        
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
        AppSettings.Log.NstStreaming.isEnabled = settings.isEnabled;
        tableView.updateTableView();
    }
    
    @IBAction func url_textField_editingEnded(_ sender: PniTextField) {
        settings.url = sender.text ?? "";
        AppSettings.Log.NstStreaming.url = settings.url;
        updateNstStateUI()
    }
    
    @IBAction func apiKey_textField_editingEnded(_ sender: PniTextField) {
        settings.apiKey = sender.text ?? ""
        AppSettings.Log.NstStreaming.apiKey = settings.apiKey;
        updateNstStateUI()
    }
    
    @IBAction func autoConnect_switch_updated(_ sender: UISwitch) {
        settings.autoConnect = sender.isOn;
        AppSettings.Log.NstStreaming.autoConnect = settings.autoConnect;
    }
    
    
    // MARK: UITableViewDataSource
    
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == Sections.connect && connect_label.isEnabled) {
            return true;
        }
        return false;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        
        if (indexPath.section == Sections.connect && connect_label.isEnabled) {
            if (client.state == .DISCONNECTED) {
                guard (!settings.apiKey.isEmpty) else {
                    showAlert(title: "Error", message: "API Key field must be provided.")
                    return;
                }
                guard let url = URL(string: settings.url) else {
                    showAlert(title: "Error", message: "URL field must be provided and a valid url.")
                    return;
                }
                client.connect(wsUrl: url, apiKey: settings.apiKey);
            } else if (client.state == .CONNECTED) {
                client.disconnect();
            }
        }
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
    
    
    // MARK: NstStreamingDelegate
    
    
    func onNstStatusChanged(state: NstStreaming.State, visibility: Bool, error: String?) {
        DispatchQueue.main.async { [weak self] in
            if let msg = error {
                self?.showAlert(title: "Nstrumenta Error", message: msg);
            }
            self?.updateNstStateUI()
        }
    }
    
    func onNstMessage(channel: String, dict: [String : Any]) { }
}
