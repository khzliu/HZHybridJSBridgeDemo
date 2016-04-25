//
//  YYXQJSOCBridge.m
//  app
//
//  Created by 刘华舟 on 16/2/24.
//  Copyright © 2016年 hdaren. All rights reserved.
//

#import "YYXQJSOCBridge.h"

@implementation YYXQJSOCBridge


//获取版本号
- (NSDictionary *)agent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(agent)]) {
        return [self.delegate agent];
    }
    return @{};
}
//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype
{
    [self call:jstype data:nil];
}


//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data
{
    [self call:jstype data:data callback:nil];
}


- (void)call:(NSNumber *)jstype data:(NSDictionary *)data callback:(NSString *)cb
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(call:data:callback:)]) {
        [self.delegate call:jstype data:data callback:cb];
    }
}

-(NSString*)syncall:(NSNumber *)jstype data:(NSDictionary*)data extra:(NSDictionary*)extra
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(syncall:data:extra:)]) {
        return [self.delegate syncall:jstype data:data extra:extra];
    }
    return @"";
}

@end
