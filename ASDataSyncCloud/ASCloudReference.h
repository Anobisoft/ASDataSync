//
//  ASCloudReference.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 25.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASPublicProtocol.h"

@interface CKRecordID(ASDataSync)
- (NSUUID *)UUID;
@end

@interface ASCloudID : CKRecordID <ASReference>

+ (instancetype)cloudIDWithUniqueData:(NSData *)uniqueData;
+ (instancetype)cloudIDWithUUIDString:(NSString *)UUIDString;

@end

@interface ASCloudReference : CKReference <ASReference>

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData;
+ (instancetype)referenceWithUUIDString:(NSString *)UUIDString;

@end
