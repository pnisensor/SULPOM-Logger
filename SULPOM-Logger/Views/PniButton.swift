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

/// Class for Generic buttons within this application.
class PniButton: UIButton {
    // MARK: Constants
    
    /// Amount of rounding we want on the button corners.
    private static let CORNER_RADIUS_VALUE: CGFloat = 15;
    
    
    // MARK: Member Variables
    
    /// A Boolean value indicating whether the control is enabled.
    /// Enabled has full alpha and disabled has 0.3 alpha.
    override public var isEnabled: Bool {
        didSet {
            alpha = (isEnabled) ? 1.0 : 0.3;
        }
    };
    
    
    // MARK: Methods
    
    
    override public init(frame: CGRect) {
        super.init(frame: frame);
        setup();
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        setup();
    }

    /// All PniButtons have rounded couners.
    private func setup() {
        layer.cornerRadius = Self.CORNER_RADIUS_VALUE;
    }
    
    // Called when the button changes in some form, whether its resizing or changing color.
    override public func layoutSubviews() {
        super.layoutSubviews();
        awakeFromNib();
    }
    
    /// What type of layer does the button contain?
    /// If we don’t override it, the main layer will be always CALayer without any way to change its type.
    /// See https://marcosantadev.com/calayer-auto-layout-swift/
    override public class var layerClass: Swift.AnyClass {
        return CAShapeLayer.self;
    }
    
    /// We want to add the shadow to the button when this happens.
    override public func awakeFromNib() {
        super.awakeFromNib();
        
        guard let newShadowLayer = self.layer as? CAShapeLayer else {
            return;
        }
        
        // This block of code will add a shadow under each PNI button.
        newShadowLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Self.CORNER_RADIUS_VALUE).cgPath;
        newShadowLayer.needsDisplayOnBoundsChange = true;
        newShadowLayer.contentsScale = self.contentScaleFactor
        newShadowLayer.fillColor = self.backgroundColor?.cgColor;
        
        newShadowLayer.shadowColor = UIColor.darkGray.cgColor;
        newShadowLayer.shadowPath = newShadowLayer.path;
        newShadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0);
        newShadowLayer.shadowOpacity = 0.8;
        newShadowLayer.shadowRadius = 2;
    }
    
    /// Bootstrap button colors to use as background color.
    /// - red: Red button, "danger"
    /// - green: Green button, "success"
    /// - turquoise: Light blue button, "info"
    /// - blue: Dark blue button, "primary"
    public enum Color {
        /// Red button, "danger"
        case red;
        /// Green button, "success"
        case green;
        /// Light blue button, "info"
        case turquoise;
        /// Dark blue button, "primary"
        case blue;
    }
    
    /// Changes the button's background color to the selected color
    /// - Parameter color: Color to change the background to
    public func setColor(color: Color) {
        var selectedColor: UIColor;
        
        switch (color) {
            
        case .red:
            selectedColor = UIColor(red: 217 / 255, green: 83 / 255, blue: 79 / 255, alpha: 1);
        case .green:
            selectedColor = UIColor(red: 92 / 255, green: 184 / 255, blue: 92 / 255, alpha: 1);
        case .turquoise:
            selectedColor = UIColor(red: 91 / 255, green: 192 / 255, blue: 222 / 255, alpha: 1);
        case .blue:
            selectedColor = UIColor(red: 51 / 255, green: 122 / 255, blue: 183 / 255, alpha: 1);
        }
        
        backgroundColor = selectedColor;
    }
    
    /// Changes both the button's title and if its enabled.
    /// - Parameters:
    ///   - title: New title to display on the button.
    ///   - enabled: New state for the button to be in.
    public func changeState(title: String, enabled: Bool) {
        self.setTitle(title, for: .normal);
        isEnabled = enabled;
    }
}
