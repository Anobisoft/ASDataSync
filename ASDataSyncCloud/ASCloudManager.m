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
    - (void)setLastSyncDate:(NSDate *)date forEntity:(NSString *)entity;



@end

@implementation ASCloudManager {
    id <ASDataSyncContextPrivate, ASCloudMappingProvider> syncContext;
    
    ASCloudState state;
    CKContainer *container;
    CKDatabase *db;
    ASDeviceList *deviceList;
    NSPredicate *thisDevicePredicate;
    
    NSMutableArray <CKRecord *> *mutableRecordsToSave;
    NSMutableArray <CKRecordID *> *mutableRecordIDsToDelete;
    NSMutableSet <CKRecord *> *_remoteUpdatedRecords, *_remoteUpdatedDeletionInfoRecords;
    
    dispatch_group_t enqueueUpdateWithMappedObjectGroup;
    dispatch_group_t reloadMappedRecordsGroup;
    dispatch_group_t primaryInitializationGroup;
    dispatch_queue_t waitingQueue;
    
}

#pragma mark - Private Properties

- (NSSet <CKRecord <ASMappedObject> *> *)remoteUpdatedRecords {
    return _remoteUpdatedRecords.copy;
}

- (NSSet <CKRecord <ASMappedObject> *> *)remoteUpdatedDeletionInfoRecords {
    return _remoteUpdatedDeletionInfoRecords.copy;
}

@synthesize lastSyncDateForEntity = _lastSyncDateForEntity;
NSMutableDictionary *lastSyncDateForEntityMutable;
- (NSDictionary <NSString *, NSDate *> *)lastSyncDateForEntity {
    if (!_lastSyncDateForEntity) {
        _lastSyncDateForEntity = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-Private-%@", ASCloudLastSyncDateForEntityUDKey, container.containerIdentifier]];
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
    [[NSUserDefaults standardUserDefaults] setObject:_lastSyncDateForEntity forKey:[NSString stringWithFormat:@"%@-Private-%@", ASCloudLastSyncDateForEntityUDKey, container.containerIdentifier]];
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
        mutableRecordsToSave = [NSMutableArray new];
        mutableRecordIDsToDelete = [NSMutableArray new];
        _remoteUpdatedRecords = [NSMutableSet new];
        _remoteUpdatedDeletionInfoRecords = [NSMutableSet new];
        
        lastSyncDateForEntityMutable = self.lastSyncDateForEntity.mutableCopy;
        
        deviceList = [ASDeviceList new];
        
        enqueueUpdateWithMappedObjectGroup = dispatch_group_create();
        reloadMappedRecordsGroup = dispatch_group_create();
        primaryInitializationGroup = dispatch_group_create();
        waitingQueue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (instancetype)initWithContainerIdentifier:(NSString *)identifier {
    if (self = [self init]) {
        container = [CKContainer containerWithIdentifier:identifier];
        dispatch_group_enter(primaryInitializationGroup);
        [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
                dispatch_group_leave(primaryInitializationGroup);
            } else {
                if (accountStatus == CKAccountStatusAvailable) {
                    state |= ASCloudStateAccountStatusAvailable;
#ifdef DEBUG
                    db = container.publicCloudDatabase;
#else
                    db = container.privateCloudDatabase;
#endif
                    [self updateDevicesCompletion:^{
                        dispatch_group_leave(primaryInitializationGroup);
                    }];
                } else {
                    state ^= state & ASCloudStateAccountStatusAvailable;
                }
            }
        }];
    }
    return self;
}



#pragma mark - ASCloudManager

- (BOOL)ready {
    ASCloudState requiredState = ASCloudStateAccountStatusAvailable | ASCloudStateDeviceUpdated | ASCloudStateDevicesReloaded;
    return (state & requiredState) == requiredState;
}

- (void)setDataSyncContext:(id<ASDataSyncContextPrivate, ASCloudMappingProvider>)context {
    syncContext = context;
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(primaryInitializationGroup, DISPATCH_TIME_FOREVER);
        [self subscribeToRegisteredRecordTypes];
        [self smartReplication];
    });
}

- (ASCloudMapping *)mapping {
    return syncContext.cloudMapping;
}

- (id<ASDataSyncContextPrivate, ASCloudMappingProvider>)dataSyncContext {
    return syncContext;
}

- (void)willCommitTransaction:(id<ASRepresentableTransaction>)transaction {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    NSSet <NSObject<ASMappedObject> *> *updatedObjects = transaction.updatedObjects;
    NSSet <NSObject<ASDescription> *> *deletedObjects = transaction.deletedObjects;
    for (NSObject<ASMappedObject> *mappedObject in updatedObjects) {
        [self enqueueUpdateWithMappedObject:mappedObject];
    }
    [self reloadDevisesCompletion:^{
        for (NSObject<ASDescription> *description in deletedObjects) {
            [self enqueueDeletionWithDescription:description];
        }
        [self pushQueueWithSuccessBlock:nil];
    }];

}



#pragma mark - Devices Update

- (void)updateDevicesCompletion:(void (^)(void))completion {
    [self enqueueUpdateWithMappedObject:deviceList.thisDevice];
    [self pushQueueWithSuccessBlock:^(BOOL success) {
        if (success) {
            thisDevicePredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ == %%@", ASCloudDeletionInfoRecordProperty_deviceID], deviceList.thisDevice.UUIDString];
            state |= ASCloudStateDeviceUpdated;
            [self reloadDevisesCompletion:^{
                if (completion) completion();
            }];
        } else {
            state ^= state & ASCloudStateDeviceUpdated;
            if (completion) completion();
        }
    }];
}

- (void)reloadDevisesCompletion:(void (^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [self getAllRecordsOfEntityName:[ASDevice entityName] fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) {
            for (CKRecord<ASMappedObject> *record in records) {
                ASDevice *device = [ASDevice deviceWithMappedObject:record];
                [deviceList addDevice:device];
            }
            state |= ASCloudStateDevicesReloaded;
        } else {
            state ^= state & ASCloudStateDevicesReloaded;
        }
        if (completion) completion();
    }];
}



#pragma mark - Remote notifications

typedef void (^SaveSubscriptionCompletionHandler)(CKSubscription * _Nullable subscription, NSError * _Nullable error);

- (void)subscribeToRegisteredRecordTypes {
    SaveSubscriptionCompletionHandler completionHandler = ^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ERROR] SaveSubscription failed: %@", error.localizedDescription);
        }
    };
    
    for (NSString *recordType in self.mapping.allRecordTypes) {
        NSLog(@"[INFO] Try to subscribe to recordType <%@>", recordType);
        CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:recordType predicate:[NSPredicate predicateWithValue:YES] options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
        [db saveSubscription:subscription completionHandler:completionHandler];
    }

    CKQuerySubscription *subscription = [[CKQuerySubscription alloc] initWithRecordType:ASCloudDeletionInfoRecordType predicate:thisDevicePredicate options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    [db saveSubscription:subscription completionHandler:completionHandler];

}

- (void)acceptPushNotificationWithUserInfo:(NSDictionary *)userInfo {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    if (notification.notificationType == CKNotificationTypeQuery && notification.containerIdentifier == container.containerIdentifier) {
        CKQueryNotification *queryNotification = (CKQueryNotification *)notification;
        [self recordByRecordID:queryNotification.recordID fetch:^(CKRecord <ASMappedObject>*record, NSError * _Nullable error) {
            if (!self.ready) @throw [NSException exceptionWithName:@"acceptPushNotificationWithUserInfo error" reason:@"ASCloudManager not ready" userInfo:nil];
            if (record) {
                NSString *entityName = self.mapping[record.recordType];
                if ([record.recordType isEqualToString:[ASDevice entityName]]) {
                    ASDevice *device = [ASDevice deviceWithMappedObject:(CKRecord <ASMappedObject> *)record];
                    NSLog(@"[DEBUG] accept NEW Device %@", device.UUIDString);
                    [deviceList addDevice:device];
                } else if ([record.recordType isEqualToString:ASCloudDeletionInfoRecordType]) {
                    [_remoteUpdatedDeletionInfoRecords addObject:record];
                    [mutableRecordIDsToDelete addObject:record.recordID];
                    [self performMergeWithContextAndCleanup];
                } else if (entityName) {
                    [_remoteUpdatedRecords addObject:record];
                    [self performMergeWithContextAndCleanup];
                }
            } else {
                @throw [NSException exceptionWithName:@"CKFetchRecordsOperation failed"  reason:[NSString stringWithFormat:@"Object with recordID %@ not found.", queryNotification.recordID.recordName] userInfo:nil];
            }
        }];
    }
}



#pragma mark - Replication

- (void)smartReplication {
    [self reloadMappedRecordsTotal:NO completion:^{

    }];
}

- (void)reloadMappedRecordsTotal:(BOOL)total completion:(void(^)(void))completion {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    for (NSString *entityName in self.mapping.synchronizableEntities) {
        FetchRecordsArray fetchArrayBlock = ^(NSArray<__kindof CKRecord *> *records) {
            for (CKRecord *record in records) {
                [_remoteUpdatedRecords addObject:record];
            }
            dispatch_group_leave(reloadMappedRecordsGroup);
        };
        dispatch_group_enter(reloadMappedRecordsGroup);
        if (total) {
            [self getAllRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        } else {
            [self getNewRecordsOfEntityName:entityName fetch:fetchArrayBlock];
        }
    }
    
    dispatch_group_enter(reloadMappedRecordsGroup);
    [self getRecordsOfEntityName:ASCloudDeletionInfoRecordType withPredicate:thisDevicePredicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        for (CKRecord *record in records) {
            [_remoteUpdatedDeletionInfoRecords addObject:record];
            [mutableRecordIDsToDelete addObject:record.recordID];
        }
        dispatch_group_leave(reloadMappedRecordsGroup);
    }];
    
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(reloadMappedRecordsGroup, DISPATCH_TIME_FOREVER);
        [self performMergeWithContextAndCleanup];
        if (completion) completion();
    });

}

- (void)performMergeWithContextAndCleanup {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    [syncContext performMergeWithTransaction:[ASCloudTransaction transactionWithUpdatedRecords:self.remoteUpdatedRecords
                                                                           deletionInfoRecords:self.remoteUpdatedDeletionInfoRecords
                                                                                       mapping:self.mapping]];
    [_remoteUpdatedRecords removeAllObjects];
    [_remoteUpdatedDeletionInfoRecords removeAllObjects];
    [self pushQueueWithSuccessBlock:^(BOOL success) {
        NSLog(@"[DEBUG] Cleanup DeletionInfo %@", success ? @"success" : @"failed");
    }];
}

#pragma mark - Fetch Records

- (void)getAllRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    [self setLastSyncDate:nil forEntity:entityName];
    [self getNewRecordsOfEntityName:entityName fetch:fetch];
}

- (void)getNewRecordsOfEntityName:(NSString *)entityName fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif
    NSDate *lastSyncDate = self.lastSyncDateForEntity[entityName];
    NSDate *queryDate = [NSDate date];
    NSPredicate *predicate = lastSyncDate ? [NSPredicate predicateWithFormat:@"modificationDate > %@", lastSyncDate] : nil;
    [self getRecordsOfEntityName:entityName withPredicate:predicate fetch:^(NSArray<__kindof CKRecord *> *records) {
        if (records) [self setLastSyncDate:queryDate forEntity:entityName];
        fetch(records);
    }];    
}

- (void)getRecordsOfEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate fetch:(FetchRecordsArray)fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, entityName);
#endif

    NSMutableArray *foundRecords = [NSMutableArray new];
    void (^recordFetchedBlock)(CKRecord * _Nonnull record) = ^(CKRecord * _Nonnull record) {
        [foundRecords addObject:record];
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
                fetch(foundRecords.copy);
            }
        }
    };
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:self.mapping[entityName] predicate:predicate ?: [NSPredicate predicateWithValue:true]];
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    queryOperation.recordFetchedBlock = recordFetchedBlock;
    queryOperation.queryCompletionBlock = queryCompletionBlock;
    
    [db addOperation:queryOperation];
}


- (void)recordByRecordID:(CKRecordID *)recordID fetch:(void (^)(CKRecord<ASMappedObject> *record, NSError * _Nullable error))fetch {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    CKFetchRecordsOperation *fetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[recordID]];
    __block NSInteger count = 0;
    __block CKRecord<ASMappedObject> *foundRecord = nil;
    __block NSError *error = nil;
    
    [fetchOperation setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * _Nullable recordID, NSError * _Nullable operationError) {
        if (operationError) {
            error = operationError;
            NSLog(@"FetchRecordsOperation Error: %@", operationError);
        }
        if (record) {
            foundRecord = (CKRecord<ASMappedObject> *)record;
            count++;
        }
    }];
    
    [fetchOperation setCompletionBlock:^{
        fetch(foundRecord, error);
        if (count > 1) {
            @throw [NSException exceptionWithName:@"CKFetchRecordsOperation error" reason:[NSString stringWithFormat:@"Unique constraint violated: duplicated recordID %@", recordID.recordName] userInfo:nil];
        }
    }];
    
    fetchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    fetchOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    [db addOperation:fetchOperation];
}


#pragma mark - Cloud Update

- (void)enqueueUpdateWithMappedObject:(NSObject<ASMappedObject> *)syncObject {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (!syncObject.uniqueData) {
        NSLog(@"[ERROR] syncObject.uniqueData == nil");
        return;
    }
    dispatch_group_enter(enqueueUpdateWithMappedObjectGroup);
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:syncObject.uniqueData.UUIDString];
    [self recordByRecordID:recordID fetch:^(CKRecord<ASMappedObject> *record, NSError * _Nullable error) {
        if (record) {
            if ([record.modificationDate compare:syncObject.modificationDate] != NSOrderedAscending) {
                NSLog(@"[WARNING] Cloud record %@ up to date %@", record.UUIDString, record.modificationDate);
                dispatch_group_leave(enqueueUpdateWithMappedObjectGroup);
                return ; // record update no needed
            }
        } else {
            if (error.code == CKErrorUnknownItem) {
                NSLog(@"[INFO] Not found. Create new record with recordID %@", recordID);
                record = (CKRecord<ASMappedObject> *)[CKRecord recordWithRecordType:syncObject.entityName recordID:recordID];
            } else {
                NSLog(@"[ERROR] %@\n%@\n%@", error.localizedDescription, error.localizedFailureReason, error.localizedRecoverySuggestion);
#warning serialize syncObject and enqueue
                dispatch_group_leave(enqueueUpdateWithMappedObjectGroup);
                return ;
            }
        }
        record.keyedDataProperties = syncObject.keyedDataProperties;
        record.modificationDate = syncObject.modificationDate;
        [mutableRecordsToSave addObject:record];
        dispatch_group_leave(enqueueUpdateWithMappedObjectGroup);
    }];
}

- (void)enqueueDeletionWithDescription:(id <ASDescription>)description {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    if (!description.uniqueData) {
        NSLog(@"[ERROR] description.uniqueData == nil");
        return;
    }
    CKRecordID *recordID = [CKRecordID recordIDWithUUIDString:description.uniqueData.UUIDString];
    [mutableRecordIDsToDelete addObject:recordID];
    for (ASDevice *device in deviceList) {
        CKRecord *deletionInfo = [CKRecord recordWithRecordType:ASCloudDeletionInfoRecordType];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordType] = self.mapping[description.entityName];
        deletionInfo[ASCloudDeletionInfoRecordProperty_recordID] = description.uniqueData.UUIDString;
        deletionInfo[ASCloudDeletionInfoRecordProperty_deviceID] = device.UUIDString;
        [mutableRecordsToSave addObject:deletionInfo];
    }
}

- (void)pushQueueWithSuccessBlock:(void (^)(BOOL success))successBlock {
#ifdef DEBUG
    NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);
#endif
    dispatch_async(waitingQueue, ^{
        dispatch_group_wait(enqueueUpdateWithMappedObjectGroup, DISPATCH_TIME_FOREVER);
        CKModifyRecordsOperation *mop = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:mutableRecordsToSave.copy recordIDsToDelete:mutableRecordIDsToDelete.copy];
        NSUInteger mutableRecordsToSaveCount = mutableRecordsToSave.count;
        NSUInteger mutableRecordIDsToDeleteCount = mutableRecordIDsToDelete.count;
        [mop setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (operationError) {
                NSLog(@"[ERROR] CKModifyRecordsOperation Error: %@", operationError);
            }
            if (savedRecords.count == mutableRecordsToSaveCount && deletedRecordIDs.count == mutableRecordIDsToDeleteCount) {
                [mutableRecordsToSave removeAllObjects];
                [mutableRecordIDsToDelete removeAllObjects];
                if (successBlock) successBlock(true);
            } else {
                for (CKRecord *record in savedRecords) {
                    [mutableRecordsToSave removeObject:record];
                }
                for (CKRecordID *recordID in deletedRecordIDs) {
                    [mutableRecordIDsToDelete removeObject:recordID];
                }
                if (successBlock) successBlock(false);
            }
        }];
        mop.queuePriority = NSOperationQueuePriorityVeryHigh;
        mop.qualityOfService = NSQualityOfServiceUserInteractive;
        [db addOperation:mop];
    });
    
}



@end
