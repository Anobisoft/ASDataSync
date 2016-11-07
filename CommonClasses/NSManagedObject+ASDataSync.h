//
//  NSManagedObject+ASDataSync.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASynchronizable.h"

typedef void (^FetchArray)(NSArray <__kindof NSManagedObject <ASynchronizableObject> *> *objects);

@interface NSManagedObject (ASDataSync)

- (NSString *)UUIDString;
- (NSString *)entityName;

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context limit:(NSUInteger)limit fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch;
+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch;

@end
