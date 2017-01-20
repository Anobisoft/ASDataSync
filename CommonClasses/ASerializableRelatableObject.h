//
//  ASerializableRelatableObject.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 20.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import "ASerializableObject.h"

@interface ASerializableRelatableObject : ASerializableObject

@property (nonatomic, strong, readonly) NSDictionary <NSString *, ASerializableDescription *> *descriptionByRelationKey;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSSet <ASerializableDescription *> *> *setOfDescriptionsByRelationKey;

@end
