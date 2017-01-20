//
//  ASerializableObject.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASerializableDescription.h"

#ifndef ASerializableObject_h
#define ASerializableObject_h


@interface ASerializableObject : ASerializableDescription <ASynchronizableObject>

+ (instancetype)instantiateWithSynchronizableObject:(id <ASynchronizableObject>)object;

@end

#endif
