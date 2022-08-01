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

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private let name: String = "SULPOM-Logger";

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        #if TEST
        print("\n--- \(name) Unit Tests Started! ---\n");
        return true;
        #endif
        
        // Update version info in "Settings" app.
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String;
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String;
        AppSettings.version = version;
        AppSettings.build = build;
        var versionString = "\(version) (\(build))";
        
        // Print out initial state just incase...
        // Go to Build Settings -> "Swift Compiler - Custom Flags".
        // From there you can add/remove symbols for either Debug or Release modes.
        #if DEBUG
        print("> Debug version.");
        versionString += " (DEBUG)";
        #else
        print("> Release version.");
        #endif
        #if IOS_SIMULATOR
        print("> `IOS_SIMULATOR` flag is set. This build doesn't support BLE.");
        #endif
        
        AppSettings.versionString = versionString;

        print("> iOS device model: '\(UIDevice.Model.current)'.");
        print("> iOS version: '\(ProcessInfo.processInfo.operatingSystemVersionString)'.");
        print("> Start time: '\(Date().description(with: .current))'.");
        
        print("\n--- \(name) v\(versionString) started! ---\n");
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        // Remove temporary file if needed.
        let tbvc: PniTabBarController?
        if #available(iOS 13.0, *) {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            tbvc = keyWindow?.rootViewController as? PniTabBarController
        } else {
            tbvc = UIApplication.shared.keyWindow?.rootViewController as? PniTabBarController
        }
        if let tbvc = tbvc,
           (tbvc.viewControllers?.count == 2), let nvc = tbvc.viewControllers?[1] as? PniNavigationController,
           (nvc.viewControllers.count > 0), let vc = nvc.viewControllers[0] as? LoggingTVC {
            vc.currentExportFile = nil
        }
    }
}
