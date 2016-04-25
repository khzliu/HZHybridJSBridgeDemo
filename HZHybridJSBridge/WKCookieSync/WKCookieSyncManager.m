//
//  WKCookieSyncManager.m
//  app
//
//  Created by 刘华舟 on 15/12/18.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "WKCookieSyncManager.h"


@interface WKCookieSyncManager()


@end

static WKCookieSyncManager* _wkckSyncManager;
@implementation WKCookieSyncManager

+ (instancetype)shareManager{
    if (_wkckSyncManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _wkckSyncManager = [[self alloc] initManager];
        });
    }
    return _wkckSyncManager;
}

- (instancetype)initManager
{
    if (self = [super init]) {
        _processPool = [[WKProcessPool alloc] init];
    }
    
    return self;
}

- (WKProcessPool *)processPool{
    if (_processPool == nil) {
        _processPool = [[WKProcessPool alloc] init];
    }
    return _processPool;
}

- (void)shareCookiesForWKWebView
{
    if (NSClassFromString(@"WKWebView")) {
        
        WKWebViewConfiguration* wkWebConf = [[WKWebViewConfiguration alloc] init];
        
        wkWebConf.processPool = [WKCookieSyncManager shareManager].processPool;
        
        WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:wkWebConf];
        
        NSURL* shareCookieURL = [NSURL URLWithString:@"http://www.o2planet.net/"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:shareCookieURL];

        NSArray *arrCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        
        NSDictionary *dictCookies = [NSHTTPCookie requestHeaderFieldsWithCookies:arrCookies];
        
        [request setValue: [dictCookies objectForKey:@"Cookie"] forHTTPHeaderField: @"Cookie"];
        
        [wkWebView loadRequest:request];
    }
}



@end
