//
//  ASDevice.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "ASDevice.h"
#import "NSUUID+NSData.h"
#import "ASCloudRecord.h"

@interface ASDevice()

@end

@implementation ASDevice {

}

+ (instancetype)deviceWithMappedObject:(id <ASMappedObject>)mappedObject {
    return [[self alloc] initWithMappedObject:mappedObject];
}

- (instancetype)initWithMappedObject:(id <ASMappedObject>)mappedObject {
    if (self = [super init]) {
        self.uniqueData = mappedObject.uniqueData;
        self.modificationDate = mappedObject.modificationDate;
        self.keyedDataProperties = mappedObject.keyedDataProperties;
    }
    return self;
}

- (NSString *)entityName {
    return [self.class entityName];
}

+ (NSString *)entityName {
    return @"Device";
}

- (void)setKeyedDataProperties:(NSDictionary<NSString *,id<NSCoding>> *)keyedDataProperties {
    self.keyedDataProperties = keyedDataProperties;
}

- (void)setModificationDate:(NSDate *)modificationDate {
    self.modificationDate = modificationDate;
}


@end
