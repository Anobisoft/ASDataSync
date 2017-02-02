//
//  ASCloudManager.h
//  ASDataSyncCloud
//
//  Created by Stanislav Pletnev on 2016-12-21
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASCloudMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASCloudManager : NSObject

+ (instancetype)defaultManager;
- (instancetype)initWithContainerIdentifier:(NSString *)identifier;
- (BOOL)ready;



@end

NS_ASSUME_NONNULL_END
