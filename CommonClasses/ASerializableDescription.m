//
//  ASerializableDescription.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASerializableDescription.h"
#import "NSUUID+NSData.h"

#define AS_uniqueDataKey @"AS_uniqueData"
#define AS_modificationDateKey @"AS_modificationDate"
#define AS_entityNameKey @"AS_entityName"

@interface ASerializableDescription()
    
@end

@implementation ASerializableDescription {
    NSString *uuidString;
}

@synthesize uniqueData = _uniqueData;
@synthesize entityName = _entityName;
@synthesize modificationDate = _modificationDate;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uniqueData forKey:AS_uniqueDataKey];
    [aCoder encodeObject:_modificationDate forKey:AS_modificationDateKey];
    [aCoder encodeObject:_entityName forKey:AS_entityNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _uniqueData = [aDecoder decodeObjectForKey:AS_uniqueDataKey];
        _modificationDate = [aDecoder decodeObjectForKey:AS_modificationDateKey];
        _entityName = [aDecoder decodeObjectForKey:AS_entityNameKey];
    }
    return self;
}

- (NSString *)UUIDString {
    if (!uuidString) {
        uuidString = self.uniqueData.UUIDString;
    }
    return uuidString;
}

- (instancetype)initWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    if (self = [super init]) {
        _uniqueData = descriptionObj.uniqueData;
        _entityName = [descriptionObj entityName];
        _modificationDate = [descriptionObj modificationDate];
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    return [[self alloc] initWithSynchronizableDescription:descriptionObj];
}

@end
