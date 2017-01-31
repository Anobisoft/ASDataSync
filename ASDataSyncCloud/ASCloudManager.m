//
//  ASCloudManager.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASCloudManager.h"
#import <CloudKit/CloudKit.h>
#import "ASDeviceList.h"
#import "ASCloudRecord.h"
#import "ASCloudReference.h"
#import "ASCloudTransaction.h"
#import "ASPrivateProtocol.h"
#import "NSUUID+NSData.h"

typedef void (^FetchRecord)(__kindof ASCloudRecord *record);
typedef void (^FetchRecordsArray)(NSArray <__kindof ASCloudRecord *> *records);

typedef NS_ENUM(NSUInteger, ASCloudState) {
    ASCloudStateAccountStatusAvailable = 1 << 0,
    ASCloudStateDeviceUpdated = 1 << 1,
    ASCloudStateDevicesReloaded = 1 << 2,
};


#define kASCloudManagerLastSyncDateForEntityDictionary @"ASCloudManagerLastSyncDateForEntityDictionary"
#define kASCloudObjectDeletionInfoRecordType @"DeleteQueue"

@interface ASCloudManager() <ASCloudManager>
    @property (nonatomic, strong, readonly) NSDictionary <NSString *, NSDate *> *lastSyncDateForEntity;

@end

@implementation ASCloudManager {
    ASCloudState state;
    CKContainer *container;
    CKDatabase *db;
    id <ASDataSyncContextPrivate> syncContext;
    ASDeviceList *deviceList;
    NSMutableArray <CKRecord *> *recordsToSave;
    NSMutableArray <CKRecordID *> *recordIDsToDelete;
    NSMutableSet <ASCloudRecord *> *_updatedRecords, *_deletionInfoRecords;
    dispatch_group_t enqueueUpdateWithSyncronizableObjectGroup;
    dispatch_group_t reloadAllMappedRecordsTotalGroup;
    dispatch_queue_t waitingQueue;
}

#pragma mark - ASCloudManager

- (BOOL)ready {
    ASCloudState requiredState = ASCloudStateAccountStatusAvailable | ASCloudStateDeviceUpdated | ASCloudStateDevicesReloaded;
    return (state & requiredState) == requiredState;
}

- (NSSet<id<ASMappedObject>> *)updatedRecords {
    return _updatedRecords.copy;
}

- (NSSet<id<ASMappedObject>> *)deletionInfoRecords {
    return _deletionInfoRecords.copy;
}

- (void)setDataSyncContext:(id<ASDataSyncContextPrivate>)context {
    syncContext = context;
}

@synthesize mapping = _mapping;

#pragma mark - lastSyncDateForEntity

@synthesize lastSyncDateForEntity = _lastSyncDateForEntity;
NSMutableDictionary *lastSyncDateForEntityMutable;
- (NSDictionary <NSString *, NSDate *> *)lastSyncDateForEntity {
    if (!_lastSyncDateForEntity) {
        _lastSyncDateForEntity = [[NSUserDefaults standardUserDefaults] objectForKey:kASCloudManagerLastSyncDateForEntityDictionary];
        if (!_lastSyncDateForEntity) _lastSyncDateForEntity = @{};
    }
    return _lastSyncDateForEntity;
}
- (void)setLastSyncDate:(NSDate *)date forEntity:(NSString *)entity {
    if (date) {
        [lastSyncDateForEntityMutable setObject:date forKey:entity];
    } else {
        [lastSyncDateForEntityMutable removeObjectForKey:entity];
    }
    _lastSyncDateForEntity = lastSyncDateForEntityMutable.copy;
    [[NSUserDefaults standardUserDefaults] setObject:_lastSyncDateForEntity forKey:kASCloudManagerLastSyncDateForEntityDictionary];
}

#pragma mark - initialization

+ (instancetype)new {
    return [self defaultManager];
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)defaultManager {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [super init]) {
        lastSyncDateForEntityMutable = self.lastSyncDateForEntity.mutableCopy;
        deviceList = [ASDeviceList defaultList];
        enqueueUpdateWithSyncronizableObjectGroup = dispatch_group_create();
        waitingQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (void)initContainerWithIdentifier:(NSString *)identifier {
    [self initContainerWithIdentifier:identifier entityMapping:nil];
}

- (void)initContainerWithIdentifier:(NSString *)identifier entityMapping:(ASCloudMapping *)mapping {
    container = [CKContainer containerWithIdentifier:identifier];
    if (mapping) {
        _mapping = mapping;
    }
    
    [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * _Nullable error) {
        if (error) NSLog(@"%@", [error localizedDescription]);
        else {
            if (accountStatus == CKAccountStatusAvailable) {
                state |= ASCloudStateAccountStatusAvailable;                
#ifdef DEBUG
                db = container.publicCloudDatabase;
#else
                db = container.privateCloudDatabase;
#endif
                [self updateDevices];
            } else {
                state ^= state & ASCloudStateAccountStatusAvailable;
            }
        }
    }];
}

#pragma mark - Remote notification accepting

typedef void (^SaveSubscriptionCompletionHandler)(CKSubscription * _Nullable subscription, NSError * _Nullable error);

- (void)subscribeToRegisteredRecordTypes {
    SaveSubscriptionCompletionHandler completionHandler = ^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
        if (error) {
            CKQuerySubscription *qsubs = (CKQuerySubscription *)subscription;
            NSLog(@"[ERROR] failed to subscribe to %@. %@", qsubs.recordType, error.localizedDescription);
        }
    };
    for (NSString *recordType in self.mapping.reverseMap.allKeys) {
        CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:recordType predicate:[NSPredicate predicateWithValue:YES] options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
        [db saveSubscription:subscription completionHandler:completionHandler];
    }
    
    CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:kASCloudObjectDeletionInfoRecordType predicate:[NSPredicate predicateWithFormat:@"dq_deviceID == %@", [ASDeviceList defaultList].thisDevice.UUIDString] options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    [db saveSubscription:subscription completionHandler:completionHandler];
    

}

- (void)acceptPushNotificationWithUserInfo:(NSDictionary *)userInfo {
    CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    if (notification.notificationType == CKNotificationTypeQuery && notification.containerIdentifier == container.containerIdentifier) {
        CKQueryNotification *queryNotification = (CKQueryNotification *)notification;
        [self recordByRecordID:queryNotification.recordID fetch:^(ASCloudRecord *record) {
            if (!self.ready) @throw [NSException exceptionWithName:@"ASCloudManager not ready" reason:@"" userInfo:nil];
            if (record) {
                NSString *entityName = self.mapping.reverseMap[record.recordType];
                if ([record.recordType isEqualToString:[ASDevice entityName]]) {
                    ASDevice *device = [ASDevice deviceWithMappedObject:record];
                    NSLog(@"[DEBUG] create device.UUIDString %@", device.UUIDString);
                    [deviceList addDevice:device];
                } else if ([record.recordType isEqualToString:kASCloudObjectDeletionInfoRecordType]) {
                    [_deletionInfoRecords addObject:record];
                    [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:_updatedRecords deletionInfoRecords:_deletionInfoRecords mapping:self.mapping]];
                    [_deletionInfoRecords removeAllObjects];
                } else if (entityName) {
                    [_updatedRecords addObject:record];
                    [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:_updatedRecords deletionInfoRecords:_deletionInfoRecords mapping:self.mapping]];
                    [_updatedRecords removeAllObjects];
                }

            } else {
                @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"  reason:[NSString stringWithFormat:@"Object with recordID %@ not found.", queryNotification.recordID.recordName] userInfo:nil];
            }
        }];
    }
}

- (void)willCommitTransaction:(id<ASRepresentableTransaction>)transaction {
    NSSet <id <ASMappedObject>> *updatedObjects = transaction.updatedObjects;
    NSSet <id <ASDescription>> *deletedObjects = transaction.deletedObjects;
    for (id <ASMappedObject> mappedObject in updatedObjects) {
        [self enqueueUpdateWithMappedObject:mappedObject];
    }
    for (id <ASDescription> description in deletedObjects) {
        [self enqueueDeletionWithDescription:description];
    }
    [self pushQueueWithSuccessBlock:nil];
}

- (void)updateDevices {
    ASDevice *thisDevice = [deviceList thisDevice];
    NSLog(@"ASDevice thisDevice %@", thisDevice.UUIDString);
    [self enqueueUpdateWithMappedObject:thisDevice];
    [self pushQueueWithSuccessBlock:^(BOOL success) {
        if (success) {
            state |= ASCloudStateDeviceUpdated;
            [self reloadDevises];
        } else {
            state ^= state & ASCloudStateDeviceUpdated;
        }
    }];
}

- (void)reloadDevises {
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
    [self getAllRecordsOfEntityName:[ASDevice entityName] fetch:^(NSArray<__kindof ASCloudRecord *> *records) {
        if (records) {
            for (ASCloudRecord *record in records) {
                ASDevice *device = [ASDevice deviceWithMappedObject:record];
                NSLog(@"[DEBUG] create device.UUIDString %@", device.UUIDString);
                [deviceList addDevice:device];
            }
            state |= ASCloudStateDevicesReloaded;
            [self subscribeToRegisteredRecordTypes];
            NSLog(@"deviceList %@", deviceList.devices);
        } else {
            state ^= state & ASCloudStateDevicesReloaded;
        }
    }];
}

- (void)reloadAllMappedRecordsTotal:(BOOL)total {
    for (NSString *entityName in self.mapping.map.allKeys) {
        FetchRecordsArray fetchArrayBlock = ^(NSArray<__kindof ASCloudRecord *> *records) {
            for (ASCloudRecord *record in records) {
                [_updatedRecords addObject:record];
            }
            dispatch_group_leave(reloadAllMappedRecordsTotalGroup);
        };
        dispatch_group_enter(reloadAllMappedRecordsTotalGroup);
        if (total) {
            [self getAllRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        } else {
            [self getNewRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        }
        
    }
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(reloadAllMappedRecordsTotalGroup, DISPATCH_TIME_FOREVER);
        [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:_updatedRecords deletionInfoRecords:_deletionInfoRecords mapping:self.mapping]];
        [_updatedRecords removeAllObjects];
        [_deletionInfoRecords removeAllObjects];
    });

}



- (void)getAllRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
    [self setLastSyncDate:nil forEntity:entityName];
    [self getNewRecordsOfEntityName:entityName fetch:fetch];
}

- (void)getNewRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
    NSDate *lastSyncDate = self.lastSyncDateForEntity[entityName];
    NSDate *queryDate = [NSDate date];
    
    NSMutableArray *foundedRecords = [NSMutableArray new];
    void (^recordFetchedBlock)(CKRecord * _Nonnull record) = ^(CKRecord * _Nonnull record) {
        [foundedRecords addObject:record];
    };
    
    void (^queryCompletionBlock)(CKQueryCursor * _Nullable cursor, NSError * _Nullable operationError) = ^(CKQueryCursor * _Nullable cursor, NSError * _Nullable operationError) {
        if (operationError) {
            fetch(nil);
        } else {
            if (cursor) {
                CKQueryOperation *fetchNext = [[CKQueryOperation alloc] initWithCursor:cursor];
                fetchNext.recordFetchedBlock = recordFetchedBlock;
                fetchNext.queryCompletionBlock = queryCompletionBlock;
                [db addOperation:fetchNext];
            } else {
                [self setLastSyncDate:queryDate forEntity:entityName];
                fetch(foundedRecords.copy);
            }
        }
    };
    NSPredicate *clause = lastSyncDate ? [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate] : [NSPredicate predicateWithValue:true];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:self.mapping.map[entityName] predicate:clause];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    queryOperation.recordFetchedBlock = recordFetchedBlock;
    queryOperation.queryCompletionBlock = queryCompletionBlock;
    
    [db addOperation:queryOperation];
    
}

- (void)recordByRecordID:(CKRecordID *)recordID fetch:(void (^)(ASCloudRecord *record))fetch {
    CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
    NSMutableArray *foundedRecords = [NSMutableArray new];
    
    [fetchOperation setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * _Nullable frecordID, NSError * _Nullable operationError) {
        if (operationError) {
            NSLog(@"FetchRecordsOperation Error: %@", operationError);
        } else {
            NSLog(@"FetchRecordsOperation PerRecordCompletion");
            [foundedRecords addObject:record];
        }
    }];
    
    [fetchOperation setCompletionBlock:^{
        if (foundedRecords.count) {
            if (foundedRecords.count > 1) @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"  reason:[NSString stringWithFormat:@"Unique constraint violated: duplicated recordID %@", recordID.recordName] userInfo:nil];
            fetch(foundedRecords.firstObject);
        } else {
            fetch(nil);
        }
    }];
    fetchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    fetchOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [db addOperation:fetchOperation];
}

- (void)enqueueUpdateWithMappedObject:(id <ASMappedObject>)syncObject {
    dispatch_group_enter(enqueueUpdateWithSyncronizableObjectGroup);
    ASCloudID *recordID = [ASCloudID cloudIDWithUUIDString:syncObject.UUIDString];
    [self recordByRecordID:recordID fetch:^(ASCloudRecord *record) {
        if (record) {
            if ([record.modificationDate compare:syncObject.modificationDate] != NSOrderedAscending) {
                dispatch_group_leave(enqueueUpdateWithSyncronizableObjectGroup);
                return ; // record update no needed
            }
             
        } else {
            record = [ASCloudRecord recordWithRecordType:syncObject.entityName recordID:recordID];
        }
        record.keyedDataProperties = syncObject.keyedDataProperties;
        record.modificationDate = syncObject.modificationDate;
        [recordsToSave addObject:record];
        dispatch_group_leave(enqueueUpdateWithSyncronizableObjectGroup);
    }];
}

- (void)enqueueDeletionWithDescription:(id <ASDescription>)description {
    ASCloudID *recordID = [ASCloudID cloudIDWithUUIDString:description.UUIDString];
    [recordIDsToDelete addObject:recordID];
    for (ASDevice *device in [ASDeviceList defaultList]) {
        ASCloudRecord *deletionInfo = [ASCloudRecord recordWithRecordType:kASCloudObjectDeletionInfoRecordType];
        deletionInfo[@"dq_recordType"] = self.mapping.map[description.entityName];
        deletionInfo[@"dq_recordID"] = description.UUIDString;
        deletionInfo[@"dq_deviceID"] = device.UUIDString;
        [recordsToSave addObject:deletionInfo];
    }
}

- (void)pushQueueWithSuccessBlock:(void (^)(BOOL success))successBlock {
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(enqueueUpdateWithSyncronizableObjectGroup, DISPATCH_TIME_FOREVER);
        CKModifyRecordsOperation *mop = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsToSave.copy recordIDsToDelete:recordIDsToDelete.copy];
        NSUInteger recordsToSaveCount = recordsToSave.count;
        NSUInteger recordIDsToDeleteCount = recordIDsToDelete.count;
        [mop setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (operationError) {
                NSLog(@"[ERROR] CKModifyRecordsOperation Error: %@", operationError);
                successBlock(false);
            } else {
                if (savedRecords.count == recordsToSaveCount && deletedRecordIDs.count == recordIDsToDeleteCount) {
                    NSLog(@"[DEBUG] CKModifyRecordsOperation OK");
                    successBlock(true);
                    [recordsToSave removeAllObjects];
                    [recordIDsToDelete removeAllObjects];
                } else {
                    NSLog(@"[ERROR] CKModifyRecordsOperation checksum failed: recordsToSaveCount %ld / recordIDsToDeleteCount %ld", (unsigned long)recordsToSaveCount, (unsigned long)recordIDsToDeleteCount);
                    successBlock(false);
                }
            }
        }];
        mop.queuePriority = NSOperationQueuePriorityVeryHigh;
        mop.qualityOfService = NSQualityOfServiceUserInteractive;
        [db addOperation:mop];
    });
    
}



@end
