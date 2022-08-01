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

class LoggingSensorsTVC: PniTableViewController, NstStreamingDelegate {
    private enum Rows {
        static let nstStreaming: Int = 0;
        static let nstFileUpload: Int = 1;
    }
    
    // MARK: UI Elements
    @IBOutlet weak var nstStream_label: UILabel!
    @IBOutlet weak var nstUpload_label: UILabel!
    
    
    // MARK: Methods
    
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        tableView.tableFooterView = UIView();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        NstStreaming.shared.delegate = self;
        updateNstStreamLabel()
        nstUpload_label.text = (ConnectedDevices.shared.nstUpload.isEnabled) ? "Enabled" : "Disabled";
    }
    
    deinit {
        PniLogs.logViewRemoved(title: title, className: "\(Self.self)");
    }
    
    private func updateNstStreamLabel() {
        let str: String;
        if (ConnectedDevices.shared.nstStreaming.isEnabled) {
            switch (NstStreaming.shared.state) {
            case .DISCONNECTED:
                str = "Disconnected"
            case .CONNECTING:
                str = "Connecting"
            case .CONNECTED:
                str = "Connected"
            case .DISCONNECTING:
                str = "Disconnecting"
            }
        } else {
            str = "Disabled";
        }
        nstStream_label.text = str;
    }
    
    
    // MARK: UITableViewDataSource
    
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        
        if (indexPath.row == Rows.nstStreaming) {
            performSegue(withIdentifier: "to_NstStreamingTVC", sender: nil);
        } else if (indexPath.row == Rows.nstFileUpload) {
            performSegue(withIdentifier: "to_NstFileUploadTVC", sender: nil);
        } else {
            print("Unhandled row tap: ", indexPath)
        }
    }
    
    
    // MARK: NstStreamingDelegate
    
    func onNstStatusChanged(state: NstStreaming.State, visibility: Bool, error: String?) {
        DispatchQueue.main.async { [weak self] in
             guard let self = self else { return }
             self.updateNstStreamLabel()
             
             if (state == .CONNECTED) {
                 UIHelpers.showLabel(text: "Nstrumenta Connected", vc: UIViewController.topMostViewController() ?? self);
             } else if (state == .DISCONNECTED) {
                 UIHelpers.showLabel(text: "Nstrumenta Disconnected", vc: UIViewController.topMostViewController() ?? self);
             }
        }
    }
    
    func onNstMessage(channel: String, dict: [String : Any]) { }
}
