//
//  NSObject+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 26.12.16.
//  Copyright © 2016 anobisoft. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSObject+ASDataSync.h"
#import "ASynchronizable.h"

@implementation NSObject (ASDataSync)

NSString *uuidString;

- (NSString *)UUIDString {
    if (!uuidString && [self conformsToProtocol:@protocol(ASynchronizableDescription)]) {
        NSData *data = ((NSManagedObject <ASynchronizableDescription> *)self).uniqueID;
        uuidString = ((NSUUID *)[NSKeyedUnarchiver unarchiveObjectWithData:data]).UUIDString;
    }
    return uuidString;
}

@end
