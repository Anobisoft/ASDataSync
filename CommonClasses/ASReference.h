//
//  ASReference.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#ifndef ASReference_h
#define ASReference_h

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"

@interface ASReference : NSObject <ASReference, NSCoding>

+ (instancetype)null;
+ (instancetype)instantiateWithReference:(id <ASReference>)reference;
- (NSString *)UUIDString;

@property (nonatomic, strong, readonly) NSData *uniqueData;

@end

#endif
