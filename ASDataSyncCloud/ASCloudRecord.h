//
//  ASCloudRecord.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASPublicProtocol.h"

@class ASCloudReference;

@interface ASCloudRecord : CKRecord <ASCloudRelatableRecord>

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(ASCloudReference *)recordID;

@end
