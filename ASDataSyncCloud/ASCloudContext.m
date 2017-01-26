//
//  ASCloudContext.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudContext.h"

@implementation ASCloudContext {
    NSSet <id <ASCloudRelatableRecord>> *_updatedRecords;
    NSSet <id <ASCloudDescription>> *_deletionInfoRecords;
}

+ (instancetype)contextWithUpdatedRecords:(NSSet <id <ASCloudRelatableRecord>> *)updatedRecords deletionInfoRecords:(NSSet <id <ASCloudDescription>> *)deletionInfoRecords {
    return [[self alloc] initWithUpdatedRecords:updatedRecords deletionInfoRecords:deletionInfoRecords];
}

- (instancetype)initWithUpdatedRecords:(NSSet <id <ASCloudRelatableRecord>> *)updatedRecords deletionInfoRecords:(NSSet <id <ASCloudDescription>> *)deletionInfoRecords {
    if (self = [super init]) {
        _updatedRecords = updatedRecords;
        _deletionInfoRecords = deletionInfoRecords;
    }
    return self;
}

- (NSSet <id <ASCloudRelatableRecord>> *)updatedRecords {
    return _updatedRecords;
}

- (NSSet <id <ASCloudDescription>> *)deletionInfoRecords {
    return _deletionInfoRecords;
}


@end
