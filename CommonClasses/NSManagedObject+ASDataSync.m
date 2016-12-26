//
//  NSManagedObject+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "NSManagedObject+ASDataSync.h"
#import "NSString+LogLevel.h"

@implementation NSManagedObject (ASDataSync)

- (NSString *)entityName {
    return [NSString stringWithString:self.entity.name];
}

+ (NSString *)entityName {
    return [NSString stringWithString:self.entity.name];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context limit:0 fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context orderBy:nil limit:limit fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context orderBy:(NSArray<NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context orderBy:sortDescriptors limit:0 fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context where:nil orderBy:sortDescriptors limit:limit fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context where:clause limit:0 fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context where:clause orderBy:nil limit:limit fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors fetch:(FetchArray)fetch {
    [self selectObjectsFromContext:context where:clause orderBy:sortDescriptors limit:0 fetch:fetch];
}

+ (void)selectObjectsFromContext:(NSManagedObjectContext *)context where:(NSPredicate *)clause orderBy:(nullable NSArray <NSSortDescriptor *> *)sortDescriptors limit:(NSUInteger)limit fetch:(FetchArray)fetch {
    [context performBlock:^{
        NSFetchRequest *request = [self fetchRequest];
        request.predicate = clause;
        [request setSortDescriptors:sortDescriptors];
        [request setFetchLimit:limit];
        NSError *error = nil;
        NSArray *entities = [context executeFetchRequest:request error:&error];
        if (error) [[NSString stringWithFormat:@"%s %@\n%@", __PRETTY_FUNCTION__, error.localizedDescription, error.userInfo] logError];
        fetch(entities);
    }];
}

@end
