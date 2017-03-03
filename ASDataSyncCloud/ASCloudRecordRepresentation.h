//
//  ASCloudRecordRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 02.02.17.
//  Copyright © 2017 Anobisoft. All rights reserved.
//

#import "ASCloudDescriptionRepresentation.h"

@class CKRecord, ASCloudMapping;

@interface ASCloudRecordRepresentation : ASCloudDescriptionRepresentation <ASMappedObject, ASRelatableToOne, ASRelatableToMany>

+ (instancetype)instantiateWithCloudRecord:(CKRecord<ASMappedObject> *)cloudRecord mapping:(ASCloudMapping *)mapping;

@end
