//
//  NSDate+ASUtilities.h
//  ASUtilities
//
//  Created by Stanislav Pletnev on 04.08.16.
//  Copyright © 2016 Anobisoft. All rights reserved.
//

#import "NSDate+ASUtilities.h"

@implementation NSDate (ASUtilities)

#pragma mark - Debug

- (NSString *)logString {
    return [NSDateFormatter localizedStringFromDate:self
                                          dateStyle:NSDateFormatterShortStyle
                                          timeStyle:NSDateFormatterShortStyle];
}

- (NSString *)logLongString {
    return [NSDateFormatter localizedStringFromDate:self
                                          dateStyle:NSDateFormatterMediumStyle
                                          timeStyle:NSDateFormatterShortStyle];
}

- (NSDate *)dayStart {
    return [[NSCalendar currentCalendar] startOfDayForDate:self];
}

- (NSDate *)nextDay {
    return [[NSCalendar currentCalendar] startOfDayForDate:[[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:self options:NSCalendarMatchStrictly]];
}

- (NSDate *)previousDay {
    return [[NSCalendar currentCalendar] startOfDayForDate:[[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:self options:NSCalendarMatchStrictly]];
}

- (NSDate *)dateWithTime:(NSDate *)time {
    return [[[NSCalendar currentCalendar] startOfDayForDate:self] dateByAddingTimeInterval:[time timeIntervalSinceDayStart]];
}
- (NSTimeInterval)timeIntervalSinceDayStart {
    return [self timeIntervalSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:self]];
}

@end
