//
//  ASerializableDescription.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"

#ifndef ASerializableDescription_h
#define ASerializableDescription_h

@interface ASerializableDescription : NSObject <ASynchronizableDescription, NSCoding>

@property (nonatomic, strong) NSString *entityName;

+ (instancetype)instantiateWithSynchronizableDescription:(id <ASynchronizableDescription>)descriptionObj;

- (NSString *)UUIDString;

@end

#endif
