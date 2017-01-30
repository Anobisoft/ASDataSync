//
//  ASCloudTransaction.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 26.01.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPrivateProtocol.h"

@class ASCloudRecord;

@interface ASCloudTransaction : NSObject <ASRepresentableTransaction>

+ (instancetype)transactionWithUpdatedRecords:(NSSet <ASCloudRecord *> *)updatedRecords deletionInfoRecords:(NSSet <ASCloudRecord *> *)deletionInfoRecords mapping:(ASCloudMapping *)mapping;

@end
