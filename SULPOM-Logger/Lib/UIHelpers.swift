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

class UIHelpers {
    static func showLabel(text: String, vc: UIViewController, completion: (() -> Void)? = nil) {
        let label: UILabel = UILabel();
        label.textAlignment = .center;
        label.numberOfLines = 0;
        label.lineBreakMode = .byWordWrapping;
        label.textColor = .white;
        label.backgroundColor = .gray;
        label.layer.cornerRadius = 8;
        label.layer.masksToBounds = true;
        label.font = .systemFont(ofSize: 15)
        label.text = text;
        
        // Calculating label frame as per message content.
        let viewWidth = vc.view.bounds.size.width;
        let viewHeight = vc.view.bounds.size.height;
        let maxWidthMargin: CGFloat = 32; // Ensure the label is >= 16 points from the edge of the screen.
        let maxSize = CGSize(width: viewWidth - maxWidthMargin, height: viewHeight);
        var expectedSize = label.sizeThatFits(maxSize);
        expectedSize = CGSize(width: min(maxSize.width, expectedSize.width), height: min(maxSize.height, expectedSize.height));
        
        // Define the frame.
        let padding: CGFloat = 16;
        let width: CGFloat = expectedSize.width + padding;
        let height: CGFloat = expectedSize.height + padding;
        let x = (viewWidth / 2) - (width / 2);
        let y = (viewHeight / 2) - (height / 2);
        label.frame = CGRect(x: x, y: y, width: width, height: height);
        
        label.alpha = 0;
        vc.view.addSubview(label);
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: { label.alpha = 0.8 }) { (_) in
            UIView.animateKeyframes(withDuration: 0.5, delay: 1.5, options: [], animations: { label.alpha = 0 }) { (_) in
                label.removeFromSuperview();
                completion?()
            }
        }
    }
}
