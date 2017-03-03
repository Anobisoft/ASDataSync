//
//  NSUUID+NSData.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUUID (ASDataSync)

- (NSData *)data;
+ (instancetype)UUIDWithData:(NSData *)data;
+ (instancetype)UUIDWithUUIDString:(NSString *)UUIDString;

@end

@interface NSData (ASDataSync)

- (NSUUID *)UUID;
- (NSString *)UUIDString;

@end
