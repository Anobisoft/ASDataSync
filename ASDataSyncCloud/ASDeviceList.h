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

+ (instancetype)defaultList;
- (ASDevice *)thisDevice;
- (void)addDevice:(ASDevice *)device;
- (ASDevice *)deviceForUniqueID:(NSData *)uniqueID;
- (NSArray <ASDevice *> *)devices;


@end
