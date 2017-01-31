//
//  ASManagedObjectContext.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASManagedObjectContext.h"
#import "ASTransactionRepresentation.h"
#import "NSManagedObjectContext+SQLike.h"
#import "ASPrivateProtocol.h"
#import "NSUUID+NSData.h"
#import "ASDataAgregator.h"

//#import <UIKit/UIKit.h>

@interface ASManagedObjectContext() <ASDataSyncContextPrivate>
@property (nonatomic, weak) id<ASTransactionsAgregator> agregator;

@end

@implementation ASManagedObjectContext {
    NSManagedObjectContext *mainContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSMutableArray <id <ASRepresentableTransaction>> *recievedTransactionsQueue;
    NSString *name;
    ASCloudMapping *selfAutoMapping;
}

@synthesize delegate = _delegate;

- (NSString *)identifier {
    return name;
}

- (void)setIdentifier:(NSString *)identifier {
    name = [NSString stringWithFormat:@"%@ %@", NSStringFromClass(self.class), identifier];
}

- (NSSet <NSManagedObject<ASMappedObject> *> *)updatedObjects {
    __block NSMutableSet <NSManagedObject<ASMappedObject> *> *result = [NSMutableSet new];;
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.insertedObjects) {
            if ([obj conformsToProtocol:@protocol(ASMappedObject)]) {
                [result addObject:(NSManagedObject<ASMappedObject> *)obj];
            }
        }
        for (NSManagedObject *obj in super.updatedObjects) {
            if ([obj conformsToProtocol:@protocol(ASMappedObject)]) {
                [result addObject:(NSManagedObject<ASMappedObject> *)obj];
            }
        }
    }];
    return result.copy;
}

- (NSSet <NSManagedObject<ASDescription> *> *)deletedObjects {
    __block NSMutableSet <NSManagedObject<ASDescription> *> *result = [NSMutableSet new];
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.deletedObjects) {
            if ([obj conformsToProtocol:@protocol(ASDescription)]) {
                [result addObject:(NSManagedObject<ASDescription> *)obj];
            }
        }
    }];
    return result.copy;
}

- (void)setAgregator:(id<ASTransactionsAgregator>)agregator {
    self.agregator = agregator;
}

- (NSManagedObjectModel *)model {
    return self.persistentStoreCoordinator.managedObjectModel;
}

#pragma mark - cloud support

- (void)enableCloudSynchronization {
    [[ASDataAgregator defaultAgregator] setPrivateCloudContext:self];
}

- (ASCloudMapping *)autoMapping {
    if (!selfAutoMapping) {
        selfAutoMapping = [ASCloudMapping new];
        for (NSEntityDescription *entity in self.model.entities) {
            Class class = NSClassFromString([entity managedObjectClassName]);
            if ([class conformsToProtocol:@protocol(ASMappedObject)]) {
                if ([class respondsToSelector:@selector(recordType)]) {
                    Class <ASMappedObject> mappedObjectClass = class;
                    NSString *recordType = [mappedObjectClass recordType];
                    if (![recordType isEqualToString:entity.name]) {
                        [selfAutoMapping mapRecordType:recordType withEntityName:entity.name];
                        continue;
                    }
                }
                [selfAutoMapping registerSynchronizableEntity:entity.name];
            }
        }
    }
    return selfAutoMapping.copy;
}

#pragma mark - Synchronization

- (void)enableWatchSynchronization {
    recievedTransactionsQueue = [NSMutableArray new];
    [[ASDataAgregator defaultAgregator] addWatchSynchronizableContext:self];
}

+ (NSException *)incompatibleEntityExceptionWithEntityName:(NSString *)entityName entityClassName:(NSString *)entityClassName protocol:(Protocol *)protocol {
    return [NSException exceptionWithName:@"Incompatible entity class implementation"
                                   reason:[NSString stringWithFormat:@"Entity <%@> class <%@> not conformsToProtocol <%@>",
                                           entityName, entityClassName, NSStringFromProtocol(protocol)]
                                 userInfo:nil];
}

- (NSManagedObject *)insertSynchronizableObject:(id <ASMappedObject>)recievedObject {
    NSManagedObject *object = [self insertTo:recievedObject.entityName];
    NSString *entityClassName = [[NSEntityDescription entityForName:recievedObject.entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASManagedObject)]) {
        NSManagedObject <ASManagedObject> *synchronizableObject = (NSManagedObject <ASManagedObject> *)object;
        synchronizableObject.uniqueData = recievedObject.uniqueData;
        synchronizableObject.modificationDate = recievedObject.modificationDate;
        synchronizableObject.keyedDataProperties = recievedObject.keyedDataProperties;
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:recievedObject.entityName entityClassName:entityClassName protocol:@protocol(ASManagedObject)];
    }
    return object;
}

- (NSManagedObject <ASFindableReference> *)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName {
    NSManagedObject <ASFindableReference> *resultObject = nil;
    NSString *entityClassName = [[NSEntityDescription entityForName:entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASFindableReference)]) {
        Class <ASFindableReference> entityClass = NSClassFromString(entityClassName);
        NSArray <NSManagedObject <ASFindableReference> *> *objects = [self selectFrom:entityName
                                                                                where:[entityClass predicateWithUniqueData:uniqueData]];
        if (objects.count == 1) {
            resultObject = (NSManagedObject <ASFindableReference> *)objects.firstObject;
        } else if (objects.count) {
            resultObject = (NSManagedObject <ASFindableReference> *)objects.firstObject;
            @throw [NSException exceptionWithName:@"DataBase UNIQUE constraint violated"
                                           reason:[NSString stringWithFormat:@"Object count with UUID <%@>: %ld\n"
                                                   "Check your ASFindableReference protocol implementation for Entity <%@>",
                                                   resultObject.UUIDString, (unsigned long)objects.count,
                                                   entityName]
                                         userInfo:nil];
        }
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:entityName entityClassName:entityClassName protocol:@protocol(ASFindableReference)];
    }
    return resultObject;
}

- (void)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName fetch:(void (^)(NSManagedObject <ASFindableReference> *object))fetch {
    [self performBlock:^{
        NSManagedObject <ASFindableReference> *object;
        @try {
            object = [self objectByUniqueData:uniqueData entityName:entityName];
        } @catch (NSException *exception) {
            NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
        } @finally {
            fetch(object);
        }
    }];
}

- (NSManagedObject <ASFindableReference> *)objectByDescription:(id <ASDescription>)description {
    return [self objectByUniqueData:description.uniqueData entityName:description.entityName];
}

- (void)performMergeWithTransaction:(id<ASRepresentableTransaction>)transaction {
    if ([self hasChanges]) {
        [recievedTransactionsQueue addObject:transaction];
    } else {
        [self performMergeBlockWithTransaction:transaction];
        [self performSaveContextAndReloadData];
    }
}

- (void)performMergeBlockWithTransaction:(id<ASRepresentableTransaction>)transaction {
    [self performBlock:^{
//        NSMutableArray <NSManagedObject <ASynchronizableRelatableObject> *> *recievedRelatableObjectArray = [NSMutableArray new];
//        NSMutableArray <NSDictionary <NSString *, ASerializableDescription *> *> *arrayOfDescriptionByRelationKey = [NSMutableArray new];
//        NSMutableArray <NSManagedObject <ASynchronizableMultiRelatableObject> *> *recievedMultiRelatableObjectArray = [NSMutableArray new];
//        NSMutableArray <NSDictionary <NSString *, NSSet <id <ASDescription> *> *> *arrayOfSetOfDescriptionsByRelationKey = [NSMutableArray new];
        
        for (id <ASMappedObject>recievedObject in transaction.updatedObjects) {
            @try {
                NSManagedObject <ASFindableReference> *foundObject = [self objectByDescription:recievedObject];
                NSManagedObject <ASManagedObject> *namagedObject;
                if (foundObject) {
                    if ([foundObject.class conformsToProtocol:@protocol(ASMutableMappedObject)]) {
                        NSManagedObject <ASMutableMappedObject> *mutableObject = (NSManagedObject <ASMutableMappedObject> *)foundObject;
                        if ([mutableObject.modificationDate compare:recievedObject.modificationDate] == NSOrderedAscending) {
                            mutableObject.modificationDate = recievedObject.modificationDate;
                            mutableObject.keyedDataProperties = recievedObject.keyedDataProperties;
                        } else {
                            NSLog(@"[WARNING] %s dequeue UPDATE: recieved object with UUID <%@> out of date", __PRETTY_FUNCTION__, recievedObject.UUIDString);
                        }
                    }
                } else {
                    foundObject = [self insertSynchronizableObject:recievedObject];
                }

                //relations to buffer
                if ([recievedObject isKindOfClass:[ASRelatableObjectRepresentation class]]) {
                    ASerializableRelatableObject *relatableObject = (ASerializableRelatableObject *)recievedObject;
                    if (relatableObject.descriptionByRelationKey.count) {
                        if ([synchronizableObject conformsToProtocol:@protocol(ASynchronizableRelatableObject)]) {
                            [recievedRelatableObjectArray addObject:(NSManagedObject <ASynchronizableRelatableObject> *)synchronizableObject];
                            [arrayOfDescriptionByRelationKey addObject:relatableObject.descriptionByRelationKey];
                        } else {
                            @throw [NSException exceptionWithName:@"Object does not conformsToProtocol ASynchronizableRelatableObject while descriptionByRelationKey is not empty"
                                                           reason:[NSString stringWithFormat:@"Object UUID <%@> class <%@> ", recievedObject.UUIDString, NSStringFromClass(recievedObject.class)]
                                                         userInfo:nil];
                        }
                    }
                    if (relatableObject.setOfDescriptionsByRelationKey.count) {
                        if ([synchronizableObject conformsToProtocol:@protocol(ASynchronizableMultiRelatableObject)]) {
                            [recievedMultiRelatableObjectArray addObject:(NSManagedObject <ASynchronizableMultiRelatableObject> *)synchronizableObject];
                            [arrayOfSetOfDescriptionsByRelationKey addObject:relatableObject.setOfDescriptionsByRelationKey];
                        } else {
                            @throw [NSException exceptionWithName:@"Object does not conformsToProtocol ASynchronizableMultiRelatableObject while setOfDescriptionsByRelationKey is not empty"
                                                           reason:[NSString stringWithFormat:@"Object UUID <%@> class <%@> ", recievedObject.UUIDString, NSStringFromClass(recievedObject.class)]
                                                         userInfo:nil];
                        }
                    }
                }

            } @catch (NSException *exception) {
                NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
            }
        }
        
        //set relations after insert all objects
        
        for (NSUInteger index = 0; index < recievedRelatableObjectArray.count; index++) {
            NSManagedObject <ASynchronizableRelatableObject> *synchronizableRelatableObject = recievedRelatableObjectArray[index];
            NSDictionary <NSString *, ASerializableDescription *> *descriptionByRelationKey = arrayOfDescriptionByRelationKey[index];
            for (NSString *relationKey in descriptionByRelationKey.allKeys) {
                if ([descriptionByRelationKey[relationKey] isKindOfClass:[NSNull class]]) {
                    [synchronizableRelatableObject replaceRelation:relationKey toObject:nil];
                } else {
                    @try {
                        NSManagedObject <ASMappedObject> *synchronizableObject = [self objectByDescription:descriptionByRelationKey[relationKey]];
                        [synchronizableRelatableObject replaceRelation:relationKey toObject:synchronizableObject];
                    } @catch (NSException *exception) {
                        NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                    }
                }
            }
        }
        
        for (NSUInteger index = 0; index < recievedRelatableObjectArray.count; index++) {
            NSManagedObject <ASynchronizableMultiRelatableObject> *synchronizableMultiRelatableObject = recievedMultiRelatableObjectArray[index];
            NSDictionary <NSString *, NSSet <ASerializableDescription *> *> *setOfDescriptionsByRelationKey = arrayOfSetOfDescriptionsByRelationKey[index];
            for (NSString *relationKey in setOfDescriptionsByRelationKey.allKeys) {
                NSSet <ASerializableDescription *> *setOfDescriptions = setOfDescriptionsByRelationKey[relationKey];
                NSMutableSet *tmpSet = [NSMutableSet new];
                for (ASerializableDescription *description in setOfDescriptions) {
                    @try {
                        NSManagedObject <ASMappedObject> *synchronizableObject = [self objectByDescription:description];
                        if (synchronizableObject) {
                            [tmpSet addObject:synchronizableObject];
                        } else {
                            @throw [NSException exceptionWithName:[NSString stringWithFormat:@"objectByDescription %@ not found", description] reason:@"WTF?!" userInfo:nil];
                        }
                    } @catch (NSException *exception) {
                        NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                    }
                }
                [synchronizableMultiRelatableObject replaceRelation:relationKey toObjectSet:tmpSet.copy];
            }
        }
        
        for (ASerializableDescription *recievedDescription in recievedContext.deletedObjects) {
            @try {
                NSManagedObject <ASMappedObject> *synchronizableObject = [self objectByDescription:recievedDescription];
                if (synchronizableObject) {
                    [self deleteObject:synchronizableObject];
                } else {
                    NSLog(@"[WARNING] %s dequeue DELETE: object with UUID <%@> not found", __PRETTY_FUNCTION__, recievedDescription.UUIDString);
                }
            } @catch (NSException *exception) {
                NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
            }
        }
    }];
}

- (void)saveMainContext {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
        NSLog(@"[ERROR] %s", __PRETTY_FUNCTION__);
#endif
        NSError *error;
        if (![mainContext save:&error]) {
            if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        }
        
    });
}

- (void)performSaveContextAndReloadData {
    [self performBlock:^{
        [self saveAndReloadData];
    }];
}

- (void)saveAndReloadData {
    NSError *error;
    if ([self save:&error]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(reloadData)]) {
            [self.delegate reloadData];
        }
        [self saveMainContext];
    } else {
        if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
    }
}

- (void)performBlockWithSaveAndReloadData:(void (^)(void))block {
    [self performBlock:^{
        block();
        [self saveAndReloadData];
    }];
}

- (void)commit {
    if ([self hasChanges]) {        
        [self performBlock:^{
            if (self.agregator) [self.agregator willCommitContext:self];
            NSError *error;
            if ([self save:&error]) {
                [self saveMainContext];
            } else {
                if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
            }
            [self mergeQueue];
        }];
    } else {
        [self mergeQueue];
    }
}

- (void)mergeQueue {
    [self mergeQueueCompletion:nil];
}

- (void)mergeQueueCompletion:(void (^)(void))completion {
    dispatch_group_t waitGroup;
    if (completion) waitGroup = dispatch_group_create();
    
    if (recievedTransactionsQueue.count) {
        if (completion) dispatch_group_enter(waitGroup);
        for (int i = 0; i < recievedTransactionsQueue.count; i++) {
            [self performMergeBlockWithRecievedContext:recievedTransactionsQueue[i]];
        }
        [self performSaveContextAndReloadData];
        [recievedTransactionsQueue removeAllObjects];
        if (completion) [self performBlock:^{
            dispatch_group_leave(waitGroup);
        }];
    }
    if (cloudContextQueue.count) {
        if (completion) dispatch_group_enter(waitGroup);
        for (int i = 0; i < cloudContextQueue.count; i++) {
            [self performMergeBlockWithCloudContext:cloudContextQueue[i]];
        }
        [self performSaveContextAndReloadData];
        [cloudContextQueue removeAllObjects];
        if (completion) [self performBlock:^{
            dispatch_group_leave(waitGroup);
        }];
    }
    if (completion) dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_wait(waitGroup, DISPATCH_TIME_FOREVER);
        completion();
    });
}

- (void)rollback {
    [self performBlock:^{
        [super rollback];        
    }];
    [self mergeQueue];
}


#pragma mark - initialization

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

+ (instancetype)new {
    return [self defaultContext];
}

+ (instancetype)defaultContext {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initDefaultContext];
    });
    return shared;
}

- (instancetype)initDefaultContext {
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"ASDefaultDataStore.sqlite"];
    if (self = [self initWithStoreURL:storeURL]) {
        self.identifier = @"Default";
    }
    return self;
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL {
    return [self initWithStoreURL:storeURL modelURL:nil];
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL {
    if (self = [super initWithConcurrencyType:NSPrivateQueueConcurrencyType]) {
        mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        NSString *idModelPart = @"DefaultModel ";
        if (modelURL) {
            idModelPart = [NSString stringWithFormat:@"Model %@ ", [modelURL.absoluteString componentsSeparatedByString:@"/"].lastObject];
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        } else {
            managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
        self.identifier = [NSString stringWithFormat:@"%@store %@", idModelPart, [storeURL.absoluteString componentsSeparatedByString:@"/"].lastObject];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        NSError *error = nil;
        NSDictionary *autoMigration = @{ NSMigratePersistentStoresAutomaticallyOption : @(YES),
                                         NSInferMappingModelAutomaticallyOption : @(YES) };
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:autoMigration error:&error]) {
            if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        }
        [mainContext setPersistentStoreCoordinator:persistentStoreCoordinator];
        self.parentContext = mainContext;
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(appWillTerminate:)
//                                                     name:UIApplicationWillResignActiveNotification
//                                                   object:nil];
    }
    return self;
}

//- (void)appWillTerminate:(NSNotification *)note {
//    [self rollbackAndWait];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

#pragma mark - thread safe queries

- (void)deleteObject:(NSManagedObject *)object completion:(void (^)(void))completion {
    [self performBlock:^{
        [super deleteObject:object];
        completion();
    }];
}

- (void)insertTo:(NSString *)entityName fetch:(FetchObject)fetch {
    [self performBlock:^{
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self];
        NSString *entityClassName = [[NSEntityDescription entityForName:entityName inManagedObjectContext:self] managedObjectClassName];
        if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASDescription)]) {
            NSManagedObject <ASDescription> *synchronizableObject = (NSManagedObject <ASDescription> *)object;
            synchronizableObject.uniqueData = [[NSUUID UUID] data];
            synchronizableObject.modificationDate = [NSDate date];
        }
        fetch(object);
    }];
}

- (void)selectFrom:(NSString *)entity fetch:(FetchArray)fetch {
    [self selectFrom:entity limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity orderBy:nil limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectFrom:entity orderBy:sortDescriptors limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity where:nil orderBy:sortDescriptors limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause orderBy:nil limit:limit fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectFrom:entity where:clause orderBy:sortDescriptors limit:0 fetch:fetch];
}

- (void)selectFrom:(NSString *)entity where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self performBlock:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
        request.predicate = clause;
        [request setSortDescriptors:sortDescriptors];
        [request setFetchLimit:limit];
        NSError *error = nil;
        NSArray *entities = [self executeFetchRequest:request error:&error];
        if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        fetch(entities);
    }];
}

- (void)rollbackCompletion:(void (^)(void))completion {
    [self performBlock:^{
        [super rollback];
        completion();
    }];
    [self mergeQueue];
}

- (void)rollbackAndWait {
    __block BOOL waiting = YES;
    NSCondition *waitingCondition = [NSCondition new];
    [self performBlock:^{
        [super rollback];
    }];
    [self mergeQueueCompletion:^{
        waiting = NO;
        [waitingCondition signal];
    }];
    [waitingCondition lock];
    while (waiting) {
        [waitingCondition wait];
    }
}





@end
