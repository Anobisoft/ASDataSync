//
//  NSManagedObjectContext+SQLike.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>

#define ASC ascending:YES
#define DESC ascending:NO

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectContext (SQLike)

- (NSManagedObject *)insertTo:(nonnull NSString *)entityName;

- (NSArray *)selectFrom:(NSString *)entity;
- (NSArray *)selectFrom:(NSString *)entity limit:(NSUInteger)limit;
- (NSArray *)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors;
- (NSArray *)selectFrom:(NSString *)entity orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

- (NSArray *)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause;
- (NSArray *)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause limit:(NSUInteger)limit;
- (NSArray *)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors;
- (NSArray *)selectFrom:(NSString *)entity where:(nullable NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit;

@end

NS_ASSUME_NONNULL_END
