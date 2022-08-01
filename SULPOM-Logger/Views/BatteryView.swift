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

/// Show a battery oriented toward `direction`, charged `level` percent.
/// Turns red when level drops below `lowThreshold`, or gradually when below `gradientThreshold`.
///
/// Rip of https://github.com/yonat/BatteryView
@IBDesignable open class BatteryView: UIView {
    static let fullBattery: Int = 100;
    
    private static var background: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    private static var foreground: UIColor {
        if #available(iOS 13, *) {
            return .label
        } else {
            return .black
        }
    }
    
    private static func blend(_ color: UIColor, with otherColor: UIColor, fraction: CGFloat) -> UIColor {
        let f = min(1, max(0, fraction))
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        color.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        otherColor.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        let h = h1 + (h2 - h1) * f
        let s = s1 + (s2 - b1) * f
        let b = b1 + (b2 - b1) * f
        let a = a1 + (a2 - a1) * f
        return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
    
    // MARK: - Behavior Properties
    /// 0 to 100 percent full, unavailable = -1
    @IBInspectable open var level: Int = -1 { didSet { setNeedsDisplay() } }

    /// change color when level crosses the threshold
    @IBInspectable open dynamic var lowThreshold: Int = 10 { didSet { layoutFillColor() } }

    /// gradually change color when level crosses the threshold
    @IBInspectable open dynamic var gradientThreshold: Int = 0 { didSet { layoutFillColor() } }

    // MARK: - Appearance Properties
    /// direction of battery terminal
    @objc open dynamic var direction: CGRectEdge = .minYEdge { didSet { setNeedsLayout() } }

    /// simplified direction of battery terminal (for Interface Builder)
    @IBInspectable open dynamic var isVertical: Bool {
        get { return direction == .maxYEdge || direction == .minYEdge }
        set { direction = newValue ? .minYEdge : .maxXEdge }
    }

    // relative size of  battery terminal
    @IBInspectable open dynamic var terminalLengthRatio: CGFloat = 0.065 { didSet { setNeedsLayout() } }
    @IBInspectable open dynamic var terminalWidthRatio: CGFloat = 0.4 { didSet { setNeedsLayout() } }

    // swiftlint:disable redundant_type_annotation
    @IBInspectable open dynamic var highLevelColor: UIColor = UIColor(red: 0.0, green: 0.9, blue: 0.0, alpha: 1) { didSet { layoutFillColor() } }
    @IBInspectable open dynamic var lowLevelColor: UIColor = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1) { didSet { layoutFillColor() } }
    @IBInspectable open dynamic var noLevelColor: UIColor = UIColor(white: 0.8, alpha: 1) { didSet { layoutFillColor() } }
    // swiftlint:enable redundant_type_annotation
    /// label shown over battery when the level is undefined or out of range
    @IBInspectable open dynamic var noLevelText: String? = "?"

    @IBInspectable open dynamic var borderColor: UIColor = BatteryView.foreground {
        didSet {
            bodyOutline.borderColor = borderColor.cgColor
            terminalOutline.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable open dynamic var fillTerminalWithBorder: Bool = false { didSet { layoutFillColor() } }

    /// set as 0 for default borderWidth = length / 20
    @IBInspectable open dynamic var borderWidth: CGFloat = 0 { didSet { layoutBattery(); layoutLevel() } }

    /// set as 0 for default cornerRadius = length / 10
    @IBInspectable open dynamic var cornerRadius: CGFloat = 0 { didSet { layoutCornerRadius() } }

    public var currentFillColor: UIColor {
        switch level {
        case 0:
            return .clear
        case 1 ... lowThreshold:
            return lowLevelColor
        case gradientThreshold ... Self.fullBattery:
            return highLevelColor
        case lowThreshold ... Self.fullBattery:
            let fraction = CGFloat(level - lowThreshold) / CGFloat(min(gradientThreshold, Self.fullBattery) - lowThreshold)
            return Self.blend(lowLevelColor, with: highLevelColor, fraction: fraction)
        default:
            return noLevelColor
        }
    }

    // MARK: - Overrides
    open override var backgroundColor: UIColor? { didSet { layoutFillColor() } }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutBattery()
        layoutLevel()
    }

    // MARK: - Subviews & Sublayers
    public let noLevelLabel = UILabel()
    private let bodyOutline = CALayer()
    private let terminalOutline = CALayer()
    private let terminalOpening = CALayer()
    private let levelFill = CALayer()

    private func setUp() {
        layer.addSublayer(bodyOutline)
        bodyOutline.masksToBounds = true
        bodyOutline.addSublayer(levelFill)
        layer.addSublayer(terminalOutline)
        layer.addSublayer(terminalOpening)
        setNeedsLayout()

        noLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noLevelLabel)

        isAccessibilityElement = true
        accessibilityIdentifier = "battery"
        accessibilityLabel = "battery"
    }
    
    open override func draw(_ rect: CGRect) {
        layoutLevel()
    }

    // MARK: - Layout
    private var length: CGFloat { return isVertical ? bounds.height : bounds.width }

    private func layoutBattery() {
        // divide total length into body and terminal
        let terminalLength = terminalLengthRatio * length
        var (terminalFrame, bodyFrame) = bounds.divided(atDistance: terminalLength, from: direction)

        // layout body
        bodyOutline.frame = bodyFrame
        bodyOutline.borderWidth = borderWidth != 0 ? borderWidth : length / 20
        noLevelLabel.center = CGPoint(x: bodyOutline.frame.midX, y: bodyOutline.frame.midY)
        noLevelLabel.font = noLevelLabel.font.withSize(min(bodyFrame.width, 0.75 * bodyFrame.height))

        // layout terminal
        let parallelInsetRatio = (1 - terminalWidthRatio) / 2
        let perpendicularInset = bodyOutline.borderWidth
        var (dx, dy) = isVertical
            ? (parallelInsetRatio * bounds.width, -perpendicularInset)
            : (-perpendicularInset, parallelInsetRatio * bounds.height)
        terminalFrame = terminalFrame.insetBy(dx: dx, dy: dy)
        (_, terminalFrame) = terminalFrame.divided(atDistance: perpendicularInset, from: direction)
        terminalOutline.frame = terminalFrame
        terminalOutline.borderWidth = bodyOutline.borderWidth

        // cover terminal opening
        var (_, coverFrame) = terminalFrame.divided(atDistance: perpendicularInset, from: direction)
        (dx, dy) = isVertical ? (perpendicularInset, -0.25) : (-0.25, perpendicularInset)
        coverFrame = coverFrame.insetBy(dx: dx, dy: dy)
        terminalOpening.frame = coverFrame
        if (fillTerminalWithBorder) {
            terminalOpening.backgroundColor = borderColor.cgColor;
        } else {
            terminalOpening.backgroundColor = noLevelColor.cgColor
        }

        // layout empty levelFill
        levelFill.frame = bodyFrame.insetBy(dx: perpendicularInset, dy: perpendicularInset).integral
        levelFill.backgroundColor = noLevelColor.cgColor
    }

    private func layoutLevel() {
        var levelFrame = bodyOutline.bounds.insetBy(dx: bodyOutline.borderWidth, dy: bodyOutline.borderWidth)
        if level >= 0 && level <= Self.fullBattery {
            let levelInset = (isVertical ? levelFrame.height : levelFrame.width) * CGFloat(Self.fullBattery - level) / CGFloat(Self.fullBattery)
            (_, levelFrame) = levelFrame.divided(atDistance: levelInset, from: direction)
            noLevelLabel.text = nil
            accessibilityValue = level.description
        } else {
            noLevelLabel.text = noLevelText
            noLevelLabel.sizeToFit()
            accessibilityValue = noLevelText
        }
        levelFill.frame = levelFrame.integral
        layoutCornerRadius()
        layoutFillColor()
    }

    private func layoutFillColor() {
        levelFill.backgroundColor = currentFillColor.cgColor
        if (fillTerminalWithBorder) {
            terminalOpening.backgroundColor = borderColor.cgColor;
        } else {
            switch level {
            case Self.fullBattery:
                terminalOpening.backgroundColor = currentFillColor.cgColor
            case 0 ..< Self.fullBattery:
                terminalOpening.backgroundColor = (backgroundColor ?? Self.background).cgColor
            default:
                terminalOpening.backgroundColor = noLevelColor.cgColor
            }
        }
    }

    private func layoutCornerRadius() {
        bodyOutline.cornerRadius = cornerRadius != 0 ? cornerRadius : length / 10
        terminalOutline.cornerRadius = bodyOutline.cornerRadius / 2
    }
}
