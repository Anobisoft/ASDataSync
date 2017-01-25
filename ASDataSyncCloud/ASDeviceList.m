//
//  ASDeviceList.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASDeviceList.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "NSUUID+NSData.h"

NSString* machine()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}


@implementation ASDeviceList {
    NSMutableDictionary *mutableStore;
    ASDevice *thisDevice;
}

+ (instancetype)new {
    return [self defaultList];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)defaultList {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}


static NSString *thisDeviceVersion;
- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        mutableStore = [NSMutableDictionary new];
        
        thisDevice = [ASDevice new];
        thisDevice.uniqueData = [UIDevice currentDevice].identifierForVendor.data;
        thisDeviceVersion = [
        @{
          @"iPod5,1"    : @"iPod Touch 5",
          @"iPod7,1"    : @"iPod Touch 6",
          @"iPhone3,1"  : @"iPhone 4",
          @"iPhone3,2"  : @"iPhone 4",
          @"iPhone3,3"  : @"iPhone 4",
          @"iPhone4,1"  : @"iPhone 4s",
          @"iPhone5,1"  : @"iPhone 5",
          @"iPhone5,2"  : @"iPhone 5",
          @"iPhone5,3"  : @"iPhone 5c",
          @"iPhone5,4"  : @"iPhone 5c",
          @"iPhone6,1"  : @"iPhone 5s",
          @"iPhone6,2"  : @"iPhone 5s",
          @"iPhone7,2"  : @"iPhone 6",
          @"iPhone7,1"  : @"iPhone 6 Plus",
          @"iPhone8,1"  : @"iPhone 6s",
          @"iPhone8,2"  : @"iPhone 6s Plus",
          @"iPhone9,1"  : @"iPhone 7",
          @"iPhone9,3"  : @"iPhone 7",
          @"iPhone9,2"  : @"iPhone 7 Plus",
          @"iPhone9,4"  : @"iPhone 7 Plus",
          @"iPhone8,4"  : @"iPhone SE",
          @"iPad2,1"    : @"iPad 2",
          @"iPad2,2"    : @"iPad 2",
          @"iPad2,3"    : @"iPad 2",
          @"iPad2,4"    : @"iPad 2",
          @"iPad3,1"    : @"iPad 3",
          @"iPad3,2"    : @"iPad 3",
          @"iPad3,3"    : @"iPad 3",
          @"iPad3,4"    : @"iPad 4",
          @"iPad3,5"    : @"iPad 4",
          @"iPad3,6"    : @"iPad 4",
          @"iPad4,1"    : @"iPad Air",
          @"iPad4,2"    : @"iPad Air",
          @"iPad4,3"    : @"iPad Air",
          @"iPad5,3"    : @"iPad Air 2",
          @"iPad5,4"    : @"iPad Air 2",
          @"iPad2,5"    : @"iPad Mini",
          @"iPad2,6"    : @"iPad Mini",
          @"iPad2,7"    : @"iPad Mini",
          @"iPad4,4"    : @"iPad Mini 2",
          @"iPad4,5"    : @"iPad Mini 2",
          @"iPad4,6"    : @"iPad Mini 2",
          @"iPad4,7"    : @"iPad Mini 3",
          @"iPad4,8"    : @"iPad Mini 3",
          @"iPad4,9"    : @"iPad Mini 3",
          @"iPad5,1"    : @"iPad Mini 4",
          @"iPad5,2"    : @"iPad Mini 4",
          @"iPad6,3"    : @"iPad Pro",
          @"iPad6,4"    : @"iPad Pro",
          @"iPad6,7"    : @"iPad Pro",
          @"iPad6,8"    : @"iPad Pro",
          @"AppleTV5,3" : @"Apple TV",
          @"i386"       : @"Simulator",
          @"x86_64"     : @"Simulator",
          } objectForKey: machine()];
        
        [self updateThisDeviceInfo];
    }
    return self;
}

- (void)updateThisDeviceInfo {
    thisDevice.keyedProperties = @{ @"name" : [[UIDevice currentDevice] name],
                                    @"model" : [[UIDevice currentDevice] model],
                                    @"version" : thisDeviceVersion,
                                    @"system" : [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]],
                                    };
    thisDevice.modificationDate = [NSDate date];
}

- (ASDevice *)thisDevice {
    [self updateThisDeviceInfo];
    return thisDevice;
}

- (void)addDevice:(ASDevice *)device {
    if (device && ![device.uniqueData isEqualToData:thisDevice.uniqueData]) {
        [mutableStore setObject:device forKey:device.UUIDString];
    }
}

- (NSArray<ASDevice *> *)devices {
    return mutableStore.allValues;
}

#pragma mark - Overload

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [mutableStore countByEnumeratingWithState:state objects:buffer count:len];
}

- (ASDevice *)deviceForUniqueID:(NSData *)uniqueID {
    return [mutableStore objectForKey:uniqueID];
}

- (NSEnumerator *)objectEnumerator {
    return mutableStore.objectEnumerator;
}

- (NSArray *)allKeys {
    return mutableStore.allKeys;
}

- (NSArray *)allValues {
    return mutableStore.allValues;
}

- (NSUInteger)count {
    return mutableStore.count;
}

- (NSArray *)allKeysForObject:(id)anObject {
    return [mutableStore allKeysForObject:anObject];
}



@end
