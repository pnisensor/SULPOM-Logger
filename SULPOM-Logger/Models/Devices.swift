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

/// Container object that holds a collection of device objects. Each device should have
/// a unique ID in is "sensorId" field.
class Devices: Collection {
    // MARK: Member Variables
    
    /// Array of device objects. This class will provide a light wrapper around this member.
    private var items: [Device] = [];
    
    /// Returns the number of devices inside of the collection.
    public var count: Int {
        get { items.count }
    }
    
    /// Should the elements be sorted by desending RSSI?
    public var sortByRssi: Bool = true;
    
    
    // MARK: Methods
    
    
    /// Add a new device to the collection. If that device is already in the collection,
    /// then the old device will we over written with the new one.
    /// If the `sortByRssi` flag is true, the device will be inserted at its proper index
    /// based off RSSI value.
    /// - Parameter device: New (possibly) device to add to the collection.
    /// - Returns: The index of the added item.
    @discardableResult
    public func append(device: Device) -> Int {
        let isAnElement: Int = indexOf(device: device);
        if (isAnElement >= 0) {
            let existing = items[isAnElement];
            if (device.rssi != existing.rssi) {
                items.remove(at: isAnElement);
                return addByRssi(device: device)
            } else {
                items[isAnElement] = device;
                return isAnElement;
            }
        }
        
        return addByRssi(device: device)
    }
    
    private func addByRssi(device: Device) -> Int {
        if (sortByRssi && device.rssi != 127) {
            var index: Int = 0;
            for item: Device in items {
                if (device.rssi > item.rssi) {
                    items.insert(device, at: index);
                    return index;
                }
                index += 1;
            }
        }
        items.append(device);
        return items.count - 1;
    }
    
    /// Gets the device with the matching id if it is found.
    func get(id: String) -> Device? {
        let id = id.lowercased()
        for item: Device in items {
            if (item.id.lowercased() == id) {
                return item;
            }
        }
        return nil;
    }
    
    /// Gets the device with the matching peripheral uuid if it is found.
    func get(uuid: String) -> Device? {
        for item: Device in items {
            if (item.peripheral.identifier.uuidString == uuid) {
                return item;
            }
        }
        return nil;
    }
    
    /// Removes the sensor with the matching id from the collection
    /// - Returns: The index of the remove item.
    @discardableResult
    func remove(id: String) -> Int? {
        var found = false;
        var index: Int = 0;
        for item: Device in items {
            if (item.id.lowercased() == id.lowercased()) {
                found = true;
                break;
            }
            index += 1;
        }
        if (found) {
            items.remove(at: index);
            return index;
        }
        return nil;
    }
    
    /// Removes the device with the matching peripheral uuid if it is found.
    func remove(uuid: String) {
        var found = false;
        var index: Int = 0;
        for item: Device in items {
            if (item.peripheral.identifier.uuidString == uuid) {
                found = true;
                break;
            }
            index += 1;
        }
        if (found) {
            items.remove(at: index);
        }
    }
    
    /// Removes the device at the specified index from the collection.
    /// - Parameter index: Index of the device to remove.
    public func remove(at index: Int) {
        items.remove(at: index);
    }
    
    /// Removes all devices in the collection.
    public func removeAll() {
        items.removeAll();
    }
    
    /// This checks if the device is already in the collection. If it is, then return the index it is at.
    /// Otherwise return -1.
    /// - Parameter device: The device to lookup in the collection.
    /// - Returns: Either a non negative value representing the device's index or -1 if the device isn't found.
    func indexOf(device: Device) -> Int {
        var index: Int = 0;
        for item: Device in items {
            if (item.id.lowercased() == device.id.lowercased()) {
                return index;
            }
            index += 1;
        }
        return -1;
    }
    
    // MARK: - Collection methods
    // Conforming to Collection allows "for x in y" iteration over the custom object.
    
    /// '[]' operator overload. Allows indexing into the array of devices.
    /// - Parameter index: The index to use in the device array.
    public subscript(index: Int) -> Device {
        get { items[index] }
        set { items.insert(newValue, at: index) }
    }
    
    // Upper bounds of the collection.
    public var startIndex: Int {
        return items.startIndex;
    };
    
    // Lower bounds of the collection.
    public var endIndex: Int {
        return items.endIndex;
    };

    // Method that returns the next index when iterating.
    public func index(after i: Int) -> Int {
        return items.index(after: i);
    }
}
