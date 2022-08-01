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
import os.log

class PniLogs {
    static let UI = OSLog("UI")
    static func logViewLoaded(title: String?, className: String) {
        os_log("View '%@ (%@)' was loaded.", log: UI, type: .debug, title ?? "", className);
    }
    static func logViewRemoved(title: String?, className: String) {
        os_log("View '%@ (%@)' was removed.", log: UI, type: .debug, title ?? "", className);
    }
    static func logMemoryWarning(title: String?, className: String) {
        os_log("⚠️ View '%@ (%@)' received memory warning.", log: UI, type: .debug, title ?? "", className);
    }
}
