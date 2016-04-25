//
//  HZWebViewManager.m
//  app
//
//  Created by 刘华舟 on 15/12/21.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "HZWebViewManager.h"

@interface HZWebViewManager()


@end



@implementation HZWebViewManager


+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    static HZWebViewManager* _webViewManager = nil;
    dispatch_once(&onceToken, ^{
        _webViewManager = [[self alloc] initManager];
    });
    return _webViewManager;
}

- (instancetype)initManager
{
    if (self = [super init]) {
        _hybridWebView = [[HZHybridWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _hybridWebView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    
    return self;
}



- (HZHybridWebView *)hybridWebView
{
    if (_hybridWebView == nil) {
        _hybridWebView = [[HZHybridWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _hybridWebView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    return _hybridWebView;
}

- (void)stopAllLoading
{
    [_hybridWebView.webView stopLoading];
}

- (void)resetHybridWebView
{
    [_hybridWebView loadRequestFromString:@""];
}



- (void)dealloc
{
    _hybridWebView.delegate = nil;
    [_hybridWebView loadRequestFromString:@""];
    [_hybridWebView.webView stopLoading];
    [_hybridWebView removeFromSuperview];
    
    _hybridWebView = nil;
    
    NSLog(@"_webView dealloc");
}

@end
