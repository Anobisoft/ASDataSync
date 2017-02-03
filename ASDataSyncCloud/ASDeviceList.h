//
//  ASDeviceList.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASDevice.h"

@interface ASDeviceList : NSObject <NSFastEnumeration>

- (ASDevice *)thisDevice;
- (void)addDevice:(ASDevice *)device;
- (NSArray <ASDevice *> *)devices;


@end
