//
//  ASCloudTransaction.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudTransaction.h"
#import "ASCloudRecordRepresentation.h"
#import "CKRecord+ASDataSync.h"

@implementation ASCloudTransaction {
    NSSet <NSObject<ASMappedObject> *> *_updatedObjects;
    NSSet <NSObject<ASDescription> *> *_deletedDescriptions;
}

+ (instancetype)transactionWithUpdatedRecords:(NSSet <CKRecord<ASMappedObject> *> *)updatedRecords deletionInfoRecords:(NSSet <CKRecord *> *)deletionInfoRecords mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithUpdatedRecords:updatedRecords deletionInfoRecords:deletionInfoRecords mapping:mapping];
}

- (instancetype)initWithUpdatedRecords:(NSSet <CKRecord<ASMappedObject> *> *)updatedRecords deletionInfoRecords:(NSSet <CKRecord *> *)deletionInfoRecords mapping:(ASCloudMapping *)mapping {
    if (self = [super init]) {
        NSMutableSet *tmpSet;
        if (updatedRecords.count) {
            tmpSet = [NSMutableSet new];
            for (CKRecord<ASMappedObject> *record in updatedRecords) {
                [tmpSet addObject:[record mappedObjectWithMapping:mapping]];
            }
            _updatedObjects = tmpSet.copy;
        } else _updatedObjects = nil;
        if (deletionInfoRecords.count) {
            tmpSet = [NSMutableSet new];
            for (CKRecord *record in deletionInfoRecords) {
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
