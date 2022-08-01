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

/// Some places have a view that is a different color to represent a "line" drawn.
/// If these are in a tableView cell, then by default their background color will be
/// temporarily changed when the cell is selected/highlighted.
/// This provides a fix.
class NeverClearView: UIView {
    // MARK: Member variables
    
    /// The last color that was set in the background.
    private var currentBackgroundColor: UIColor? = UIColor(red: 154 / 255, green: 154 / 255, blue: 154 / 255, alpha: 1);
    
    
    // MARK: Methods

    
    /// The view's background color.
    /// This override prevents the view from dissapearing when a UITableViewCell is highlighted.
    override public var backgroundColor: UIColor? {
        didSet {
            if let bgAlpha: CGFloat = backgroundColor?.cgColor.alpha, (bgAlpha == 0) {
                backgroundColor = currentBackgroundColor;
            } else {
                currentBackgroundColor = backgroundColor;
            }
        }
    }
}
