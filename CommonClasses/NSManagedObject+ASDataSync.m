//
//  NSManagedObject+ASDataSync.m
//  ASDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import "NSManagedObject+ASDataSync.h"

@implementation NSManagedObject (ASDataSync)

NSString *uuidString;

- (NSString *)UUIDString {
    if (!uuidString && [self conformsToProtocol:@protocol(ASynchronizableDescription)]) {
        NSData *data = ((NSManagedObject <ASynchronizableDescription> *)self).uniqueID;
        uuidString = ((NSUUID *)[NSKeyedUnarchiver unarchiveObjectWithData:data]).UUIDString;
    }
    return uuidString;
}

@end
