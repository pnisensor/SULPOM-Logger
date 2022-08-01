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

class NstBase {
    private init() { }
    
    private static let BASE_URL = "https://us-central1-macro-coil-194519.cloudfunctions.net";
    
    enum Endpoints {
        static let getUploadData = "\(BASE_URL)/getUploadDataUrl";
        static let getToken = "\(BASE_URL)/getToken";
        static let generatedataId = "\(BASE_URL)/generateDataId"
        static let setDataMetadata = "\(BASE_URL)/setDataMetadata"
    }
}

