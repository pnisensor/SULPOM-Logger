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

class PniViewController: UIViewController {
    // MARK: Methods
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        
        // Label for the back button.
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: nil,
            action: nil);
        
        // Devices w/ iOS 10.x randomly have empty space appears above embedded table views (and maybe more...?)...
        // This seems to get rid of it.
        if #available(iOS 11.0, *) { } else {
            automaticallyAdjustsScrollViewInsets = false;
        }
    }
    
    override public func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let activityVC: UIActivityViewController = viewControllerToPresent as? UIActivityViewController {
            // Handle iPad specifc bug.
            if let popover: UIPopoverPresentationController = activityVC.popoverPresentationController {
                // activityVC crashes on iPad without this check!
                popover.sourceView = view;
                
                // Centers the popup.
                let x: CGFloat = UIScreen.main.bounds.width / 2;
                let y: CGFloat = UIScreen.main.bounds.height / 2;
                popover.sourceRect = CGRect(x: x, y: y, width: 0, height: 0);
                popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0);
            }
        }
        
        // If there is already an alert on screen, clear it out and show the new one.
        // Try to save the message from the previous alert if possible and add the new message
        // on the next line.
        if let newAlert = viewControllerToPresent as? UIAlertController,
           let shownAlert = presentedViewController as? UIAlertController {
            if let shownMessage: String = shownAlert.message, let message: String = newAlert.message {
                newAlert.message = shownMessage + "\n\n" + message;
            }
            shownAlert.dismiss(animated: false) {
                super.present(viewControllerToPresent, animated: flag, completion: completion);
            }
            return;
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion);
    }

    /// This function will cause an message alert to appear on the user's screen with the passed parameters.
    /// - Parameters:
    ///   - title: String to display at the top of the alert.
    ///   - message: String to display in the body of the alert.
    ///   - then: Optional callback function to execute when the user taps "Ok".
    public func showAlert(title: String, message: String, actionHandler: ((_ alertAction: UIAlertAction) -> Void)? = nil) {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: actionHandler));
        present(alert, animated: true);
    }
}
