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
import UIKit

class PniTabBarController: UITabBarController, UITabBarControllerDelegate {
    weak var pniDelegate: UITabBarControllerDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.delegate = self;
    }
    
    // MARK:  UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Stops View Controllers from being dismissed when a tab is selected on the UITabBarController
        return (viewController != tabBarController.selectedViewController);
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        pniDelegate?.tabBarController?(tabBarController, didSelect: viewController)
    }
}
