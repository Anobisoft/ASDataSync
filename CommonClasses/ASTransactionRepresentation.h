//
//  ASTransactionRepresentation.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#ifndef ASTransactionRepresentation_h
#define ASTransactionRepresentation_h

#import "ASRelatableObjectRepresentation.h"
#import "ASPrivateProtocol.h"

@interface ASTransactionRepresentation : NSObject <ASRepresentableTransaction, NSSecureCoding>

+ (instancetype)instantiateWithRepresentableTransaction:(id <ASRepresentableTransaction>)transaction;

@end

#endif
