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
import UIKit;

public extension UIViewController {
    static func topMostViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            return keyWindow?.rootViewController?.topMostViewController()
        }
        
        return UIApplication.shared.keyWindow?.rootViewController?.topMostViewController()
    }
    
    /// Recursive function that returns the top most view controller on the stack.
    /// - Returns: The top most view controller
    func topMostViewController() -> UIViewController {
        // Check if the current VC is a navigationVC. If so, return the top most controller of
        // the controller thats displayed by the nav controller (or just the nav controller).
        if let navigation: UINavigationController = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation;
        }
        
        if let tab: UITabBarController = self as? UITabBarController {
            if let selectedTab: UIViewController = tab.selectedViewController {
                return selectedTab.topMostViewController();
            }
            return tab.topMostViewController();
        }
        
        // If the view controller is presenting another view controller, then grab the presented one.
        guard let presentedVC: UIViewController = self.presentedViewController else {
            // This is the true base case unless the top most VC is a navigation VC.
            return self;
        }
        
        return presentedVC.topMostViewController();
    }
}
