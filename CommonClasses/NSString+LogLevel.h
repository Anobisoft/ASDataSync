//
//  NSString+LogLevel.h
//  ASDataSync
//
//  Created by Stanislav Pletnev on 11.06.16.
//  Copyright © 2016 Anobisoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LogLevel)

//by decreasing importance
- (void)logEmergency;
//system is unusable
- (void)logAlert;
//action must be taken immediately
- (void)logCritical;
//critical conditions
- (void)logError;
//error conditions
- (void)logWarning;
//warning conditions
- (void)logNotice;
//normal, but significant, condition
- (void)logInfo;
//informational message
- (void)logDebug;
//debug-level message

@end
