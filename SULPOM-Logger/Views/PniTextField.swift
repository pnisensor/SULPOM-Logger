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

/// A standard text field where the "Enter" button is replaced by a "Done" button that will
/// close the text entry screen when pressed.
class PniTextField: UITextField {
    // MARK: Methods
    
    // constructor
    override init(frame: CGRect) {
        super.init(frame: frame);
        setup();
    }
    
    // constructor
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup();
    }
    
    /// Steps needed to make it so the "Enter" button shows the text "Done" and will close the
    /// text entry when pressed.
    private func setup() {
        returnKeyType = .done;
        addTarget(nil, action: Selector(("firstResponderAction:")), for: .editingDidEndOnExit);
    }
    
    enum Options {
        case NEGATIVE_SIGN;
    }
    
    /// Adds a done button to the Text Field. Clicking this closes the Text Fields input screen.
    ///
    /// Some TextFields lack a done button, so we have to make one
    /// ourself. We also need to register an objective-c function to be used as a callback
    /// function when done is pressed...
    func addDoneButton(option: Options? = nil) {
        let toolBar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50));
        toolBar.barStyle = .default;
        
        var barButtons: [UIBarButtonItem] = [];
        if let option: Options = option {
            switch (option) {
            case .NEGATIVE_SIGN:
                barButtons.append(UIBarButtonItem(
                    title: "+/-",
                    style: .plain,
                    target: self,
                    action: #selector((plusMinusPressed))));
            }
        }
        
        // This item will fill the empty space in the toolbar
        barButtons.append(UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        ));
        
        // This item will create a 'done' button
        barButtons.append(UIBarButtonItem(
            title: "Done",
            style: .done,
            target: nil,
            action: #selector((doneAction))
        ));
        
        // Add the items to the toolbar
        toolBar.items = barButtons;
        toolBar.sizeToFit();
        
        // Add the toolbar to the input view.
        inputAccessoryView = toolBar;
    }
    
    /// Selector function that closes the open input entry window.
    @objc private func doneAction() {
        resignFirstResponder();
    }
    
    @objc private func plusMinusPressed() {
        guard let text = text else {
            return;
        }
        if (text.hasPrefix("-")) {
            let index: String.Index = text.index(text.startIndex, offsetBy: 1);
            self.text = String(text[index...]); // Remove negative sign.
        } else {
            self.text = "-\(text)";
        }
    }
}
