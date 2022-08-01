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

public extension Array {
    /// This function takes the active array and an array with all the elements starting from
    /// startIndex and ending at endIndex.
    /// - Note: Both indexes should be non-negative. Neither should be larger than the size of the array.
    /// - Note: startIndex should ALWAYS be less than endIndex. It is up to the caller to check for this!
    /// - Parameters:
    ///   - startIndex: First index of array elements to include.
    ///   - endIndex: Last index of array elements to include.
    /// - Returns: An array with elements in the passed index range
    func slice(startIndex: Int, endIndex: Int) -> Array {
        let arraySlice: ArraySlice<Element> = self[startIndex ..< endIndex];
        return Array(arraySlice);
    }
}

// MARK: [UInt8]

extension Array where Element == UInt8 {
    /// Gets the 4-byte Float in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getFloat(_ i: Int) -> Float {
        return Float(fromBytes: [self[i], self[i + 1], self[i + 2], self[i + 3]])
    }
    
    /// Gets the 8-byte Double in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getDouble(_ i: Int) -> Double {
        return Double(fromBytes: [self[i], self[i + 1], self[i + 2], self[i + 3],
                                  self[i + 4], self[i + 5], self[i + 6], self[i + 7]])
    }
    
    /// Gets the 2-byte UInt16 in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getUInt16(_ i: Int) -> UInt16 {
        return UInt16(fromBytes: [self[i], self[i + 1]])
    }
    
    /// Gets the 3-byte UInt24 in little endian at the given index. This is returned as a UInt32.
    /// This doesn't chech for index of of range.
    func getUInt24(_ i: Int) -> UInt32 {
        return UInt32(fromBytes: [self[i], self[i + 1], self[i + 2], 0]);
    }
    
    /// Gets the 4-byte UInt32 in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getUInt32(_ i: Int) -> UInt32 {
        return UInt32(fromBytes: [self[i], self[i + 1], self[i + 2], self[i + 3]])
    }
    
    /// Gets the 8-byte UInt64 in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getUInt64(_ i: Int) -> UInt64 {
        return UInt64(fromBytes: [self[i], self[i + 1], self[i + 2], self[i + 3],
                                  self[i + 4], self[i + 5], self[i + 6], self[i + 7]])
    }
    
    /// Gets the 2-byte Int16 in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getInt16(_ i: Int) -> Int16 {
        return Int16(fromBytes: [self[i], self[i + 1]])
    }
    
    /// Gets the 3-byte Int24 in little endian at the given index. This is returned as a Int32.
    /// This doesn't chech for index of of range.
    func getInt24(_ i: Int) -> Int32 {
        let extraByte: UInt8;
        if (self[i + 2] > 127) { // Check upper bit for twos complement extension.
            extraByte = 255;
        } else {
            extraByte = 0;
        }
        return Int32(fromBytes: [self[i], self[i + 1], self[i + 2], extraByte]);
    }
    
    /// Gets the 4-byte Int32 in little endian at the given index.
    /// This doesn't chech for index of of range.
    func getInt32(_ i: Int) -> Int32 {
        return Int32(fromBytes: [self[i], self[i + 1], self[i + 2], self[i + 3]])
    }
}
