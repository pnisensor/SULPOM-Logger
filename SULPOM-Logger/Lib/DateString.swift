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

/// Contains commonly used date formatting.
class DateString {
    private static let filenameDateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter();
        formatter.calendar = Calendar(identifier: .iso8601);
        formatter.locale = Locale(identifier: "en_US_POSIX");
        formatter.timeZone = TimeZone(secondsFromGMT: 0);
        formatter.dateFormat = "yyyy-MM-dd_HH_mm_ss";
        return formatter;
    }();
    
    private static let isoDateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter();
        formatter.calendar = Calendar(identifier: .iso8601);
        formatter.locale = Locale(identifier: "en_US_POSIX");
        formatter.timeZone = TimeZone(secondsFromGMT: 0);
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX";
        return formatter;
    }();
    
    /// Creartes an iso8601 date string.
    /// Example: "`2022-07-05T20:40:01.525Z`"
    static func iso(date: Date) -> String {
        return isoDateFormatter.string(from: date);
    }
    
    /// Creates a filename "safe date string.
    /// Example: "`2022-07-05_20_40_01`"
    static func filename(date: Date) -> String {
        return filenameDateFormatter.string(from: date);
    }
}
