//
//  NSManagedObject+ASDataSync.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 21.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASynchronizable.h"

@interface NSManagedObject (ASDataSync)

- (NSString *)UUIDString;

@end
