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

/// Contains `Device` firmware information.
class Firmware: Equatable {
    /// The type of firmware.
    let typeId: TypeId;
    /// The version number of the firmware.
    let version: UInt16;
    /// A text respresentation of the firmware.
    private(set) lazy var name: String = Self.getName(typeId: typeId, version: version)
    
    init(typeId: TypeId, version: UInt16) {
        self.typeId = typeId;
        self.version = version;
    }
    
    static func == (lhs: Firmware, rhs: Firmware) -> Bool {
        return (lhs.typeId == rhs.typeId && lhs.version == rhs.version)
    }
    
    /// The type of firmware.
    enum TypeId {
        /// Standard LPOM firmware.
        case LPOM_TRACKER;
        
        /// LPOM with DOM funcionality firmware.
        case LPOM_DOM;
        
        /// Standard SULPOM firmware.
        case SULPOM_TRACKER;
        
        /// SULPOM with DOM functionality firmware.
        case SULPOM_DOM;
        
        /// Unknown firmware type.
        case UNKNOWN;
        
        /// Create a TypeId from the given byte. This is provided from a device's manufacturer data.
        static func from(type: UInt8) -> Self {
            switch (type) {
            case 0:
                return .LPOM_TRACKER;
            case 1:
                return .LPOM_DOM;
            case 6:
                return .SULPOM_TRACKER;
            case 7:
                return .SULPOM_DOM;
            default:
                return .UNKNOWN;
            }
        }
        
        /// Is the current firmware that of a SULPOM sensor?
        func isSulpom() -> Bool {
            return self == .SULPOM_TRACKER || self == .SULPOM_DOM;
        }
        
        /// Is the current firmware that of a LPOM sensor?
        func isLpom() -> Bool {
            return self == .LPOM_TRACKER || self == .LPOM_DOM;
        }
        
        /// Does the current firmware have DOM functionality included?
        func isDom() -> Bool {
            return self == .LPOM_DOM || self == .SULPOM_DOM;
        }
    }
    
    /// Get the firmware name string based off of typeId and version number.
    static func getName(typeId: TypeId, version: UInt16) -> String {
        switch (typeId) {
        case .LPOM_TRACKER:
            return "LPOM (\(version))";
        case .LPOM_DOM:
            return "DOM (\(version))";
        case .SULPOM_TRACKER:
            return "SULPOM Tracker (\(version))";
        case .SULPOM_DOM:
            return "SULPOM DOM (\(version))";
        case .UNKNOWN:
            return "Unknown (\(version))";
        }
    }
}
