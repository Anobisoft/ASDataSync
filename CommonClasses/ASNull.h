//
//  ASNull.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 23.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASynchronizable.h"

@interface ASNull : NSNull <ASynchronizableDescription>

+ (instancetype)null;

@end
