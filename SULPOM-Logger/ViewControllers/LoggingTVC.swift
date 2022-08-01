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
import CoreBluetooth

class LoggingTVC: PniTableViewController, PniCentralManagerDelegate, DeviceDelegate, NstStreamingDelegate {
    private enum Sections {
        static let settings: Int = 0;
        static let start: Int = 1;
        static let export: Int = 2;
    }
    
    private enum IndexPaths {
        static let rate = IndexPath(row: 0, section: Sections.settings)
        static let enabledLogs = IndexPath(row: 1, section: Sections.settings);
    }
    
    // MARK: UI Elements
    @IBOutlet weak var rate_label: UILabel!
    @IBOutlet weak var rate_label_trailing: NSLayoutConstraint!
    @IBOutlet weak var rate_cell: UITableViewCell!
    @IBOutlet weak var selected_label: UILabel!
    @IBOutlet weak var selected_label_trailing: NSLayoutConstraint!
    @IBOutlet weak var selected_cell: UITableViewCell!
    @IBOutlet weak var count_label: UILabel!
    @IBOutlet weak var start_label: UILabel!
    @IBOutlet weak var export_label: UILabel!
    @IBOutlet weak var export_indicator: UIActivityIndicatorView!
    
    
    // MARK: Memeber Variables
    var currentExportFile: TemporaryFile?
    private var reconnectDevices = Devices();
    private lazy var reconnectAlert = ActivityIndicatorAlert(title: "Reconnecting", message: "Please Wait...", presentor: self) { [weak self] in
        guard let self = self else { return }
        for device in self.reconnectDevices {
            if (device.state != .CONNECTED) {
                device.cancelReconnection();
            }
        }
        self.reconnectDevices.removeAll();
    }
    private var isShowingDisconnected = false;
    private lazy var nstFileUpload = NstFileUploader()
    private lazy var uploadProgress = ProgressAlert(title: "Nstrumenta Upload", message: "Please Wait...",
                                                    presentor: self, includeCancel: false);
    private var checkCount = false;

    
    // MARK: Methods
    

    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        tableView.tableFooterView = UIView();
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        count_label.text = "";
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        NstStreaming.shared.delegate = self;
        start_label.isEnabled = false;
        for device in ConnectedDevices.shared {
            device.delegate = self;
            if (!start_label.isEnabled && device.state == .CONNECTED) {
                start_label.isEnabled = true;
            }
        }
        PniCentralManager.shared.delegate = self;
        
        rate_label.text = "\(ConnectedDevices.shared.rate) Hz";
        selected_label.text = "\(ConnectedDevices.shared.enabledList.count) Selected";
        
        let streaming = ConnectedDevices.shared.nstStreaming;
        if (streaming.isEnabled && streaming.autoConnect && NstStreaming.shared.state == .DISCONNECTED) {
            guard (!streaming.apiKey.isEmpty) else { return; }
            guard let url = URL(string: streaming.url) else { return; }
            NstStreaming.shared.connect(wsUrl: url, apiKey: streaming.apiKey);
        }
    }

    deinit {
        PniLogs.logViewRemoved(title: title, className: "\(Self.self)");
    }
    
    private func startLogging() {
        count_label.text = "0"
        currentExportFile = nil;
        ConnectedDevices.shared.startLogging();
        export_label.isEnabled = false;
        rate_cell.accessoryType = .none;
        selected_cell.accessoryType = .none;
        rate_label_trailing.constant = 16;
        selected_label_trailing.constant = 16;
        start_label.text = "Stop Logging";
        
        checkCount = true;
        updateCountLoop();
    }
    
    private func stopLogging() {
        checkCount = false;
        ConnectedDevices.shared.stopLogging();
        export_label.isEnabled = true;
        rate_cell.accessoryType = .disclosureIndicator;
        selected_cell.accessoryType = .disclosureIndicator;
        rate_label_trailing.constant = 0;
        selected_label_trailing.constant = 0;
        start_label.text = "Start Logging";
        
        count_label.text = String(describing: ConnectedDevices.shared.logCount)
    }
    
    private func export() {
        export_label.isEnabled = false;
        start_label.isEnabled = false;
        
        if let currentExportFile = currentExportFile {
            self.checkIfUploadIsNeeded(url: currentExportFile.url);
        } else {
            export_indicator.startAnimating()
            ConnectedDevices.shared.exportLog { [weak self] (err, file) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.export_indicator.stopAnimating()
                    if let err = err {
                        self.showAlert(title: "Error", message: "Failed to encode JSON: \(err)");
                        self.export_label.isEnabled = true;
                        self.start_label.isEnabled = true;
                        return;
                    }
                    guard let file = file else { return; }
                    self.currentExportFile = file;
                    self.checkIfUploadIsNeeded(url: file.url);
                }
            }
        }
    }
    
    private func checkIfUploadIsNeeded(url: URL) {
        if (ConnectedDevices.shared.nstUpload.isEnabled) {
            let title = "Nstrumenta Upload"
            let msg = "Would you like to upload to Nstrumenta?"
            
            let alert: UIAlertController = UIAlertController(title: title, message: msg, preferredStyle: .alert);
            let actionHandler = { [weak self] (action: UIAlertAction) in
                guard let self = self else { return }
                if (action.style == .cancel) {
                    self.presentFile(url: url);
                } else {
                    self.nstFileUpload.apiKey = ConnectedDevices.shared.nstUpload.apiKey;
                    self.nstFileUpload.onProgress = { [weak self] (progress) in
                        self?.uploadProgress.setProgress(to: progress)
                    }
                    self.nstFileUpload.onStart = { [weak self] (start) in
                        self?.uploadProgress.setMessage(text: "Uploading \(start)\nPlease Wait...");
                        self?.uploadProgress.setProgress(to: 0)
                        self?.uploadProgress.display()
                    }
                    self.upload(url: url);
                }
            }
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: actionHandler));
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: actionHandler));
            present(alert, animated: true);
        } else {
            presentFile(url: url);
        }
    }
    
    private func upload(url: URL) {
        nstFileUpload.onError = { [weak self] (msg) in
            self?.uploadProgress.dismiss { [weak self] in
                print(msg);
                self?.showAlert(title: "Upload Error", message: msg);
            }
        }
        nstFileUpload.onSuccess = { [weak self] _ in
            self?.uploadProgress.dismiss { [weak self] in
                self?.showAlert(title: "Success", message: "The file was uploaded.") { [weak self] _ in
                    self?.presentFile(url: url)
                }
            }
        }
        nstFileUpload.uploadFiles(urls: [url])
    }
    
    private func presentFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil);
        self.present(activityVC, animated: true) { [weak self] in
            self?.export_label.isEnabled = true;
            self?.start_label.isEnabled = true;
        }
    }
    
    private func updateCountLoop() {
        count_label.text = String(describing: ConnectedDevices.shared.logCount)
        if (checkCount) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.updateCountLoop();
            }
        }
    }
    
    
    // MARK: DeviceDelegate
    
    
    func onError(_ device: Device, error: Error, type: PniPeripheral.ErrorType) {
        // TODO...
    }
    
    func onReadRSSI(_ device: Device, rssi: Float) { }
    
    func onReconnecting(_ device: Device) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return; }
            self.reconnectDevices.append(device: device);
            var msg = "Attempting to reconnect to: [\(self.reconnectDevices.map { $0.id }.joined(separator: ", "))]";
            msg += "\nPlease Wait...";
            
            self.reconnectAlert.setMessage(text: msg);
            self.reconnectAlert.display();
        }
    }
    
    func onReconnected(_ device: Device) {
        device.logService.start(); // Services need to be rediscovered.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return; }
            self.reconnectDevices.remove(id: device.id);
            if (self.reconnectDevices.isEmpty) {
                self.reconnectAlert.dismiss();
            } else {
                var msg = "Attempting to reconnect to: [\(self.reconnectDevices.map { $0.id }.joined(separator: ", "))]";
                msg += "\nPlease Wait...";
                
                self.reconnectAlert.setMessage(text: msg);
                self.reconnectAlert.display();
            }
        }
    }
    
    func onDisconnected(_ device: Device) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reconnectDevices.remove(id: device.id);
            self.isShowingDisconnected = true;
            let msg = "Try scanning for the device(s) again."
            self.showAlert(title: "Device(s) Disconnected", message: msg) { [weak self] _ in
                self?.isShowingDisconnected = false;
            }
            
            var containsConnected = false;
            for device in ConnectedDevices.shared {
                if (device.state == .CONNECTED) {
                    containsConnected = true;
                    break;
                }
            }
            if (!containsConnected) {
                self.stopLogging();
                self.start_label.isEnabled = false;
                self.tableView.updateTableView()
            }
        }
    }
    
    
    // MARK: PniCentralManagerDelegate
    
    
    func onStateUpdated(_ centralManager: PniCentralManager, state: CBManagerState) {
        for device in ConnectedDevices.shared {
            device.onStateUpdated(centralManager, state: state);
        }
    }
    
    func onDiscovered(peripheral: PniPeripheral, name: String?, manufacturerData: [UInt8]?, rssi: Float) { }
    
    func onConnected(toPeripheral peripheral: PniPeripheral) {
        for device in ConnectedDevices.shared {
            if (device.peripheral.identifier == peripheral.identifier) {
                device.onConnected(toPeripheral: peripheral);
                break;
            }
        }
    }
    
    func onConnectionFailed(toPeripheral peripheral: PniPeripheral) {
        for device in ConnectedDevices.shared {
            if (device.peripheral.identifier == peripheral.identifier) {
                device.onConnectionFailed(toPeripheral: peripheral)
                break;
            }
        }
    }
    
    func onDisconnected(fromPeripheral peripheral: PniPeripheral, error: Error?) {
        for device in ConnectedDevices.shared {
            if (device.peripheral.identifier == peripheral.identifier) {
                device.onDisconnected(fromPeripheral: peripheral, error: error);
            }
        }
    }
    
    
    // MARK: UITableView overrides
    
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch (indexPath.section) {
        case Sections.settings:
            if (!ConnectedDevices.shared.isLogging) {
                return true;
            }
        case Sections.start:
            if (start_label.isEnabled) {
                return true;
            }
        case Sections.export:
            if (!ConnectedDevices.shared.isLogging && export_label.isEnabled) {
                return true;
            }
        default:
            break;
        }
        return false;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section) {
        case Sections.settings:
            if (!ConnectedDevices.shared.isLogging) {
                tableView.deselectRow(at: indexPath, animated: true);
                if (indexPath.row == IndexPaths.rate.row) {
                    performSegue(withIdentifier: "to_LogRateTVC", sender: nil);
                    return;
                } else if (indexPath.row == IndexPaths.enabledLogs.row) {
                    performSegue(withIdentifier: "to_EnabledLogsTVC", sender: nil);
                }
            }
        case Sections.start:
            if (start_label.isEnabled) {
                tableView.deselectRow(at: indexPath, animated: true);
                if (ConnectedDevices.shared.isLogging) {
                    stopLogging()
                } else {
                    startLogging()
                }
                tableView.updateTableView();
            }
        case Sections.export:
            if (!ConnectedDevices.shared.isLogging && export_label.isEnabled) {
                tableView.deselectRow(at: indexPath, animated: true);
                export();
            }
        default:
            print("Unhandled index path selected: \(indexPath)");
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == Sections.export && !export_label.isEnabled && !export_indicator.isAnimating) {
            return Sizes.TableViewRow.hidden;
        }
        return super.tableView(tableView, heightForRowAt: indexPath);
    }
    
    
    // MARK: NstStreamingDelegate
    
    func onNstStatusChanged(state: NstStreaming.State, visibility: Bool, error: String?) {
        if (state == .CONNECTED) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                UIHelpers.showLabel(text: "Nstrumenta Connected", vc: UIViewController.topMostViewController() ?? self);
            }
        } else if (state == .DISCONNECTED) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                UIHelpers.showLabel(text: "Nstrumenta Disconnected", vc: UIViewController.topMostViewController() ?? self);
            }
        }
    }
    
    func onNstMessage(channel: String, dict: [String : Any]) { }
}
