//
//  ASCloudDescriptionRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPublicProtocol.h"

@class ASCloudMapping;

@interface ASCloudDescriptionRepresentation : NSObject <ASDescription>

+ (instancetype)instantiateWithRecordType:(NSString *)recordType uniqueData:(NSData *)uniqueData mapping:(ASCloudMapping *)mapping;

@end
