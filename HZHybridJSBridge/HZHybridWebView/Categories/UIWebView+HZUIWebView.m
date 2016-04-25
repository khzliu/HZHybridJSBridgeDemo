//
//  UIWebView+HZUIViewView.m
//  HZWebView
//
//  Created by 刘华舟 on 15/5/11.
//  Copyright (c) 2015年 云图. All rights reserved.
//

#import "UIWebView+HZUIWebView.h"

@implementation UIWebView (HZUIWebView)

@dynamic URL;

/*
 * Set any delegate view that implements UIWebViewDelegate.
 * HZWKWebView has a comparable method that looks for its own delegates.
 * Since this method is defined in HZWebViewProvider, we can call it in our view controller
 * no matter which web view was used.
 */
- (void) setDelegateViews: (id <UIWebViewDelegate, UIScrollViewDelegate>) delegateView
{
    [self setDelegate: delegateView];
    [self.scrollView setDelegate:delegateView];
}

/*
 * Same implementation as HZWKWebView.
 */
- (void) loadRequestFromString: (NSString *) urlNameAsString
{
    [self loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString: urlNameAsString]]];
}


/*
 * Convenience method to load a string with baseURL.
 */
- (void)loadWebString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    [self loadHTMLString:string baseURL:baseURL];
}

/*
 * The current URL is stored within the request property.
 * WKWebView has this available as a property, so we add it to UIWebView here.
 */
- (NSURL *) URL
{
    return [[self request] URL];
}

/*
 * Simple way to implement WKWebView's JavaScript handling in UIWebView.
 * Just evaluates the JavaScript and passes the result to completionHandler, if it exists.
 * Since this is defined in HZWebViewProvider, we can call this method regardless of the web view used.
 */
- (void) evaluateJavaScript: (NSString *) javaScriptString completionHandler: (void (^)(id, NSError *)) completionHandler
{
    NSString *string = [self stringByEvaluatingJavaScriptFromString: javaScriptString];
    
    if (completionHandler) {
        completionHandler(string, nil);
    }
}

/*
 * WKWebView has nothing comparable to scalesPagesToFit, so we use this method instead.
 * Here, we just update scalesPagesToFit. In HZWKWebView, nothing happens.
 */
- (void) setScalesPageToFit: (BOOL) setPages
{
    self.scalesPageToFit = setPages;
}

@end
