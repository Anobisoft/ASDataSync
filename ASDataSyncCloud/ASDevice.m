//
//  ASDevice.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASDevice.h"

@implementation ASDevice {
    NSString *uuidString;
}

+ (NSString *)entityName {
    return @"Device";
}

- (NSString *)entityName {
    return [self.class entityName];
}

- (void)setUUIDString:(NSString *)UUIDString {
    uuidString = UUIDString;
    self.uniqueData = [[[NSUUID alloc] initWithUUIDString:UUIDString] data];
}

- (NSString *)UUIDString {
    if (!uuidString) {
        uuidString = self.uniqueData.UUIDString;
    }
    return uuidString;
}

//- (NSString *)entityName {
//    return [self.class entityName];
//}

@end
