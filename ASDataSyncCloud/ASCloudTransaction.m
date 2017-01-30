//
//  ASCloudTransaction.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudTransaction.h"
#import "ASCloudRecord.h"

@implementation ASCloudTransaction {
    NSSet <id <ASMappedObject>> *_updatedObjects;
    NSSet <id <ASDescription>> *_deletedDescriptions;
}

+ (instancetype)transactionWithUpdatedRecords:(NSSet <ASCloudRecord *> *)updatedRecords deletionInfoRecords:(NSSet <ASCloudRecord *> *)deletionInfoRecords mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithUpdatedRecords:updatedRecords deletionInfoRecords:deletionInfoRecords mapping:mapping];
}

- (instancetype)initWithUpdatedRecords:(NSSet <ASCloudRecord *> *)updatedRecords deletionInfoRecords:(NSSet <ASCloudRecord *> *)deletionInfoRecords mapping:(ASCloudMapping *)mapping {
    if (self = [super init]) {
        NSMutableSet *tmpSet;
        if (updatedRecords.count) {
            tmpSet = [NSMutableSet new];
            for (ASCloudRecord *record in updatedRecords) {
                [tmpSet addObject:[record mappedObjectWithMapping:mapping]];
            }
            _updatedObjects = tmpSet.copy;
        } else _updatedObjects = nil;
        if (deletionInfoRecords.count) {
            tmpSet = [NSMutableSet new];
            for (ASCloudRecord *record in deletionInfoRecords) {
                [tmpSet addObject:[record descriptionOfDeletedObjectWithMapping:mapping]];
            }
            _deletedDescriptions = tmpSet.copy;
        } else _deletedDescriptions = nil;

    }
    return self;
}

- (NSSet <id <ASMappedObject>> *)updatedObjects {
    return _updatedObjects;
}

- (NSSet <id <ASDescription>> *)deletedObjects {
    return _deletedDescriptions;
}

- (NSString *)contextIdentifier {
    return nil;
}


@end
