//
//  ASerializableDescription.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASerializableDescription.h"
#import "NSUUID+NSData.h"

#define AS_uniqueUUIDDataKey @"AS_uniqueUUIDData"
#define AS_modificationDateKey @"AS_modificationDate"
#define AS_entityNameKey @"AS_entityName"

@interface ASerializableDescription()
    
@end

@implementation ASerializableDescription {
    NSString *uuidString;
}

+ (NSPredicate *)predicateWithUniqueUUIDData:(NSData *)uniqueUUIDData {
    return nil;
}

+ (NSString *)entityName {
    return nil;
}

@synthesize uniqueUUIDData = _uniqueUUIDData;
@synthesize entityName = _entityName;
@synthesize modificationDate = _modificationDate;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uniqueUUIDData forKey:AS_uniqueUUIDDataKey];
    [aCoder encodeObject:_modificationDate forKey:AS_modificationDateKey];
    [aCoder encodeObject:_entityName forKey:AS_entityNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _uniqueUUIDData = [aDecoder decodeObjectForKey:AS_uniqueUUIDDataKey];
        _modificationDate = [aDecoder decodeObjectForKey:AS_modificationDateKey];
        _entityName = [aDecoder decodeObjectForKey:AS_entityNameKey];
    }
    return self;
}

- (NSString *)UUIDString {
    if (!uuidString) {
        uuidString = [NSUUID uuidWithData:self.uniqueUUIDData].UUIDString;
    }
    return uuidString;
}

- (instancetype)initWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    if (self = [super init]) {
        _uniqueUUIDData = descriptionObj.uniqueUUIDData;
        _entityName = [[descriptionObj class] entityName];
        _modificationDate = [descriptionObj modificationDate];
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    return [[self alloc] initWithSynchronizableDescription:descriptionObj];
}

@end
