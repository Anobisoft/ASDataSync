//
//  ASRepresentableTransaction.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 09.02.17.
//  Copyright © 2017 anobisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASPrivateProtocol.h"

@interface ASRepresentableTransaction : NSObject <ASRepresentableTransaction>

+ (instancetype)instantiateWithContext:(id <ASRepresentableTransaction>)context;

@end