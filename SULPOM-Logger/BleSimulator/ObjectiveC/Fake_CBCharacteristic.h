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

#ifndef Fake_CBCharacteristic_h
#define Fake_CBCharacteristic_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface Fake_CBCharacteristic : CBCharacteristic

/// Create a fake instance.
+ (id)createInstance:(NSString*)uuid;

@property(readwrite) CBUUID* _uuid;
@property(readwrite) NSData* _value;
@property(readwrite) BOOL _isNotifying;
@property(readwrite) CBService* _service;

@end

#endif /* Fake_CBCharacteristic_h */

#endif
