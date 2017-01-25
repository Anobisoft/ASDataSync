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

@interface ASCloudReference : CKRecordID <ASCloudReference>

+ (instancetype)referenceWithUniqueData:(NSData *)uniqueData;
+ (instancetype)referenceWithRecordName:(NSString *)recordName;

@end
