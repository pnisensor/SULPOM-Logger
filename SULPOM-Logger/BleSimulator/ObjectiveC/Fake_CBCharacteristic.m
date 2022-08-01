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

#import "Fake_CBCharacteristic.h"

@implementation Fake_CBCharacteristic : CBCharacteristic;

@synthesize _uuid;
@synthesize _value;
@synthesize _isNotifying;
@synthesize _service;

+ (id) createInstance:(NSString*)uuid {
    Fake_CBCharacteristic* newInstance = [[NSClassFromString(NSStringFromClass([self class])) alloc] init];

    newInstance._uuid = [CBUUID UUIDWithString:uuid];
    newInstance._isNotifying = FALSE;
    
    return newInstance;
}

// Get mock uuid.
- (CBUUID*) UUID {
    return _uuid;
}

// Get mock response data.
- (NSData*) value {
    return _value;
}

// Get mock notifying status.
- (BOOL) isNotifying {
    return _isNotifying;
}

- (CBService*) service {
    return _service;
}

@end

#endif
