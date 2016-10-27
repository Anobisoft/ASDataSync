//
//  ASerializableRelation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASerializableDescription.h"

#ifndef ASerializableRelation_h
#define ASerializableRelation_h

@interface ASerializableRelation : NSObject <NSCoding>

@property (nonatomic, strong) ASerializableDescription *objectDescription;
@property (nonatomic, strong) ASerializableDescription *relatedDescription;
@property (nonatomic, strong) NSString *relationKey;

+ (instancetype)instantiateWithSynchronizableDescription:(id<ASynchronizableDescription>)descriptionObj relatedDescription:(id <ASynchronizableDescription>)relatedDescription relationKey:(NSString *)relationKey;

@end

#endif
