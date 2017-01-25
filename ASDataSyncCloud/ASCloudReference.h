//
//  ASCloudReference.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 25.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASPublicProtocol.h"

@interface ASCloudReference : CKRecordID <ASCloudReference>

+ (instancetype)recordIDWithUniqueData:(NSData *)uniqueData;
+ (instancetype)recordIDWithRecordName:(NSString *)recordName;
- (NSUUID *)UUID;

@end
