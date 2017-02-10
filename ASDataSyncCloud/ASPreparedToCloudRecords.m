//
//  ASPreparedToCloudRecords.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASPreparedToCloudRecords.h"
#import <CloudKit/CloudKit.h>
#import "ASObjectRepresentation.h"
#import "CKRecord+ASDataSync.h"

@implementation NSMutableArray(removeReference)

- (void)removeReference:(NSObject<ASReference> *)reference {
    NSUInteger foundReferenceIndex;
    NSMutableArray<NSObject<ASReference> *> *references = (NSMutableArray<NSObject<ASReference> *> *)self;
    for (foundReferenceIndex = 0; foundReferenceIndex < references.count; foundReferenceIndex++) {
        if ([references[foundReferenceIndex].uniqueData isEqualToData:reference.uniqueData]) break;
    }
    if (foundReferenceIndex != references.count) [self removeObjectAtIndex:foundReferenceIndex];
}

@end

@implementation ASPreparedToCloudRecords {
    NSMutableArray <CKRecord<ASReference> *> *mutableRecordsToSave;
    NSMutableArray <CKRecordID<ASReference> *> *mutableRecordIDsToDelete;
    NSMutableArray <ASObjectRepresentation *> *failedObjectsRepresentations;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self = [super init]) {
        mutableRecordsToSave = [aDecoder decodeObjectForKey:@"mutableRecordsToSave"];
        mutableRecordIDsToDelete = [aDecoder decodeObjectForKey:@"mutableRecordIDsToDelete"];
        failedObjectsRepresentations = [aDecoder decodeObjectForKey:@"failedObjectsRepresentations"];
        self.accumulativeTransaction = [aDecoder decodeObjectForKey:@"accumulativeTransaction"];
        _lockGroup = dispatch_group_create();
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:mutableRecordsToSave forKey:@"mutableRecordsToSave"];
    [aCoder encodeObject:mutableRecordIDsToDelete forKey:@"mutableRecordIDsToDelete"];
    [aCoder encodeObject:failedObjectsRepresentations forKey:@"failedObjectsRepresentations"];
    [aCoder encodeObject:self.accumulativeTransaction forKey:@"accumulativeTransaction"];
}

- (instancetype)init {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (self = [super init]) {
        mutableRecordsToSave = [NSMutableArray new];
        mutableRecordIDsToDelete = [NSMutableArray new];
        failedObjectsRepresentations = [NSMutableArray new];
        _lockGroup = dispatch_group_create();
    }
    return self;
}


@synthesize failedEnqueueUpdateObjects = _failedEnqueueUpdateObjects;
- (NSArray<id<ASMappedObject>> *)failedEnqueueUpdateObjectsRepresentations {
    if (!_failedEnqueueUpdateObjects) _failedEnqueueUpdateObjects = failedObjectsRepresentations.copy;
    return _failedEnqueueUpdateObjects;
}
- (void)addFailedEnqueueUpdateObject:(NSObject<ASMappedObject> *)object {
    _failedEnqueueUpdateObjects = nil;
    ASObjectRepresentation *representedObject = [ASObjectRepresentation instantiateWithMappedObject:object];
    [failedObjectsRepresentations removeReference:representedObject];
    [failedObjectsRepresentations addObject:representedObject];
}


@synthesize recordsToSave = _recordsToSave;
- (NSArray <CKRecord *> *)recordsToSave {
    if (!_recordsToSave) _recordsToSave = mutableRecordsToSave.copy;
    return _recordsToSave;
}
- (void)addRecordToSave:(CKRecord<ASReference> *)record {
    _recordsToSave = nil;
    [mutableRecordsToSave removeReference:record];
    [mutableRecordsToSave addObject:record];
    NSLog(@"[DEBUG] mutableRecordsToSave.count %ld", (unsigned long)mutableRecordsToSave.count);
    _failedEnqueueUpdateObjects = nil;
    [failedObjectsRepresentations removeReference:record];
}


@synthesize recordIDsToDelete = _recordIDsToDelete;
- (NSArray <CKRecordID *> *)recordIDsToDelete {
    if (!_recordIDsToDelete) _recordIDsToDelete = mutableRecordIDsToDelete.copy;
    return _recordIDsToDelete;
}
- (void)addRecordIDToDelete:(CKRecordID<ASReference> *)recordID {
    _recordIDsToDelete = nil;
    [mutableRecordIDsToDelete removeReference:recordID];
    [mutableRecordIDsToDelete addObject:recordID];
    NSLog(@"[DEBUG] mutableRecordIDsToDelete.count %ld", (unsigned long)mutableRecordIDsToDelete.count);
}

- (BOOL)isEmpty {
    return (mutableRecordsToSave.count + mutableRecordIDsToDelete.count + failedObjectsRepresentations.count) == 0;
}

- (void)clearAll {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    _recordsToSave = @[];
    [mutableRecordsToSave removeAllObjects];
    _recordIDsToDelete = @[];
    [mutableRecordIDsToDelete removeAllObjects];
}

- (void)clearWithSavedRecords:(NSArray<CKRecord<ASReference> *> *)savedRecords deletedRecordIDs:(NSArray<CKRecordID<ASReference> *> *)deletedRecordIDs {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    _recordsToSave = nil; _recordIDsToDelete = nil;
    for (CKRecord<ASReference> *record in savedRecords) [mutableRecordsToSave removeReference:record];
    for (CKRecordID<ASReference> *recordID in deletedRecordIDs) [mutableRecordIDsToDelete removeReference:recordID];
#ifdef DEBUG
    NSLog(@"[DEBUG] mutableRecordsToSave.count %ld mutableRecordIDsToDelete.count %ld", (unsigned long)mutableRecordsToSave.count, (unsigned long)mutableRecordIDsToDelete.count);
#endif
}



@end
