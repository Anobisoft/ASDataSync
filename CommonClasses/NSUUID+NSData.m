//
//  NSUUID+NSData.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "NSUUID+NSData.h"

@implementation NSUUID (ASDataSync)

- (NSData *)data {
    uuid_t bytes;
    [self getUUIDBytes:bytes];
    return [NSData dataWithBytes:bytes length:16];
}

+ (instancetype)UUIDWithData:(NSData *)data {
    uuid_t bytes;
    [data getBytes:bytes length:16];
    return [[self alloc] initWithUUIDBytes:bytes];
}

+ (instancetype)UUIDWithUUIDString:(NSString *)UUIDString {
    return [[self alloc] initWithUUIDString:UUIDString];
}

@end

@implementation NSData (ASDataSync)

- (NSUUID *)UUID {
    return [NSUUID UUIDWithData:self];
}

- (NSString *)UUIDString {
    return [NSUUID UUIDWithData:self].UUIDString;
}

@end
