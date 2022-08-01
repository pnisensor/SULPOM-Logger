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

/// Encapsulates lightweight persistent app specific settings.
enum AppSettings {
    /// Full app version string.
    public static var versionString: String = "Unknown";
    
    private static let defaults: UserDefaults = UserDefaults.standard;

    private static let APP_VERSION: String = "appV";
    private static let BUILD_VERSION: String = "buildV";
    
    /// App version number.
    static var version: String {
        get { defaults.string(forKey: APP_VERSION) ?? "1.0" }
        set { defaults.set(newValue, forKey: APP_VERSION) }
    }
    
    /// App build number.
    static var build: String {
        get { defaults.string(forKey: BUILD_VERSION) ?? "1" }
        set { defaults.set(newValue, forKey: BUILD_VERSION) }
    }
    
    /// Output log settings.
    enum Log {
        enum Enabled {
            private static let Q9 = "logE_q9";
            private static let QMA = "logE_qma";
            private static let LINACC = "logE_linacc";
            private static let GBIAS = "logE_gbias";
            private static let MRAW = "logE_mraw";
            private static let MAUTO = "logE_mauto";
            private static let ARAW = "logE_araw";
            private static let AAUTO = "logE_aauto";
            private static let GRAW = "logE_graw";
            private static let GAUTO = "logE_gauto";
            private static let TEMP = "logE_temp";
            private static let PRESSURE = "logE_pressure";
            
            static var quaternion9axis: Bool {
                get { defaults.object(forKey: Q9) as? Bool ?? false }
                set { defaults.set(newValue, forKey: Q9) }
            }
            
            static var quaternionMagAccel: Bool {
                get { defaults.object(forKey: QMA) as? Bool ?? false }
                set { defaults.set(newValue, forKey: QMA) }
            }
            
            static var linearAccel: Bool {
                get { defaults.object(forKey: LINACC) as? Bool ?? false }
                set { defaults.set(newValue, forKey: LINACC) }
            }
            
            static var gyroBias: Bool {
                get { defaults.object(forKey: GBIAS) as? Bool ?? false }
                set { defaults.set(newValue, forKey: GBIAS) }
            }
            
            static var magRaw: Bool {
                get { defaults.object(forKey: MRAW) as? Bool ?? false }
                set { defaults.set(newValue, forKey: MRAW) }
            }
            
            static var magAutocal: Bool {
                get { defaults.object(forKey: MAUTO) as? Bool ?? true }
                set { defaults.set(newValue, forKey: MAUTO) }
            }
            
            static var accelRaw: Bool {
                get { defaults.object(forKey: ARAW) as? Bool ?? false }
                set { defaults.set(newValue, forKey: ARAW) }
            }
            
            static var accelAutocal: Bool {
                get { defaults.object(forKey: AAUTO) as? Bool ?? true }
                set { defaults.set(newValue, forKey: AAUTO) }
            }
            
            static var gyroRaw: Bool {
                get { defaults.object(forKey: GRAW) as? Bool ?? false }
                set { defaults.set(newValue, forKey: GRAW) }
            }
            
            static var gyroAutocal: Bool {
                get { defaults.object(forKey: GAUTO) as? Bool ?? true }
                set { defaults.set(newValue, forKey: GAUTO) }
            }
            
            static var temperature: Bool {
                get { defaults.object(forKey: TEMP) as? Bool ?? false }
                set { defaults.set(newValue, forKey: TEMP) }
            }
            
            static var pressure: Bool {
                get { defaults.object(forKey: PRESSURE) as? Bool ?? false }
                set { defaults.set(newValue, forKey: PRESSURE) }
            }
        }
        
        enum NstStreaming {
            private static let ENABLED = "logNS_enabled";
            private static let URL = "logNS_url";
            private static let API_KEY = "logNS_key"
            private static let AUTO_CONNECT = "logNS_auto"
            
            static var isEnabled: Bool {
                get { defaults.object(forKey: ENABLED) as? Bool ?? false }
                set { defaults.set(newValue, forKey: ENABLED) }
            }
            
            static var url: String {
                get { defaults.string(forKey: URL) ?? "" }
                set { defaults.set(newValue, forKey: URL) }
            }
            
            static var apiKey: String {
                get { defaults.string(forKey: API_KEY) ?? "" }
                set { defaults.set(newValue, forKey: API_KEY) }
            }
            
            static var autoConnect: Bool {
                get { defaults.object(forKey: AUTO_CONNECT) as? Bool ?? false }
                set { defaults.set(newValue, forKey: AUTO_CONNECT) }
            }
        }
        
        enum NstUpload {
            private static let ENABLED = "logNU_enabled";
            private static let API_KEY = "logNU_key"
            
            static var isEnabled: Bool {
                get { defaults.object(forKey: ENABLED) as? Bool ?? false }
                set { defaults.set(newValue, forKey: ENABLED) }
            }
            
            static var apiKey: String {
                get { defaults.string(forKey: API_KEY) ?? "" }
                set { defaults.set(newValue, forKey: API_KEY) }
            }
        }
        
        private static let RATE: String = "log_rate";

        static var rate: UInt8 {
            get { defaults.object(forKey: RATE) as? UInt8 ?? 30 }
            set { defaults.set(newValue, forKey: RATE) }
        }
    }
}
