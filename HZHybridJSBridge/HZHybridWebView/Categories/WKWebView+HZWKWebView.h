//
//  WKWebView+HZWKWebView.h
//  HZWebView
//
//  Created by 刘华舟 on 15/5/11.
//  Copyright (c) 2015年 云图. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "HZWebViewProvider.h"

/*
 * This category extends WKWebView and conforms to the HZWebViewProvider protocol.
 */
@interface WKWebView (HZWKWebView) <HZWebViewProvider>

/*
 * Shorthand for setting WKUIDelegate and WKNavigationDelegate to the same class.
 */
- (void) setDelegateViews: (id <WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>) delegateView;

@end