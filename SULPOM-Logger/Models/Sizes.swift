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

enum Sizes {
    enum TableViewRow {
        /// Use this for TableView rows that are to be temporarily hidden.
        static let hidden: CGFloat = 0.00000001;
        /// Use this for TableView rows that are to be hidden for the TableView's lifecycle.
        static let zero: CGFloat = 0;
    }
    
    enum TableViewHeader {
        /// Use for "plain" TableView header sections that are hidden.
        static let hiddenPlain: CGFloat = 0;
        /// Use for "grouped" TableView header sections that are hidden.
        static let hiddenGrouped: CGFloat = 0.00000001;
        /// Use for TableView header sections that are at the top of the table and have a single line of text.
        static let screenTopWithText: CGFloat = 36
        /// Use for TableView header sections with a single line of text.
        static let withText: CGFloat = 28;
        /// Use foe TableView header sections that have no text and are there for a small section gap.
        static let withoutText: CGFloat = 12;
    }
}
