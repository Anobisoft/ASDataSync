//
//  ASerializableDescription.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "ASerializableDescription.h"

#define AS_uniqueIDKey @"AS_uniqueID"
#define AS_modifyDateKey @"AS_modifyDate"
#define AS_entityNameKey @"AS_entityName"

@interface ASerializableDescription()
    
@end

@implementation ASerializableDescription {
    NSString *uuidString;
}

+ (NSPredicate *)predicateWithUniqueID:(NSData *)uniqueID {
    return nil;
}

+ (NSString *)entityName {
    return nil;
}

@synthesize uniqueID = _uniqueID;
@synthesize entityName = _entityName;
@synthesize modifyDate = _modifyDate;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_uniqueID forKey:AS_uniqueIDKey];
    [aCoder encodeObject:_modifyDate forKey:AS_modifyDateKey];
    [aCoder encodeObject:_entityName forKey:AS_entityNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _uniqueID = [aDecoder decodeObjectForKey:AS_uniqueIDKey];
        _modifyDate = [aDecoder decodeObjectForKey:AS_modifyDateKey];
        _entityName = [aDecoder decodeObjectForKey:AS_entityNameKey];
    }
    return self;
}

//- (NSString *)UUIDString {
//    if (!uuidString) {
//        uuidString = ((NSUUID *)[NSKeyedUnarchiver unarchiveObjectWithData:self.uniqueID]).UUIDString;
//    }
//    return uuidString;
//}

- (instancetype)initWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    if (self = [super init]) {
        _uniqueID = descriptionObj.uniqueID;
        _entityName = [[descriptionObj class] entityName];
        _modifyDate = [descriptionObj modifyDate];
    }
    return self;
}

+ (instancetype)instantiateWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj {
    return [[self alloc] initWithSynchronizableDescription:descriptionObj];
}

@end
