//
//  NSMassKit.m
//  UIExternal
//
//  Created by huangbenhua on 15-3-24.
//  Copyright (c) 2015年 jiankangdaren. All rights reserved.
//

#import "NSMassKit.h"

@implementation NSArray(NSMassKit)


-(id)objectAtIndex:(int)idx
            getter:(id(^)())get
{
    if (idx < 0 || idx >= [self count]) {
        if (!get) {
            return nil;
        }
        return get();
    }
    return [self objectAtIndex:idx];
};

-(BOOL)isEmpty
{
    return [self count] < 1;
}

-(id)firstValue
{
    if ([self count] < 1) {
        return nil;
    }
    return [self firstObject];
}

-(id)lastValue
{
    if ([self count] < 1) {
        return nil;
    }
    return [self lastObject];
}

-(id)valueAtPosition:(int)idx
{
    if (idx < 0) {
        idx += [self count];
    }
    if (idx < 0 || idx >= [self count]) {
        return nil;
    }
    return [self objectAtIndex:idx];
};

-(id)valueAtIndex:(int)idx
{
    if (idx < 0 || idx >= [self count]) {
        return nil;
    }
    return [self objectAtIndex:idx];
};

-(NSArray*)arrayAtPosition:(int)idx
{
    id v = [self valueAtPosition:idx];
    if (v == nil) {
        return @[];
    }
    if ([v isKindOfClass:[NSArray class]]) {
        return v;
    }
    return @[v];
};

-(NSArray*)arrayAtIndex:(int)idx
{
    id v = [self valueAtIndex:idx];
    if (v == nil) {
        return @[];
    }
    if ([v isKindOfClass:[NSArray class]]) {
        return v;
    }
    return @[v];
};

@end

@implementation NSMutableArray(NSMassKit)

-(id)objectAtIndex:(int)idx
           creator:(id (^)())create
{
    if (idx < 0 || idx >= [self count]) {
        if (!create) {
            return nil;
        }
        id val = create();
        if (val) {
            [self addObject:val];
        }
        return val;
    }
    return [self objectAtIndex:idx];
}

@end

@implementation NSDictionary(NSMassKit)

-(id)objectForKey:(NSString*)key nilValue:(id)nilVal{
    if (key == nil) {
        return nilVal;
    }
    id val = [self objectForKey:key];
    if (val == nil) {
        return nilVal;
    }
    return val;
}

-(NSString*)stringForKey:(NSString*)key
{
    return [self stringForKey:key nilValue:@""];
}

-(NSString*)stringForKey:(NSString*)key nilValue:(NSString*)nilValue
{
    if (key == nil) {
        return nilValue;
    }
    id str = [self objectForKey:key];
    if (!str) {
        return nilValue;
    }
    if ([str isKindOfClass:NSString.class]) {
        return str;
    }
    return [NSString stringWithFormat:@"%@", str];
};

-(NSDictionary *)dictForKey:(NSString*)key
{
    if (key == nil) {
        return @{};
    }
    id val = [self objectForKey:key];
    if (!val) {
        return @{};
    }
    if ([val isKindOfClass:NSDictionary.class]) {
        return val;
    }
    return @{key:val};
}

-(NSArray*)arrayForKey:(NSString*)key
{
    if (key == nil) {
        return @[];
    }
    id arr = [self objectForKey:key];
    if (!arr) {
        return @[];
    }
    if ([arr isKindOfClass:NSArray.class]) {
        return arr;
    }
    return @[arr];
};

-(NSNumber *)numberForKey:(NSString*)key {
    return [self numberForKey:key nilValue:@0];
}

-(NSNumber *)numberForKey:(NSString*)key nilValue:(NSNumber *)nilVal
{
    if (key == nil) {
        return nilVal;
    }
    id val = [self objectForKey:key];
    if (val == nil) {
        return nilVal;
    }
    if ([val isKindOfClass:NSNumber.class]) {
        return val;
    }
    if (![val isKindOfClass:NSString.class]) {
        val = [NSString stringWithFormat:@"%@", val];
    }
    double f = [(NSString*)val doubleValue];
    return [NSNumber numberWithDouble:f];
}


-(NSInteger)intForKey:(NSString*)key
{
    return [self intForKey:key nilValue:0];
}

-(NSInteger)intForKey:(NSString*)key
          nilValue:(int)nilVal
{
    NSNumber * num = [self numberForKey:key nilValue:nil];
    if (num == nil) {
        return nilVal;
    }
    return num.integerValue;
}

-(float)floatValueForKey:(NSString*)key
{
    return [self floatValueForKey:key nilValue:0.0f];
}

-(float)floatValueForKey:(NSString*)key
              nilValue:(float)nilVal
{
    NSNumber * num = [self numberForKey:key nilValue:nil];
    if (num == nil) {
        return nilVal;
    }
    return num.floatValue;
}

@end

@implementation NSMassKit

+(id)objectFrom:(NSDictionary*)dict
          ofKey:(id)key
{
    if (dict) {
        return [dict objectForKey:key];
    }
    return nil;
};

+(NSArray*)arrayFrom:(NSDictionary*)dict ofKey:(id)key
{
    return [self arrayOf:[self objectFrom:dict ofKey:key]];
};

+(NSArray*)arrayOf:(id)obj
{
    if (obj == nil) {
        return @[];
    }
    if ([obj isKindOfClass:NSArray.class]) {
        return obj;
    }
    return @[obj];
};

+(NSArray*)arrayFrom:(NSArray *)arr atIndex:(int)idx
{
    return [self arrayOf:[self objectFrom:arr atIndex:idx]];
};

+(id)objectFrom:(NSDictionary*)dict ofKey:(id)key nilValue:(id)obj
{
    id v = [self objectFrom:dict ofKey:key];
    if (v == nil) {
        return obj;
    }
    return v;
};

+(id)objectFrom:(NSArray *)arr
        atIndex:(int)idx
{
    if (arr && [arr count] > idx) {
        if (idx < 0) {
            idx += [arr count];
            if (idx < 0) {
                return nil;
            }
        }
        return [arr objectAtIndex:idx];
    }
    return nil;
};

+(id)objectFrom:(NSArray*)arr atIndex:(int)idx  nilValue:(id)obj
{
    id v = [self objectFrom:arr atIndex:idx];
    if (v == nil) {
        return obj;
    }
    return v;
};


+(id)objectFrom:(NSArray *)arr atIndex:(int)idx atLeast:(int)length
{
    if (arr && [arr count] >= length) {
        return [self objectFrom:arr atIndex:idx];
    }
    return nil;
};


+(id)firstOf:(NSArray *)arr atLeast:(int)len
{
    return [self objectFrom:arr atIndex:0 atLeast:len];
};

+(id)firstOf:(NSArray *)arr{
    return [self objectFrom:arr atIndex:0];
};

+(id)lastOf:(NSArray *)arr{
    return [self objectFrom:arr atIndex:-1];
};


@end
