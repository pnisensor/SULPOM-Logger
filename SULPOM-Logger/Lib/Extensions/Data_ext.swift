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

public extension Data {
    /// Returns the underlying bytes of the Data object.
    var bytes: [UInt8] {
        return [UInt8](self);
    }
    
    /// Attemps to convert data into a String.
    /// Returns nil if it fails.
    /// ## Usage Example: ##
    /// ```
    /// let data: Data = ... // Some received Data
    /// print(data) // 10 bytes
    /// print(data.toString()!) // "4.2.0.510"
    /// ```
    func toString() -> String? {
        return String(data: self, encoding: .utf8);
    }
}
