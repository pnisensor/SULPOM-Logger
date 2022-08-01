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
import os.log
import CoreBluetooth.CBManager

class BleScanVC: PniViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
                 PniCentralManagerDelegate, DeviceDelegate {
    // MARK: Constants
    private let SECONDS_TO_WAIT: Double = 10;
    private enum Segues: String {
        case SERVICES = "to_ServicesVC";
    }
    private enum Sections {
        static let CONNECTED = 0;
        static let AVAILABLE = 1;
    }
    
    // MARK: UI Elements
    @IBOutlet private weak var device_tableView: UITableView!;
    @IBOutlet private weak var scan_button: PniButton!;
    @IBOutlet weak var id_searchBar: PniSearchBar!

    // MARK: Member variables

    private lazy var centralManager: PniCentralManager = PniCentralManager.shared;
    
    /// Discovered devices.
    private let devices: Devices = Devices();
    
    /// Device selected from the table view that we wish to connect to.
    private var selectedDevice: Device?;
    
    private var isScanning: Bool = false;
    private var searchText: String = "";
    
    private lazy var connectAlert = ActivityIndicatorAlert(title: "Connecting", message: "Please Wait...", presentor: self) { [weak self] in
        self?.cancelConnection();
    }
    
    /// Contains function block to be executed if the central takes too long to connect to the peripheral.
    private var connectTimeout: DispatchWorkItem?;
    private var hasShownBleOffError: Bool = false;
    private var isShowingBleOff = false;
    

    // MARK: Methods
    
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        PniLogs.logViewLoaded(title: title, className: "\(Self.self)");
        
        updateTabBarUI(enabled: false)
        id_searchBar.addDoneButton();
        id_searchBar.delegate = self;
        
        devices.sortByRssi = true;
        
        device_tableView.delegate = self;
        device_tableView.dataSource = self;
        
        device_tableView.layer.borderWidth = 0.7;
        device_tableView.layer.borderColor = UIColor.gray.cgColor;
        device_tableView.layer.cornerRadius = 2;
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        centralManager.delegate = self;
        scan_button.isEnabled = true;
        
        var disconnectedDevices: [Device] = [];
        for item in ConnectedDevices.shared.enumerated().reversed() {
            item.element.delegate = self;
            if (item.element.state == .DISCONNECTED) {
                disconnectedDevices.append(item.element);
            } else {
                updateConnectedCellUI(device: item.element, idx: item.offset);
            }
        }
        for device in disconnectedDevices {
            disconnectUI(device: device);
        }
        
        device_tableView.isUserInteractionEnabled = true;
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        stopScan();
        
        // Clear this out since we don't know what will be there when we come back.
        selectedDevice = nil;
        devices.removeAll();
        device_tableView.reloadSections([Sections.AVAILABLE], with: .automatic)

        super.viewWillDisappear(animated);
    }
    
    deinit {
        PniLogs.logViewRemoved(title: title, className: "\(Self.self)");
    }
    
    /// Change how the "scan" button looks depending on if its enabled or not.
    /// - Parameter enabled: **true** for red button "Stop Scanning", **false** for green button "Start Scanning"
    private func updateScanButtonUI(isScanning: Bool) {
        if (isScanning) {
            scan_button.setTitle("Stop Scan", for: .normal);
            scan_button.setColor(color: .red);
        } else {
            scan_button.setTitle("Start Scan", for: .normal);
            scan_button.setColor(color: .green);
        }
    }

    /// Start scanning for available peripherals.
    private func startScan() {
        guard (checkState()) else { return }
        
        isScanning = true;
        updateScanButtonUI(isScanning: true);
        
        // Clear prior scan results.
        devices.removeAll();
        UIView.performWithoutAnimation { [weak self] in
            // https://stackoverflow.com/a/32896400/8406615
            self?.device_tableView.reloadSections([Sections.AVAILABLE], with: .none)
        }
        
        centralManager.startScan(withServices: []);
    }
    
    /// Stop scanning for available peripherals.
    private func stopScan() {
        let wasScanning: Bool = isScanning;
        isScanning = false;
        
        connectTimeout?.cancel();
        connectTimeout = nil;
        
        connectAlert.dismiss();

        updateScanButtonUI(isScanning: false);
        if (wasScanning) {
            centralManager.stopScan();
        }
    }
    
    /// Attempt to connect to the provided peripheral.
    private func connectTo(peripheral: PniPeripheral) {
        DispatchQueue.main.async { [weak self] in
            // Display connecting alert.
            self?.connectAlert.title = "Connecting";
            self?.connectAlert.display();
            self?.scan_button.isEnabled = false;
        }
        
        centralManager.connect(toPeripheral: peripheral);
        startTimeout();
    }
    
    /// Safeguard against the peripheral not communicating once we try to connect.
    /// This will fire after SECONDS_TO_WAIT seconds if a response hasn't arrived.
    private func startTimeout() {
        let workItem: DispatchWorkItem = DispatchWorkItem { [weak self] in
            self?.connectAlert.dismiss { [weak self] in
                self?.cancelConnection();
                self?.showAlert(title: "Operation timed out", message: "Try scanning again.");
            }
        }
        connectTimeout = workItem;
        
        DispatchQueue.main.asyncAfter(deadline: .now() + SECONDS_TO_WAIT, execute: workItem);
    }
    
    /// If the cancel button is tapped while trying to connect to a device, then
    /// this will attempt to stop the connection process.
    private func cancelConnection() {
        stopScan();
        
        if let peripheral: PniPeripheral = selectedDevice?.peripheral {
            centralManager.cancelConnection(toPeripheral: peripheral);
        }
        selectedDevice = nil;
        
        device_tableView.isUserInteractionEnabled = true;
        scan_button.isEnabled = true;
    }
    
    /// Check the current state of the centealManager. This will update the UI if needed.
    /// - Returns: True if the centralManager is ready, otherwise false.
    private func checkState() -> Bool {
        var msg: String;
        switch (centralManager.state) {
        case .poweredOn:
            return true;
        case .poweredOff:
            msg = "";
            if (!isShowingBleOff) {
                isShowingBleOff = true;
                _ = PniCentralManager(delegate: nil); // Doing this will make the system display an alert saying BLE is off.
                UIHelpers.showLabel(text: "Bluetooth is powered off", vc: self) { [weak self] in
                    self?.isShowingBleOff = false;
                }
            }
        case .resetting:
            msg = "Bluetooth is restarting, please wait.";
        case .unsupported:
            msg = "Device does not support Bluetooth.";
        case .unauthorized:
            msg = "Bluetooth is not authorized on this device.";
            if #available(iOS 13.0, *) {
                switch (centralManager.authorization) {
                case .notDetermined:
                    msg += " User has not given access.";
                case .restricted:
                    msg += " This app is not authorized to use BLE.";
                case .denied:
                    msg += " User has denied access.";
                default:
                    break;
                }
            }
        case .unknown:
            fallthrough
        @unknown default:
            msg = "Bluetooth is in an unknown state. Please try again.";
        }
        
        // Error state handling...
        devices.removeAll();
        device_tableView.reloadData();
        stopScan();
        if (!msg.isEmpty) {
            showAlert(title: "Error", message: msg);
        }
        return false;
    }
    
    /// Updates the appropriate device under the "Connected" section.
    private func updateConnectedCellUI(device: Device) {
        let idx = ConnectedDevices.shared.indexOf(device);
        updateConnectedCellUI(device: device, idx: idx);
    }
    
    /// Updates the device based on index under the "Connected" section.
    private func updateConnectedCellUI(device: Device, idx: Int) {
        guard (idx >= 0) else { return; }
        if let cell = device_tableView.cellForRow(at: IndexPath(row: idx, section: Sections.CONNECTED)) as? DeviceCell {
            cell.setCell(device: device, isConnected: true);
        }
    }
    
    /// Removes the device at the given index from the tableView and from the ConectedDevices collection.
    private func disconnectUI(idx: Int) {
        guard (idx >= 0) else { return; }
        ConnectedDevices.shared[idx].disconnect();
        device_tableView.beginUpdates()
        ConnectedDevices.shared.remove(at: idx);
        device_tableView.deleteRows(at: [IndexPath(row: idx, section: Sections.CONNECTED)], with: .fade);
        device_tableView.endUpdates();

        self.updateTabBarUI(enabled: !ConnectedDevices.shared.isEmpty);
    }
    
    /// Removes the device from the tableView and from the ConectedDevices collection.
    private func disconnectUI(device: Device) {
        let idx = ConnectedDevices.shared.indexOf(device)
        disconnectUI(idx: idx);
    }
    
    /// Enable or disable the "Logging" bar button item.
    private func updateTabBarUI(enabled: Bool) {
        if let items = tabBarController?.tabBar.items, (items.count == 2) {
            items[1].isEnabled = enabled;
        }
    }


    // MARK: UI Methods


    @IBAction private func scan_button_tapped(_ sender: PniButton?) {
        if (isScanning) {
            stopScan();
        } else {
            startScan();
        }
    }
    
    
    // MARK: PniCentralManagerDelegate
    
        
    func onStateUpdated(_ centralManager: PniCentralManager, state: CBManagerState) {
        DispatchQueue.main.async { [weak self] in
            _ = self?.checkState();
        }
        // Route to connected devices.
        for device in ConnectedDevices.shared {
            device.onStateUpdated(centralManager, state: state)
        }
    }
    
    func onDiscovered(peripheral: PniPeripheral, name: String?, manufacturerData: [UInt8]?, rssi: Float) {
        guard let manufacturerData: [UInt8] = manufacturerData, (manufacturerData.count > 5) else {
            return;
        }
        
        let companyId = manufacturerData.getUInt16(0);
        guard (companyId == Device.COMPANY_ID && name == nil) else {
            // Not a PNI BLE device.
            return;
        }
        
        let device: Device = Device(peripheral: peripheral, centralManager: centralManager, rssi: rssi, manufacturerData: manufacturerData);
        guard (searchText == "" || device.id.range(of: searchText, options: .caseInsensitive) != nil) else {
            return;
        }
        
        os_log("Discovered '%{public}s', uuid: '%{public}s', mfdata: '%{public}s'.", log: centralManager.generalLogger, type: .debug, device.id, "\(peripheral.identifier.uuidString.prefix(8))", String(describing: manufacturerData));

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.devices.append(device: device);
            
            // Trying to insert a row at a specific index gives an animation that can't
            // be disabled. This gives the desired effect at a small performance cost.
            UIView.performWithoutAnimation { [weak self] in
                // https://stackoverflow.com/a/32896400/8406615
                self?.device_tableView.reloadSections([Sections.AVAILABLE], with: .none)
            }
        }
    }
    
    func onConnected(toPeripheral peripheral: PniPeripheral) {
        if let selectedDevice = selectedDevice, peripheral.identifier == selectedDevice.peripheral.identifier {
            connectTimeout?.cancel();
            connectTimeout = nil;
            
            // Re-assign. The peripheral provided here is different than the original one.
            // The original one can't have a delegate assigned.
            let device: Device = Device(
                peripheral: peripheral,
                centralManager: centralManager,
                rssi: selectedDevice.rssi,
                manufacturerData: selectedDevice.data);
            device.delegate = self;
            device.start();
            self.selectedDevice = nil;

            DispatchQueue.main.async { [weak self] in
                self?.connectAlert.dismiss { [weak self] in
                    guard let self = self else { return }

                    // Move the sensor from the "Available" section to the "Connected" section.
                    self.device_tableView.beginUpdates()
                    let existIdx = ConnectedDevices.shared.indexOf(device);
                    if (existIdx < 0) {
                        let addIdx = ConnectedDevices.shared.add(device);
                        self.device_tableView.insertRows(at: [IndexPath(row: addIdx, section: Sections.CONNECTED)], with: .fade);
                    } else {
                        ConnectedDevices.shared.add(device);
                    }

                    let removeIdx = self.devices.remove(id: device.id);
                    if let removeIdx = removeIdx {
                        self.device_tableView.deleteRows(at: [IndexPath(row: removeIdx, section: Sections.AVAILABLE)], with: .fade)
                    }
                    self.device_tableView.endUpdates()
                    
                    self.scan_button.isEnabled = true;
                    self.device_tableView.isUserInteractionEnabled = true;
                    
                    self.updateTabBarUI(enabled: true);
                }
            }
        } else {
            // Route to connected devices.
            for device in ConnectedDevices.shared {
                if (device.peripheral.identifier == peripheral.identifier) {
                    device.onConnected(toPeripheral: peripheral)
                    break;
                }
            }
        }
    }
    
    func onConnectionFailed(toPeripheral peripheral: PniPeripheral) {
        if let selectedDevice = selectedDevice, peripheral.identifier == selectedDevice.peripheral.identifier {
            self.selectedDevice = nil;
            DispatchQueue.main.async { [weak self] in
                self?.device_tableView.isUserInteractionEnabled = true;
            }
        } else {
            // Route to connected devices.
            for device in ConnectedDevices.shared {
                if (device.peripheral.identifier == peripheral.identifier) {
                    device.onConnectionFailed(toPeripheral: peripheral)
                    break;
                }
            }
        }
    }
    
    func onDisconnected(fromPeripheral peripheral: PniPeripheral, error: Error?) {
        // Route to connected devices.
        for device in ConnectedDevices.shared {
            if (device.peripheral.identifier == peripheral.identifier) {
                device.onDisconnected(fromPeripheral: peripheral, error: error);
                break;
            }
        }
    }
    
    
    // MARK: DeviceDelegate
    
    
    func onError(_ device: Device, error: Error, type: PniPeripheral.ErrorType) {
        // TODO
    }
    
    func onReadRSSI(_ device: Device, rssi: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectedCellUI(device: device);
        }
    }
    
    func onReconnecting(_ device: Device) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectedCellUI(device: device);
        }
    }
    
    func onReconnected(_ device: Device) {
        device.logService.start(); // Services need to be rediscovered.
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectedCellUI(device: device);
        }
    }
    
    func onDisconnected(_ device: Device) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIHelpers.showLabel(text: "Disconnected from \(device.id)", vc: self)
            self.disconnectUI(device: device)
        }
    }
    
    func onGetBatteryLevel(_ device: Device, percent: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectedCellUI(device: device);
        }
    }
    

    // MARK: UITableViewDataSource
    
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2;
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case Sections.CONNECTED:
            return (ConnectedDevices.shared.count == 0) ? nil : "Connected";
        case Sections.AVAILABLE:
            return "Available";
        default:
            return nil;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch (section) {
        case Sections.CONNECTED:
            return (ConnectedDevices.shared.count == 0)
                ? Sizes.TableViewHeader.hiddenGrouped
                : Sizes.TableViewHeader.withText
        case Sections.AVAILABLE:
            return Sizes.TableViewHeader.withText;
        default:
            return Sizes.TableViewHeader.hiddenGrouped;
        }
    }
    
   func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // This will change the headers to their original strings. Grouped tableView force them to be capitalized.
        if let headerView = view as? UITableViewHeaderFooterView  {
            headerView.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case Sections.CONNECTED:
            return ConnectedDevices.shared.count;
        case Sections.AVAILABLE:
            return devices.count;
        default:
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: DeviceCell.IDENTIFIER, for: indexPath);
        
        if let cell: DeviceCell = currentCell as? DeviceCell {
            switch (indexPath.section) {
            case Sections.CONNECTED:
                cell.setCell(
                    device: ConnectedDevices.shared[indexPath.row],
                    isConnected: true);
                return cell;
            case Sections.AVAILABLE:
                cell.setCell(
                    device: devices[indexPath.row],
                    isConnected: false);
                return cell;
            default:
                break;
            }
        }
        return currentCell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == Sections.AVAILABLE && !searchText.isEmpty
            && devices[indexPath.row].id.range(of: searchText, options: .caseInsensitive) == nil) {
            return Sizes.TableViewRow.hidden
        }
        return 70;
    }
    
    
    // MARK: UITableViewDelegate
    

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section) {
        case Sections.CONNECTED:
            disconnectUI(idx: indexPath.row)
            break;
        case Sections.AVAILABLE:
            // Possibly leaving this open can confuse `ActivityIndicatorAlert`.
            id_searchBar.endEditing(true);
            device_tableView.isUserInteractionEnabled = false;
            
            stopScan(); // Stop the timer-based scan and instead just scan until callback

            device_tableView.deselectRow(at: indexPath, animated: true);
            selectedDevice = devices[indexPath.row];
            connectTo(peripheral: devices[indexPath.row].peripheral);
        default:
            break;
        }
    }
    
    
    // MARK: UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText;
        device_tableView.updateTableView()
    }
}
