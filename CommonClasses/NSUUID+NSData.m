//
//  NSUUID+NSData.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "NSUUID+NSData.h"

@implementation NSUUID (NSData)

- (NSData *)data {
    uuid_t bytes;
    [self getUUIDBytes:bytes];
    return [NSData dataWithBytes:bytes length:16];
}

+ (instancetype)uuidWithData:(NSData *)data {
    uuid_t bytes;
    [data getBytes:bytes length:16];
    return [[self alloc] initWithUUIDBytes:bytes];
}

@end
