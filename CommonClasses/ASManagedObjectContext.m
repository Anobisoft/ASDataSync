//
//  ASManagedObjectContext.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASManagedObjectContext.h"
#import "ASRepresentableTransaction.h"
#import "ASDescriptionRepresentation.h"
#import "NSManagedObjectContext+SQLike.h"
#import "ASPrivateProtocol.h"
#import "NSUUID+NSData.h"
#import "ASDataAgregator.h"

//#import <UIKit/UIKit.h>

@interface FoundObjectWithRelationRepresentation : NSObject

@property (nonatomic, strong) NSObject <ASRelatableToOne> *recievedRelationsToOne;
@property (nonatomic, strong) NSObject <ASRelatableToMany> *recievedRelationsToMany;
@property (nonatomic, strong) NSManagedObject <ASManagedObject> *managedObject;

@end

@implementation FoundObjectWithRelationRepresentation

@end

@interface ASManagedObjectContext() <ASDataSyncContextPrivate, ASCloudMappingProvider>

@end

@implementation ASManagedObjectContext {
    NSManagedObjectContext *mainContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSMutableArray <id <ASRepresentableTransaction>> *recievedTransactionsQueue;
    NSString *name;
    ASCloudMapping *cloudMapping;
    id<ASTransactionsAgregator> transactionsAgregator;
    id<ASCloudManager> ownedCloudManager;
}

@synthesize delegate = _delegate;

- (NSString *)contextIdentifier {
    return name;
}

- (void)setContextIdentifier:(NSString *)contextIdentifier {
    name = [NSString stringWithFormat:@"%@ %@", NSStringFromClass(self.class), contextIdentifier];
}

- (NSSet <NSManagedObject<ASMappedObject> *> *)updatedObjects {
    __block NSMutableSet <NSManagedObject<ASMappedObject> *> *result = [NSMutableSet new];;
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.insertedObjects) {
            if ([obj conformsToProtocol:@protocol(ASMutableMappedObject)]) {
                NSManagedObject<ASMutableMappedObject> *mappedObject = (NSManagedObject<ASMutableMappedObject> *)obj;
                mappedObject.modificationDate = [NSDate date];
                [result addObject:mappedObject];
            }
        }
        for (NSManagedObject *obj in super.updatedObjects) {
            if ([obj conformsToProtocol:@protocol(ASMutableMappedObject)]) {
                NSManagedObject<ASMutableMappedObject> *mappedObject = (NSManagedObject<ASMutableMappedObject> *)obj;
                mappedObject.modificationDate = [NSDate date];
                [result addObject:mappedObject];
            }
        }
    }];
    return result.copy;
}

- (NSSet <NSObject<ASDescription> *> *)deletedObjects {
    __block NSMutableSet <NSObject<ASDescription> *> *result = [NSMutableSet new];
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.deletedObjects) {
            if ([obj conformsToProtocol:@protocol(ASDescription)]) {
                [result addObject:[ASDescriptionRepresentation instantiateWithDescription:(NSManagedObject <ASDescription> *)obj]];
            }
        }
    }];
    return result.copy;
}

- (void)setAgregator:(id<ASTransactionsAgregator>)agregator {
    transactionsAgregator = agregator;
}

#pragma mark - cloud support

- (void)setCloudManager:(id<ASCloudManager>)cloudManager {
    ownedCloudManager = cloudManager;
}

- (void)initCloudWithContainerIdentifier:(NSString *)containerIdentifier {
    [[ASDataAgregator defaultAgregator] setPrivateCloudContext:self forCloudContainerIdentifier:containerIdentifier];
}

- (void)acceptPushNotificationUserInfo:(NSDictionary *)userInfo {
    if (ownedCloudManager) [ownedCloudManager acceptPushNotificationUserInfo:userInfo];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)cloudReplication {
    if (ownedCloudManager) [ownedCloudManager smartReplication];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)cloudTotalReplication {
    if (ownedCloudManager) [ownedCloudManager totalReplication];
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)setCloudEnabled:(BOOL)cloudEnabled {
    if (ownedCloudManager) {
        ownedCloudManager.enabled = cloudEnabled;
        [self totalReplication];
    }
    else NSLog(@"[ERROR] owned cloud manager unordered");
}

- (void)totalReplication {
    if (transactionsAgregator) [self performBlock:^{
        ASRepresentableTransaction *transaction = [ASRepresentableTransaction instantiateWithContext:self];
        for (NSString *entityName in self.cloudMapping.synchronizableEntities) {
            [transaction addObjects:[NSSet setWithArray:[self selectFrom:entityName]]];
        }
        [transactionsAgregator willCommitTransaction:transaction];
    }];
}

- (BOOL)cloudEnabled {
    return ownedCloudManager ? ownedCloudManager.enabled : false;
}

- (ASCloudMapping *)cloudMapping {
    if (!cloudMapping) {
        cloudMapping = [ASCloudMapping new];
        for (NSEntityDescription *entity in managedObjectModel.entities) {
            Class class = NSClassFromString([entity managedObjectClassName]);
            if ([class conformsToProtocol:@protocol(ASMappedObject)]) {
                if ([class respondsToSelector:@selector(recordType)]) {
                    Class <ASMappedObject> mappedObjectClass = class;
                    NSString *recordType = [mappedObjectClass recordType];
                    if (![recordType isEqualToString:entity.name]) {
                        [cloudMapping mapRecordType:recordType withEntityName:entity.name];
                        continue;
                    }
                }
                [cloudMapping addEntity:entity.name];
            }
        }
    }
    return cloudMapping;
}

#pragma mark - Synchronization

- (void)enableWatchSynchronization {    
    [[ASDataAgregator defaultAgregator] addWatchSynchronizableContext:self];
}

+ (NSException *)incompatibleEntityExceptionWithEntityName:(NSString *)entityName entityClassName:(NSString *)entityClassName protocol:(Protocol *)protocol {
    return [NSException exceptionWithName:@"Incompatible entity class implementation"
                                   reason:[NSString stringWithFormat:@"Entity <%@> class <%@> not conformsToProtocol <%@>",
                                           entityName, entityClassName, NSStringFromProtocol(protocol)]
                                 userInfo:nil];
}

- (NSManagedObject *)insertMappedObject:(id <ASMappedObject>)recievedObject {
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

- (void)objectByUniqueData:(NSData *)uniqueData entityName:(NSString *)entityName fetch:(void (^)(__kindof NSManagedObject *object))fetch {
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
        NSMutableArray <FoundObjectWithRelationRepresentation *> *foundObjectsWithRelationRepresentations = [NSMutableArray new];
        for (NSObject <ASMappedObject> *recievedMappedObject in transaction.updatedObjects) {
            @try {
                NSManagedObject <ASFindableReference> *foundObject = [self objectByDescription:recievedMappedObject];
                NSManagedObject <ASManagedObject> *managedObject;
                if (foundObject) {
                    if ([foundObject.class conformsToProtocol:@protocol(ASManagedObject)]) {
                        managedObject = (NSManagedObject <ASManagedObject> *)foundObject;
                        if ([managedObject.modificationDate compare:recievedMappedObject.modificationDate] == NSOrderedAscending) {
                            managedObject.modificationDate = recievedMappedObject.modificationDate;
                            managedObject.keyedDataProperties = recievedMappedObject.keyedDataProperties;
                        } else {
                            NSLog(@"[WARNING] %s dequeue UPDATE: recieved object with UUID <%@> out of date", __PRETTY_FUNCTION__, recievedMappedObject.UUIDString);
                        }
                    }
                } else {
                    managedObject = (NSManagedObject <ASManagedObject> *)[self insertMappedObject:recievedMappedObject];
                }
                
                BOOL relatableToOne = [recievedMappedObject conformsToProtocol:@protocol(ASRelatableToOne)];
                BOOL relatableToMany = [recievedMappedObject conformsToProtocol:@protocol(ASRelatableToMany)];
                
                if (relatableToOne || relatableToMany) {
//                    NSLog(@"[DEBUG] recievedMappedObject %@ %@", relatableToOne ? @"relatableToOne" : @"", relatableToMany ? @"relatableToMany" : @"");
                    FoundObjectWithRelationRepresentation *theFoundObjectWithRelationRepresentation = [FoundObjectWithRelationRepresentation new];
                    if (relatableToOne) {
                        theFoundObjectWithRelationRepresentation.recievedRelationsToOne = (NSObject <ASRelatableToOne> *)recievedMappedObject;
                    }
                    if (relatableToMany) {
                        theFoundObjectWithRelationRepresentation.recievedRelationsToMany = (NSObject <ASRelatableToMany> *)recievedMappedObject;
                    }
                    theFoundObjectWithRelationRepresentation.managedObject = managedObject;
                    [foundObjectsWithRelationRepresentations addObject:theFoundObjectWithRelationRepresentation];
                }
                

            } @catch (NSException *exception) {
                NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
            }
        }
        
//        NSLog(@"[DEBUG] foundObjectsWithRelationRepresentations %@ count %ld", foundObjectsWithRelationRepresentations, (long)foundObjectsWithRelationRepresentations.count);
        
        for (FoundObjectWithRelationRepresentation *theFoundObjectWithRelationRepresentation in foundObjectsWithRelationRepresentations) {
//            NSLog(@"[DEBUG] theFoundObjectWithRelationRepresentation.managedObject %@", theFoundObjectWithRelationRepresentation.managedObject);
            if (theFoundObjectWithRelationRepresentation.recievedRelationsToOne && [theFoundObjectWithRelationRepresentation.managedObject conformsToProtocol:@protocol(ASMutableRelatableToOne)]) {
//                NSLog(@"[DEBUG] theFoundObjectWithRelationRepresentation.recievedRelationsToOne %@", theFoundObjectWithRelationRepresentation.recievedRelationsToOne);
                NSManagedObject <ASManagedObject, ASMutableRelatableToOne> *managedObjectRelatableToOne = (NSManagedObject <ASManagedObject, ASMutableRelatableToOne> *)theFoundObjectWithRelationRepresentation.managedObject;
//                NSLog(@"[DEBUG] theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences %@", theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences);
                for (NSString *relationKey in theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences.allKeys) {
//                    NSLog(@"[DEBUG] recievedRelationsToOne relationKey %@", relationKey);
                    NSObject <ASReference> *reference = theFoundObjectWithRelationRepresentation.recievedRelationsToOne.keyedReferences[relationKey];
                    NSString *relatedEntityName = [managedObjectRelatableToOne.class entityNameByRelationKey][relationKey];
                    NSManagedObject <ASFindableReference> *relatedObject;
                    @try {
                        relatedObject = [self objectByUniqueData:reference.uniqueData entityName:relatedEntityName];
                    } @catch (NSException *exception) {
                        NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                    }
                    [managedObjectRelatableToOne replaceRelation:relationKey toReference:relatedObject];
                    
                }
            }
            if (theFoundObjectWithRelationRepresentation.recievedRelationsToMany && [theFoundObjectWithRelationRepresentation.managedObject conformsToProtocol:@protocol(ASMutableRelatableToMany)]) {
//                NSLog(@"[DEBUG] theFoundObjectWithRelationRepresentation.recievedRelationsToMany %@", theFoundObjectWithRelationRepresentation.recievedRelationsToMany);
                NSManagedObject <ASManagedObject, ASMutableRelatableToMany> *managedObjectRelatableToMany = (NSManagedObject <ASManagedObject, ASMutableRelatableToMany> *)theFoundObjectWithRelationRepresentation.managedObject;
//                NSLog(@"[DEBUG] theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences %@", theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences);
                for (NSString *relationKey in theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences.allKeys) {
//                    NSLog(@"[DEBUG] recievedRelationsToMany relationKey %@", relationKey);
                    NSSet <NSObject <ASReference> *> *setOfReferences = theFoundObjectWithRelationRepresentation.recievedRelationsToMany.keyedSetsOfReferences[relationKey];
                    NSString *relatedEntityName = [managedObjectRelatableToMany.class entityNameByRelationKey][relationKey];
                    NSMutableSet *newSet = [NSMutableSet new];
                    for (NSObject <ASReference> *reference in setOfReferences) {
                        NSManagedObject <ASFindableReference> *relatedObject;
                        @try {
                            relatedObject = [self objectByUniqueData:reference.uniqueData entityName:relatedEntityName];
                        } @catch (NSException *exception) {
                            NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
                        }
                        if (relatedObject) [newSet addObject:relatedObject];
                    }
                    [managedObjectRelatableToMany replaceRelation:relationKey toSetsOfReferences:newSet.copy];
                }
            }
        }
        
        for (NSObject <ASDescription> *recievedDescription in transaction.deletedObjects) {
            @try {
                NSManagedObject <ASFindableReference> *foundObject = [self objectByDescription:recievedDescription];
                if (foundObject) {
                    [self deleteObject:foundObject];
                } else {
                    NSLog(@"[WARNING] %s dequeue DELETE: object of Entity <%@> with UUID <%@> not found", __PRETTY_FUNCTION__, recievedDescription.entityName, recievedDescription.UUIDString);
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
            if (transactionsAgregator) [transactionsAgregator willCommitTransaction:[ASRepresentableTransaction instantiateWithContext:self]];
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
            [self performMergeBlockWithTransaction:recievedTransactionsQueue[i]];
        }
        [self performSaveContextAndReloadData];
        [recievedTransactionsQueue removeAllObjects];
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
        shared = [[self alloc] initDefaultContext];
    });
    return shared;
}

- (instancetype)initDefaultContext {
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"ASDefaultDataStore.sqlite"];
    if (self = [self initWithStoreURL:storeURL]) {
        self.contextIdentifier = @"Default";
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
        self.contextIdentifier = [NSString stringWithFormat:@"%@store %@", idModelPart, [storeURL.absoluteString componentsSeparatedByString:@"/"].lastObject];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        NSError *error = nil;
        NSDictionary *autoMigration = @{ NSMigratePersistentStoresAutomaticallyOption : @(true),
                                         NSInferMappingModelAutomaticallyOption : @(true) };
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:autoMigration error:&error]) {
            if (error) NSLog(@"[ERROR] %s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo);
        }
        [mainContext setPersistentStoreCoordinator:persistentStoreCoordinator];
        self.parentContext = mainContext;
        
        recievedTransactionsQueue = [NSMutableArray new];
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
        if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASMutableReference)]) {
            NSManagedObject <ASMutableReference> *mutableReference = (NSManagedObject <ASMutableReference> *)object;
            mutableReference.uniqueData = [[NSUUID UUID] data];
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
    __block BOOL waiting = true;
    NSCondition *waitingCondition = [NSCondition new];
    [self performBlock:^{
        [super rollback];
    }];
    [self mergeQueueCompletion:^{
        waiting = false;
        [waitingCondition signal];
    }];
    [waitingCondition lock];
    while (waiting) {
        [waitingCondition wait];
    }
    NSLog(@"rollbackAndWait didFinishWaiting");
}





@end
