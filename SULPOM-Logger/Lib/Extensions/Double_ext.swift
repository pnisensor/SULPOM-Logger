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

public extension Double {
    /// Takes an array of bytes and turns it into a double.
    /// Bytes will be interpreted as little endian.
    /// - Parameter bytes: Array of bytes to turn into a double.
    init(fromBytes bytes: [UInt8]) {
        var double: Double = 0.0;
        memcpy(&double, bytes, bytes.count);
        self = double;
    }

    /// Get the underlying bytes of the float in little endian. Length is 8.
    var bytes: [UInt8] {
        return bitPattern.bytes;
    }
}
