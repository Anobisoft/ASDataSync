//
//  ASManagedObjectContext.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASManagedObjectContext.h"
#import "ASerializableContext.h"
#import "NSManagedObjectContext+SQLike.h"
#import "ASynchronizablePrivate.h"
#import "NSUUID+NSData.h"

@interface ASManagedObjectContext()<ASynchronizableContextPrivate>
@property (nonatomic, weak) id<ASDataSyncAgregator> agregator;

@end

@implementation ASManagedObjectContext {
    NSManagedObjectContext *mainContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSMutableArray <ASerializableContext *> *recievedContextQueue;
    NSString *name;
}

#pragma mark ASynchronizableContext

@synthesize delegate = _delegate;

- (NSString *)identifier {
    return name;
}

- (void)setIdentifier:(NSString *)identifier {
    name = [NSString stringWithFormat:@"%@ %@", NSStringFromClass(self.class), identifier];
}

- (NSSet <NSManagedObject<ASynchronizableObject> *> *)updatedObjects {
    __block NSMutableSet <NSManagedObject<ASynchronizableObject> *> *result = [NSMutableSet new];;
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.insertedObjects) {
            if ([obj conformsToProtocol:@protocol(ASynchronizableObject)]) {
                [result addObject:(NSManagedObject<ASynchronizableObject> *)obj];
            }
        }
        for (NSManagedObject *obj in super.updatedObjects) {
            if ([obj conformsToProtocol:@protocol(ASynchronizableObject)]) {
                [result addObject:(NSManagedObject<ASynchronizableObject> *)obj];
            }
        }
    }];
    return result.copy;
}

- (NSSet <NSManagedObject<ASynchronizableObject> *> *)deletedObjects {
    __block NSMutableSet <NSManagedObject<ASynchronizableObject> *> *result = [NSMutableSet new];
    [self performBlockAndWait:^{
        for (NSManagedObject *obj in super.deletedObjects) {
            if ([obj conformsToProtocol:@protocol(ASynchronizableObject)]) {
                [result addObject:(NSManagedObject<ASynchronizableObject> *)obj];
            }
        }
    }];
    return result.copy;
}

- (void)setAgregator:(id<ASDataSyncAgregator>)agregator {
    _agregator = agregator;
}

+ (NSException *)incompatibleEntityExceptionWithEntityName:(NSString *)entityName entityClassName:(NSString *)entityClassName {
    return [NSException exceptionWithName:@"IncompatibleEntity"
                                   reason:[NSString stringWithFormat:@"Entity <%@> class <%@> not conformsToProtocol ASynchronizableObject",
                                           entityName, entityClassName]
                                 userInfo:nil];
}

- (NSManagedObject *)insertRecievedObject:(ASerializableObject *)recievedObject {
    NSManagedObject *object = [self insertTo:recievedObject.entityName];
    NSString *entityClassName = [[NSEntityDescription entityForName:recievedObject.entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASynchronizableObject)]) {
        NSManagedObject <ASynchronizableObject> *synchronizableObject = (NSManagedObject <ASynchronizableObject> *)object;
        synchronizableObject.uniqueUUIDData = recievedObject.uniqueUUIDData;
        synchronizableObject.modificationDate = recievedObject.modificationDate;
        synchronizableObject.keyedProperties = recievedObject.keyedProperties;
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:recievedObject.entityName entityClassName:entityClassName];
    }
    return object;
}

- (NSManagedObject <ASynchronizableObject> *)objectByuniqueUUIDData:(NSData *)uniqueUUIDData entityName:(NSString *)entityName {
    NSManagedObject <ASynchronizableObject> *resultObject = nil;
    NSString *entityClassName = [[NSEntityDescription entityForName:entityName inManagedObjectContext:self] managedObjectClassName];
    if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASynchronizableObject)]) {
        Class <ASynchronizableObject> entityClass = NSClassFromString(entityClassName);
        NSArray <NSManagedObject *> *objects = [self selectFrom:entityName
                                                          where:[entityClass predicateWithUniqueUUIDData:uniqueUUIDData]];
        if (objects.count == 1) {
            resultObject = (NSManagedObject <ASynchronizableObject> *)objects[0];
        } else if (objects.count) {
            resultObject = (NSManagedObject <ASynchronizableObject> *)objects[0];
            @throw [NSException exceptionWithName:@"DataBase UNIQUE constraint violated"
                                           reason:[NSString stringWithFormat:@"Object count with UUID <%@>: %ld\n"
                                                   "Check your ASynchronizableDescription protocol implementation for Entity <%@>",
                                                   resultObject.UUIDString, (unsigned long)objects.count,
                                                   entityName
                                                   ]
                                         userInfo:nil];
        }
    } else {
        @throw [self.class incompatibleEntityExceptionWithEntityName:entityName entityClassName:entityClassName];
    }
    return resultObject;
}

- (void)objectByuniqueUUIDData:(NSData *)uniqueUUIDData entityName:(NSString *)entityName fetch:(FetchObject)fetch {
    [self performBlock:^{
        NSManagedObject <ASynchronizableObject> *object;
        @try {
            object = [self objectByuniqueUUIDData:uniqueUUIDData entityName:entityName];
        } @catch (NSException *exception) {
            NSLog(@"[ERROR] %s Exception: %@", __PRETTY_FUNCTION__, exception);
        } @finally {
            fetch(object);
        }
    }];
}

- (NSManagedObject <ASynchronizableObject> *)objectByDescription:(ASerializableDescription *)descriptionObj {
    return [self objectByuniqueUUIDData:descriptionObj.uniqueUUIDData entityName:descriptionObj.entityName];
}

- (void)mergeWithRecievedContext:(ASerializableContext *)recievedContext {
    if ([self hasChanges]) {
        [recievedContextQueue addObject:recievedContext];
    } else {
        [self enqueueMergeBlockWithRecievedContext:recievedContext];
        [self saveContextAsync];
    }
}

- (void)enqueueMergeBlockWithRecievedContext:(ASerializableContext *)recievedContext {
    [self performBlock:^{
        NSMutableArray <NSManagedObject <ASynchronizableRelatableObject> *> *recievedRelatableObjectArray = [NSMutableArray new];
        NSMutableArray <NSDictionary <NSString *, ASerializableDescription *> *> *arrayOfDescriptionByRelationKey = [NSMutableArray new];
        NSMutableArray <NSManagedObject <ASynchronizableMultiRelatableObject> *> *recievedMultiRelatableObjectArray = [NSMutableArray new];
        NSMutableArray <NSDictionary <NSString *, NSSet <ASerializableDescription *> *> *> *arrayOfSetOfDescriptionsByRelationKey = [NSMutableArray new];
        
        for (ASerializableObject *recievedObject in recievedContext.updatedObjects) {
            @try {
                NSManagedObject <ASynchronizableObject> *synchronizableObject = [self objectByDescription:recievedObject];
                if (synchronizableObject) {
                    if ([recievedObject.modificationDate compare:synchronizableObject.modificationDate] != NSOrderedAscending) {
                        synchronizableObject.keyedProperties = recievedObject.keyedProperties;
                        synchronizableObject.modificationDate = recievedObject.modificationDate;
                    } else {
                        NSLog(@"[WARNING] %s dequeue UPDATE: recieved object with UUID <%@> out of date", __PRETTY_FUNCTION__, recievedObject.UUIDString);
                    }
                } else {
                    synchronizableObject = (NSManagedObject <ASynchronizableObject> *)[self insertRecievedObject:recievedObject];
                }
                //relations to buffer
                if ([recievedObject isKindOfClass:[ASerializableRelatableObject class]]) {
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
                        NSManagedObject <ASynchronizableObject> *synchronizableObject = [self objectByDescription:descriptionByRelationKey[relationKey]];
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
                        NSManagedObject <ASynchronizableObject> *synchronizableObject = [self objectByDescription:description];
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
                NSManagedObject <ASynchronizableObject> *synchronizableObject = [self objectByDescription:recievedDescription];
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

- (void)saveContextAsync {
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

- (void)performAndSave:(void (^)(void))block {
    [self performBlock:^{
        block();
        [self saveAndReloadData];
    }];
}

- (void)commit {
    if ([self hasChanges]) {
        if (self.agregator) [self.agregator willCommitContext:self];
        [self performBlock:^{
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
    if (recievedContextQueue.count) {
        for (int i = 0; i < recievedContextQueue.count; i++) {
            [self enqueueMergeBlockWithRecievedContext:recievedContextQueue[i]];
        }
        [self saveContextAsync];
        [recievedContextQueue removeAllObjects];
    }
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
        recievedContextQueue = [NSMutableArray new];
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
    }
    return self;
}

#pragma mark - overload

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
        if ([NSClassFromString(entityClassName) conformsToProtocol:@protocol(ASynchronizableDescription)]) {
            NSManagedObject <ASynchronizableDescription> *synchronizableObject = (NSManagedObject <ASynchronizableDescription> *)object;
            synchronizableObject.uniqueUUIDData = [[NSUUID UUID] data];
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



@end
