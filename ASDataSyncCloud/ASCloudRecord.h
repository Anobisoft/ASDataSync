//
//  ASCloudRecord.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2017-01-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASPublicProtocol.h"

@class ASCloudReference, ASMapping;

@interface ASCloudRecord : CKRecord <ASCloudRelatableRecord>

+ (instancetype)recordWithRecordType:(NSString *)recordType recordID:(ASCloudReference *)recordID;
+ (instancetype)recordWithRecordType:(NSString *)recordType;
+ (id <ASCloudDescription>)cloudDescriptionWithDeletionInfo:(ASCloudRecord *)cloudRecord;

@end
