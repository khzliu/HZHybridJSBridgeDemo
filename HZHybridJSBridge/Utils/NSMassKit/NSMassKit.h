//
//  NSMassKit.h
//  UIExternal
//
//  Created by huangbenhua on 15-3-24.
//  Copyright (c) 2015年 jiankangdaren. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] doubleValue]


@interface NSArray(NSMassKit)

-(id)objectAtIndex:(int)idx getter:(id(^)())get;

-(id)valueAtPosition:(int)idx;

-(id)valueAtIndex:(int)idx;

-(NSArray*)arrayAtPosition:(int)idx;

-(NSArray*)arrayAtIndex:(int)idx;

-(BOOL)isEmpty;

-(id)firstValue;

-(id)lastValue;

@end

@interface NSMutableArray(NSMassKit)

-(id)objectAtIndex:(int)idx creator:(id(^)())create;

@end

@interface NSDictionary(NSMassKit)

-(id)objectForKey:(NSString*)key nilValue:(id)nilVal;

-(NSDictionary*)dictForKey:(NSString*)key;

-(NSArray*)arrayForKey:(NSString*)key;

-(NSString*)stringForKey:(NSString*)key;

-(NSString*)stringForKey:(NSString*)key
                nilValue:(NSString*)nilValue;

-(NSString*)numberForKey:(NSString*)key;

-(NSNumber*)numberForKey:(NSString*)key
                nilValue:(NSNumber*)nilVal;

-(NSInteger)intForKey:(NSString*)key;

-(NSInteger)intForKey:(NSString*)key
                nilValue:(int)nilVal;

-(float)floatValueForKey:(NSString*)key;

-(float)floatValueForKey:(NSString*)key
                nilValue:(float)nilVal;

@end


@interface NSMassKit : NSObject

+(id)objectFrom:(NSDictionary*)dict ofKey:(id)key;

+(NSArray*)arrayFrom:(NSDictionary*)dict ofKey:(id)key;

+(id)objectFrom:(NSDictionary*)dict ofKey:(id)key nilValue:(id)obj;

+(id)objectFrom:(NSArray *)arr atIndex:(int)idx;

+(NSArray*)arrayFrom:(NSArray *)arr atIndex:(int)idx;

+(NSArray*)arrayOf:(id)obj;

+(id)objectFrom:(NSArray *)arr atIndex:(int)idx nilValue:(id)obj;

+(id)objectFrom:(NSArray *)arr atIndex:(int)idx atLeast:(int)length;

+(id)firstOf:(NSArray *)arr atLeast:(int)len;

+(id)firstOf:(NSArray *)arr;

+(id)lastOf:(NSArray *)arr;



@end
