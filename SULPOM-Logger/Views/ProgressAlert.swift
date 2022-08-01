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

class ProgressAlert {
    // MARK: Member Variables
        
    /// The base alert view
    private var alertController: AlertController;
    
    /// The parent view controller
    private weak var vc: UIViewController?;
    
    private let progressView: UIProgressView;
    
    /// Callback function to be invoked if the user taps the `cancel` button.
    private var callback: (() -> Void)?;
    
    /// The title message of the alert
    public var title: String {
        get {
            return alertController.title ?? "";
        } set(value) {
            alertController.title = value;
        }
    };
    
    /// Is the alert currently shown?
    private var isShown: Bool = false;
    
    // MARK: Methods
    
    /// Creates an alert with whatever title nad message the user wants, a loading icon below the message,
    /// and a cancel button.
    /// - Parameters:
    ///   - title: The alert's title
    ///   - message: The alert's message
    ///   - presentingViewController: The view controller that will display the alert
    ///   - callback: To be invoked if the calcel button is tapped
    public init(title: String, message: String?, presentor: UIViewController, includeCancel: Bool, onCancel callback: (() -> Void)? = nil) {
        progressView = UIProgressView(progressViewStyle: .default);
        progressView.progress = 0
        progressView.tintColor = .blue;
        progressView.translatesAutoresizingMaskIntoConstraints = false;
        
        vc = presentor;
        
        alertController = AlertController(title: title, message: message, preferredStyle: .alert);
        let style = AlertVisualStyle(alertStyle: .alert);
        if (includeCancel) {
            alertController.addAction(AlertAction(title: "Cancel", style: .preferred, handler: { [weak self] (_) in
                self?.isShown = false; // Tapping a button of UIAlertController dismisses it.
                callback?();
            }));
            
            if #available(iOS 13.0, *) {
                style.actionViewSeparatorColor = .separator;
            } else {
                // Fallback on earlier versions
                style.actionViewSeparatorColor = UIColor(displayP3Red: 0.2352, green: 0.2352, blue: 0.2627, alpha: 0.29);
            }
        }
        
        style.verticalElementSpacing = 20;
        style.contentPadding.bottom += 20;
        alertController.visualStyle = style;
        
        alertController.contentView.addSubview(progressView)
        
        progressView.centerXAnchor.constraint(equalTo: alertController.contentView.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: alertController.contentView.centerYAnchor).isActive = true
        progressView.leftAnchor.constraint(equalTo: alertController.contentView.leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: alertController.contentView.rightAnchor).isActive = true
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
        alertController.dismiss(animated: true, completion: callback);
    }
    
    public func setProgress(to value: Double) {
        progressView.progress = Float(value);
    }
    
    public func setMessage(text: String?) {
        alertController.message = text;
    }
}
