//
//  NSDate+ASUtilities.h
//  ASUtilities
//
//  Created by Stanislav Pletnev on 04.08.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#ifndef NSDate_ASUtilities_h
#define NSDate_ASUtilities_h

#import <Foundation/Foundation.h>

@interface NSDate (ASUtilities)

- (NSString *)logString;
- (NSString *)logLongString;
- (NSDate *)dayStart;
- (NSDate *)dateWithTime:(NSDate *)time;
- (NSDate *)nextDay;
- (NSDate *)previousDay;
- (NSTimeInterval)timeIntervalSinceDayStart;

@end

#endif
