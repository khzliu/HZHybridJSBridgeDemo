//
//  UIWebView+HZUIViewView.h
//  HZWebView
//
//  Created by 刘华舟 on 15/5/11.
//  Copyright (c) 2015年 云图. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HZWebViewProvider.h"

/*
 * This category extends UIWebView and conforms to the FLWebViewProvider protocol.
 */
@interface UIWebView (HZUIWebView) <HZWebViewProvider>

/*
 * Shorthand for setting UIWebViewDelegate to a class.
 */
- (void) setDelegateViews: (id <UIWebViewDelegate, UIScrollViewDelegate>) delegateView;

@end
