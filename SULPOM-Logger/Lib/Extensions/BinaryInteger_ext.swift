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

public extension BinaryInteger {
    /// Create a Binary number from an array of bytes. Truncation will automatically happen if
    /// the type of integer contains less bytes than the number of passed bytes.
    /// Bytes will be interpreted as little endian.
    /// - Parameter bytes: Bytes to convert into an integer.
    init(fromBytes bytes: [UInt8]) {
        var value: Self = 0;
        for byte: UInt8 in bytes.reversed() {
            value = value << 8;
            value = value | Self(byte);
        }
        
        self = value;
    }
    
    /// Returns the underlying bytes of the Binary number. Bytes are ordered in
    /// little endian by default.
    /// ## Usage Example: ##
    /// ```
    /// let u_int32: UInt32 = 26600009
    /// print(u_int32.bytes) // [73, 226, 149, 1]
    /// let u_int16: UInt16 = 12312
    /// print(u_int16.bytes) // [24, 48]
    /// ```
    var bytes: [UInt8] {
        var source: Self = self;
        return Data(bytes: &source, count: MemoryLayout<Self>.size).bytes;
    }
}
