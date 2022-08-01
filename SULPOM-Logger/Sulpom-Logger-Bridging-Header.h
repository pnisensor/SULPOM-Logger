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

//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

// NOTE: You can (at least) import C and ObjectiveC from here!

// Only import debug objective c if these symbols are defined.
#if IOS_SIMULATOR
#import "Fake_CBPeripheral.h"
#import "Fake_CBService.h"
#import "Fake_CBCharacteristic.h"
#endif // IOS_SIMULATOR
