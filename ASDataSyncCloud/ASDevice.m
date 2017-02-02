//
//  ASDevice.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASDevice.h"
#import "NSUUID+NSData.h"
#import "ASCloudInternalConst.h"

@interface ASObjectRepresentation(protected)

- (instancetype)initWithMappedObject:(id <ASMappedObject>)object;

@end

@implementation ASDevice

+ (instancetype)deviceWithMappedObject:(id <ASMappedObject>)mappedObject {
    return [[self alloc] initWithMappedObject:mappedObject];
}

- (instancetype)initWithMappedObject:(id <ASMappedObject>)mappedObject {
    if (self = [super initWithMappedObject:mappedObject]) {
        
    }
    return self;
}

- (void)setUUID:(NSUUID *)UUID {
    _uniqueData = UUID.data;
}

- (void)setUniqueData:(NSData *)uniqueData {
    _uniqueData = uniqueData;
}

- (void)setModificationDate:(NSDate *)modificationDate {
    _modificationDate = modificationDate;
}

- (void)setKeyedDataProperties:(NSDictionary<NSString *,NSObject<NSCoding> *> *)keyedDataProperties {
    _keyedDataProperties = keyedDataProperties;
}

- (NSString *)entityName {
    return [self.class entityName];
}

+ (NSString *)entityName {
    return ASCloudDevicesInfoRecordType;
}


@end
