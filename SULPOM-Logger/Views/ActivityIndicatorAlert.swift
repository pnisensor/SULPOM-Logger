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
import SDCAlertView


/// Creates an alert with whatever title and message the user wants, a loading icon below the message,
/// and a cancel button.
/// This now relies on a module rather than messing with UIAlertController subviews
class ActivityIndicatorAlert {
    // MARK: Member Variables
    
    /// The base alert view
    private var alertController: AlertController;
    
    /// The parent view controller
    private weak var vc: UIViewController?;
    
    /// The loading icon to show within the view.
    private var activityIndicator: UIActivityIndicatorView;
    
    /// The title message of the alert
    public var title: String {
        get {
            return alertController.title ?? "";
        } set(value) {
            alertController.title = value;
        }
    };
    
    /// Is the alert currently shown?
    private(set) var isShown: Bool = false;
    
    // MARK: Methods
    
    /// Creates an alert with whatever title nad message the user wants, a loading icon below the message,
    /// and a cancel button.
    /// - Parameters:
    ///   - title: The alert's title
    ///   - message: The alert's message
    ///   - presentingViewController: The view controller that will display the alert
    ///   - callback: To be invoked if the calcel button is tapped
    public init(title: String, message: String, presentor: UIViewController, onCancel callback: (() -> Void)? = nil) {
#if IS_MAC_OS_BUILD
        activityIndicator = UIActivityIndicatorView(style: .medium);
#else
        activityIndicator = UIActivityIndicatorView(style: .gray);
#endif
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
        
        vc = presentor;
        let style = AlertVisualStyle(alertStyle: .alert);
        style.verticalElementSpacing = 20;
        if #available(iOS 13.0, *) {
            style.actionViewSeparatorColor = .separator;
        } else {
            // Fallback on earlier versions
            style.actionViewSeparatorColor = UIColor(displayP3Red: 0.2352, green: 0.2352, blue: 0.2627, alpha: 0.29);
        }
        
        alertController = AlertController(title: title, message: message, preferredStyle: .alert);
        alertController.visualStyle = style
        alertController.addAction(AlertAction(title: "Cancel", style: .preferred, handler: { [weak self] (_) in
            self?.isShown = false; // Tapping a button of UIAlertController dismisses it.
            callback?();
        }));
        
        alertController.contentView.addSubview(activityIndicator)
        alertController.willDismissHandler = { [weak self] in
            // It is possible for there to be a race conditon where the user taps "Cancel" and the code
            // manually dismisses the alert. If that happens, then the wrong view controller is
            // dismissed (the navgationVC was being dismissed which was jarring).
            // This seems to fix it.
            self?.isShown = false;
        }
        
        activityIndicator.centerXAnchor.constraint(equalTo: alertController.contentView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: alertController.contentView.centerYAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: alertController.contentView.topAnchor).isActive = true
        activityIndicator.bottomAnchor.constraint(equalTo: alertController.contentView.bottomAnchor).isActive = true
    }
    
    /// Open the alert. If the alert is already shown, then don't do anything. Set constraints on
       /// the indicator once the alert has been displayed.
       /// - Parameter completion: Function to invoke when the alert has been dismissed.
       public func display(_ completion: (() -> Void)? = nil) {
           guard (!isShown) else {
               completion?();
               return;
           }
           isShown = true;
           activityIndicator.startAnimating();
           vc?.present(alertController, animated: true, completion: completion);
       }
    
    /// Programmatically close the open alert. If a callback is given, then pass that as
    /// the completion handler to `dismiss`
    /// - Parameter callback: Function to invoke when the alert has been programmatically dismissed.
    public func dismiss(then callback: (() -> Void)? = nil) {
        guard (isShown) else {
            callback?();
            return;
        }
        isShown = false;
        alertController.dismiss(animated: true) { [weak self] in
            callback?();
            self?.activityIndicator.stopAnimating();
        }
    }
    
    public func setTitle(text: String?) {
        alertController.title = text;
    }
    
    public func setMessage(text: String?) {
        alertController.message = text;
    }
}
