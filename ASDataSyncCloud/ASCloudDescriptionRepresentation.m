//
//  ASCloudDescriptionRepresentation.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASCloudDescriptionRepresentation.h"
#import "NSUUID+NSData.h"
#import "ASCloudMapping.h"

@implementation ASCloudDescriptionRepresentation {
    NSString *_entityName, *_uuidString;
    NSData *_uniqueData;
}

- (NSString *)entityName {
    return _entityName;
}

- (NSData *)uniqueData {
    return _uniqueData;
}

- (NSString *)UUIDString {
    if (!_uuidString) _uuidString = _uniqueData.UUIDString;
    return _uuidString;
}

+ (instancetype)instantiateWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping {
    return [[self alloc] initWithRecordType:recordType uniqueData:uniqueData mapping:mapping];
}

- (instancetype)initWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping {
    if (self = [super init]) {
        _entityName = mapping.reverseMap[recordType];
        _uniqueData = uniqueData;
    }
    return self;
}



@end
