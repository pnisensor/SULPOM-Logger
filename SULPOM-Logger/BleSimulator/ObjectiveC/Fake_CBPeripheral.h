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

#if IOS_SIMULATOR

#ifndef Fake_CBPeripheral_h
#define Fake_CBPeripheral_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface Fake_CBPeripheral : CBPeripheral

+ (id)createInstance:(NSString*)uuid;

/// Set fake objects.
@property(readwrite) CBPeripheralState _state;
@property(readwrite) NSUUID* _identifier;

@end

#endif /* Fake_CBPeripheral_h */

#endif
