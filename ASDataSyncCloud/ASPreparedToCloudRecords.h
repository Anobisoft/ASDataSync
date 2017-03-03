//
//  ASPreparedToCloudRecords.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"
#import "ASTransactionRepresentation.h"

@class CKRecord, CKRecordID;

@interface ASPreparedToCloudRecords : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly) NSArray<CKRecord *> *recordsToSave;
@property (nonatomic, strong, readonly) NSArray<CKRecordID *> *recordIDsToDelete;
@property (nonatomic, strong, readonly) NSArray<NSObject<ASMappedObject> *> *failedEnqueueUpdateObjects;
@property (nonatomic, strong) ASTransactionRepresentation *accumulativeTransaction;
@property (nonatomic, retain, readonly) dispatch_group_t lockGroup;

- (void)addRecordToSave:(CKRecord *)record;
- (void)addRecordIDToDelete:(CKRecordID *)recordID;
- (void)addFailedEnqueueUpdateObject:(NSObject<ASMappedObject> *)object;
- (BOOL)isEmpty;
- (void)clearAll;
- (void)clearWithSavedRecords:(NSArray<CKRecord *> *)savedRecords deletedRecordIDs:(NSArray<CKRecordID *> *)deletedRecordIDs;

@end
