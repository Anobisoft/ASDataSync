//
//  ASCloudManager.m
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <CloudKit/CloudKit.h>
#import "ASCloudManager.h"

#import "ASDeviceList.h"
#import "ASPrivateProtocol.h"
#import "NSUUID+NSData.h"

#import "ASCloudTransaction.h"
#import "ASCloudRecordRepresentation.h"
#import "ASCloudDescriptionRepresentation.h"
#import "CKRecord+ASDataSync.h"
#import "CKRecordID+ASDataSync.h"
#import "CKReference+ASDataSync.h"

#import "ASCloudInternalConst.h"

typedef void (^FetchRecord)(__kindof CKRecord *record);
typedef void (^FetchRecordsArray)(NSArray <__kindof CKRecord *> *records);

typedef NS_ENUM(NSUInteger, ASCloudState) {
    ASCloudStateAccountStatusAvailable = 1 << 0,
    ASCloudStateDeviceUpdated = 1 << 1,
    ASCloudStateDevicesReloaded = 1 << 2,
};

@interface ASCloudManager() <ASCloudManager>
    @property (nonatomic, strong, readonly) NSDictionary <NSString *, NSDate *> *lastSyncDateForEntity;

@end

@implementation ASCloudManager {
    ASCloudState state;
    CKContainer *container;
    CKDatabase *db;
    id <ASDataSyncContextPrivate, ASCloudMappingProvider> syncContext;
    ASDeviceList *deviceList;
    NSMutableArray <CKRecord *> *recordsToSave;
    NSMutableArray <CKRecordID *> *recordIDsToDelete;
    NSMutableSet <CKRecord *> *_cloudUpdatedRecords, *_cloudUpdatedDeletionInfoRecords;
    dispatch_group_t enqueueUpdateWithSyncronizableObjectGroup;
    dispatch_group_t reloadAllMappedRecordsTotalGroup;
    dispatch_group_t reloadDevicesGroup;
    dispatch_queue_t waitingQueue;
    
    
    
}

- (NSSet <CKRecord <ASMappedObject> *> *)cloudUpdatedRecords {
    return _cloudUpdatedRecords.copy;
}

- (NSSet <CKRecord <ASMappedObject> *> *)cloudUpdatedDeletionInfoRecords {
    return _cloudUpdatedDeletionInfoRecords.copy;
}

#pragma mark - ASCloudManager

- (BOOL)ready {
    ASCloudState requiredState = ASCloudStateAccountStatusAvailable | ASCloudStateDeviceUpdated | ASCloudStateDevicesReloaded;
    return (state & requiredState) == requiredState;
}

- (NSSet<CKRecord<ASMappedObject> *> *)updatedRecords {
    return _cloudUpdatedRecords.copy;
}

- (NSSet<CKRecord<ASMappedObject> *> *)deletionInfoRecords {
    return _cloudUpdatedDeletionInfoRecords.copy;
}

- (void)setDataSyncContext:(id<ASDataSyncContextPrivate, ASCloudMappingProvider>)context {
    syncContext = context;
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(reloadDevicesGroup, DISPATCH_TIME_FOREVER);
        [self subscribeToRegisteredRecordTypes];
        [self startReplication];
    });
}

- (ASCloudMapping *)mapping {
    return syncContext.cloudMapping;
}

- (id<ASDataSyncContextPrivate, ASCloudMappingProvider>)dataSyncContext {
    return syncContext;
}

- (void)startReplication {
    [self reloadAllMappedRecordsTotal:NO completion:^{
#warning select newest local records
    }];
}


#pragma mark - lastSyncDateForEntity

@synthesize lastSyncDateForEntity = _lastSyncDateForEntity;
NSMutableDictionary *lastSyncDateForEntityMutable;
- (NSDictionary <NSString *, NSDate *> *)lastSyncDateForEntity {
    if (!_lastSyncDateForEntity) {
        _lastSyncDateForEntity = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-%@", ASCloudLastSyncDateForEntityUDKey, container.containerIdentifier]];
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
    [[NSUserDefaults standardUserDefaults] setObject:_lastSyncDateForEntity forKey:[NSString stringWithFormat:@"%@-%@", ASCloudLastSyncDateForEntityUDKey, container.containerIdentifier]];
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
        shared = [[self alloc] initUniqueInstance];
    });
    return shared;
}

- (instancetype)initUniqueInstance {
    if (self = [self init]) {
        
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        recordsToSave = [NSMutableArray new];
        recordIDsToDelete = [NSMutableArray new];
        _cloudUpdatedRecords = [NSMutableSet new];
        _cloudUpdatedDeletionInfoRecords = [NSMutableSet new];
        
        lastSyncDateForEntityMutable = self.lastSyncDateForEntity.mutableCopy;
        deviceList = [ASDeviceList defaultList];
        enqueueUpdateWithSyncronizableObjectGroup = dispatch_group_create();
        reloadAllMappedRecordsTotalGroup = dispatch_group_create();
        reloadDevicesGroup = dispatch_group_create();
        waitingQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (instancetype)initWithContainerIdentifier:(NSString *)identifier {
    if (self = [self init]) {
        container = [CKContainer containerWithIdentifier:identifier];
        dispatch_group_enter(reloadDevicesGroup);
        [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
                dispatch_group_leave(reloadDevicesGroup);
            } else {
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
    return self;
}

#pragma mark - Remote notification accepting

typedef void (^SaveSubscriptionCompletionHandler)(CKSubscription * _Nullable subscription, NSError * _Nullable error);

- (void)subscribeToRegisteredRecordTypes {
    SaveSubscriptionCompletionHandler completionHandler = ^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] SaveSubscription failed: %@", error.localizedDescription);
        }
    };
    for (NSString *recordType in self.mapping.allRecordTypes) {
        NSLog(@"subscribeToRecordType %@", recordType);
        CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:recordType predicate:[NSPredicate predicateWithValue:YES] options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
        [db saveSubscription:subscription completionHandler:completionHandler];
    }
    
    NSPredicate *thisDeviceFilter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ == %%@", ASCloudDeletionInfoRecordProperty_deviceID], [ASDeviceList defaultList].thisDevice.UUIDString];
    CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:ASCloudDeletionInfoRecordType predicate:thisDeviceFilter options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    [db saveSubscription:subscription completionHandler:completionHandler];
    

}

- (void)acceptPushNotificationWithUserInfo:(NSDictionary *)userInfo {
    CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    if (notification.notificationType == CKNotificationTypeQuery && notification.containerIdentifier == container.containerIdentifier) {
        CKQueryNotification *queryNotification = (CKQueryNotification *)notification;
        [self recordByRecordID:queryNotification.recordID fetch:^(CKRecord <ASMappedObject>*record) {
            if (!self.ready) @throw [NSException exceptionWithName:@"ASCloudManager not ready" reason:@"" userInfo:nil];
            if (record) {
                NSString *entityName = self.mapping[record.recordType];
                if ([record.recordType isEqualToString:[ASDevice entityName]]) {
                    ASDevice *device = [ASDevice deviceWithMappedObject:(CKRecord <ASMappedObject> *)record];
                    NSLog(@"[DEBUG] create device.UUIDString %@", device.UUIDString);
                    [deviceList addDevice:device];
                } else if ([record.recordType isEqualToString:ASCloudDeletionInfoRecordType]) {
                    [_cloudUpdatedDeletionInfoRecords addObject:record];
                    [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:self.cloudUpdatedRecords
                                                                                           deletionInfoRecords:self.cloudUpdatedDeletionInfoRecords
                                                                                                       mapping:self.mapping]];
                    [_cloudUpdatedDeletionInfoRecords removeAllObjects];
                } else if (entityName) {
                    [_cloudUpdatedRecords addObject:record];
                    [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:self.cloudUpdatedRecords
                                                                                           deletionInfoRecords:self.cloudUpdatedDeletionInfoRecords
                                                                                                       mapping:self.mapping]];
                    [_cloudUpdatedRecords removeAllObjects];
                }

            } else {
                @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"  reason:[NSString stringWithFormat:@"Object with recordID %@ not found.", queryNotification.recordID.recordName] userInfo:nil];
            }
        }];
    }
}

- (void)willCommitTransaction:(id<ASRepresentableTransaction>)transaction {
    NSSet <NSObject<ASMappedObject> *> *updatedObjects = transaction.updatedObjects;
    NSSet <NSObject<ASDescription> *> *deletedObjects = transaction.deletedObjects;
    for (NSObject<ASMappedObject> *mappedObject in updatedObjects) {
        [self enqueueUpdateWithMappedObject:mappedObject];
    }
    for (NSObject<ASDescription> *description in deletedObjects) {
        [self enqueueDeletionWithDescription:description];
    }
    [self pushQueueWithSuccessBlock:nil];
}

- (void)updateDevices {
    ASDevice *thisDevice = [deviceList thisDevice];
    NSLog(@"ASDevice thisDevice %@ %@", thisDevice, thisDevice.UUIDString);
    [self enqueueUpdateWithMappedObject:thisDevice];
    [self pushQueueWithSuccessBlock:^(BOOL success) {
        if (success) {
            state |= ASCloudStateDeviceUpdated;
            [self reloadDevises];
        } else {
            state ^= state & ASCloudStateDeviceUpdated;
            dispatch_group_leave(reloadDevicesGroup);
        }
    }];
}

- (void)reloadDevises {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getAllRecordsOfEntityName:[ASDevice entityName] fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
            for (CKRecord<ASMappedObject> *record in records) {
                ASDevice *device = [ASDevice deviceWithMappedObject:record];
                NSLog(@"[DEBUG] create device.UUIDString %@", device.UUIDString);
                [deviceList addDevice:device];
            }
            state |= ASCloudStateDevicesReloaded;
            NSLog(@"deviceList %@", deviceList.devices);
        } else {
            state ^= state & ASCloudStateDevicesReloaded;
        }
        dispatch_group_leave(reloadDevicesGroup);
    }];
}

- (void)reloadAllMappedRecordsTotal:(BOOL)total completion:(void(^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    for (NSString *entityName in self.mapping.synchronizableEntities) {
        FetchRecordsArray fetchArrayBlock = ^(NSArray<__kindof CKRecord *> *records) {
            for (CKRecord *record in records) {
                [_cloudUpdatedRecords addObject:record];
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
    
    dispatch_group_enter(reloadAllMappedRecordsTotalGroup);
    [self getAllRecordsOfEntityName:ASCloudDeletionInfoRecordType fetch:^(NSArray<__kindof CKRecord *> *records) {
        for (CKRecord *record in records) {
            [_cloudUpdatedDeletionInfoRecords addObject:record];
        }
        dispatch_group_leave(reloadAllMappedRecordsTotalGroup);
    }];
    
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(reloadAllMappedRecordsTotalGroup, DISPATCH_TIME_FOREVER);
        [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:self.cloudUpdatedRecords
                                                                               deletionInfoRecords:self.cloudUpdatedDeletionInfoRecords
                                                                                           mapping:self.mapping]];
        [_cloudUpdatedRecords removeAllObjects];
        [_cloudUpdatedDeletionInfoRecords removeAllObjects];
        
    });

}



- (void)getAllRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self setLastSyncDate:nil forEntity:entityName];
    [self getNewRecordsOfEntityName:entityName fetch:fetch];
}

- (void)getNewRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
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
    CKQuery *query = [[CKQuery alloc] initWithRecordType:self.mapping[entityName] predicate:clause];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    queryOperation.recordFetchedBlock = recordFetchedBlock;
    queryOperation.queryCompletionBlock = queryCompletionBlock;
    
    [db addOperation:queryOperation];
    
}

- (void)recordByRecordID:(CKRecordID *)recordID fetch:(void (^)(CKRecord<ASMappedObject> *record))fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
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

- (void)enqueueUpdateWithMappedObject:(NSObject<ASMappedObject> *)syncObject {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_group_enter(enqueueUpdateWithSyncronizableObjectGroup);
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:syncObject.uniqueData.UUIDString];
    [self recordByRecordID:recordID fetch:^(CKRecord<ASMappedObject> *record) {
        if (record) {
            if ([record.modificationDate compare:syncObject.modificationDate] != NSOrderedAscending) {
                NSLog(@"[WARNING] Cloud record %@ up to date %@", record.UUIDString, record.modificationDate);
                dispatch_group_leave(enqueueUpdateWithSyncronizableObjectGroup);
                return ; // record update no needed
            }
        } else {
            NSLog(@"[DEBUG] Not Found. Create new recordID %@", recordID);
            record = (CKRecord<ASMappedObject> *)[CKRecord recordWithRecordType:syncObject.entityName recordID:recordID];
        }
        record.keyedDataProperties = syncObject.keyedDataProperties;
        record.modificationDate = syncObject.modificationDate;
        [recordsToSave addObject:record];
        dispatch_group_leave(enqueueUpdateWithSyncronizableObjectGroup);
    }];
}

- (void)enqueueDeletionWithDescription:(id <ASDescription>)description {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    NSLog(@"%@ description.uniqueData.UUIDString %@", description, description.uniqueData.UUIDString);
    if (!description.uniqueData) return;
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:description.uniqueData.UUIDString];
    [recordIDsToDelete addObject:recordID];
    for (ASDevice *device in [ASDeviceList defaultList]) {
        CKRecord *deletionInfo = [CKRecord recordWithRecordType:ASCloudDeletionInfoRecordType];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordType] = self.mapping[description.entityName];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordID] = description.uniqueData.UUIDString;
        deletionInfo[ASCloudDeletionInfoRecordProperty_deviceID] = device.UUIDString;
        [recordsToSave addObject:deletionInfo];
    }
}

- (void)pushQueueWithSuccessBlock:(void (^)(BOOL success))successBlock {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(enqueueUpdateWithSyncronizableObjectGroup, DISPATCH_TIME_FOREVER);
        CKModifyRecordsOperation *mop = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsToSave.copy recordIDsToDelete:recordIDsToDelete.copy];
        NSUInteger recordsToSaveCount = recordsToSave.count;
        NSLog(@"recordsToSaveCount %ld", recordsToSaveCount);
        NSUInteger recordIDsToDeleteCount = recordIDsToDelete.count;
        NSLog(@"recordIDsToDeleteCount %ld", recordIDsToDeleteCount);
        [mop setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (operationError) {
                NSLog(@"[ERROR] CKModifyRecordsOperation Error: %@", operationError);
                successBlock(false);
            } else {
                if (savedRecords.count == recordsToSaveCount && deletedRecordIDs.count == recordIDsToDeleteCount) {
                    NSLog(@"[DEBUG] CKModifyRecordsOperation OK");
                    if (successBlock) successBlock(true);
                    [recordsToSave removeAllObjects];
                    [recordIDsToDelete removeAllObjects];
                } else {
                    NSLog(@"[ERROR] CKModifyRecordsOperation checksum failed: recordsToSaveCount %ld / recordIDsToDeleteCount %ld", (unsigned long)recordsToSaveCount, (unsigned long)recordIDsToDeleteCount);
                    if (successBlock) successBlock(false);
                }
            }
        }];
        mop.queuePriority = NSOperationQueuePriorityVeryHigh;
        mop.qualityOfService = NSQualityOfServiceUserInteractive;
        [db addOperation:mop];
    });
    
}



@end
