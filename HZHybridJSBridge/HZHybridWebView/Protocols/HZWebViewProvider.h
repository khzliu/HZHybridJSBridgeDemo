//
//  HZWebViewProvider.h
//  HZWebView
//
//  Created by 刘华舟 on 15/5/11.
//  Copyright (c) 2015年 云图. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * This class defines methods that HZUIWebView and HZWKWebView should implement in
 * order to work within our ViewController.
 */
@protocol HZWebViewProvider <NSObject>


/*
 * Return the active NSURLRequest of this webview.
 * The methodology is a bit different between UIWebView and WKWebView.
 * Defining it here one way helps to ensure we'll implement it in the same way in our categories.
 */
@property (nonatomic, strong) NSURLRequest *request;

/*
 * Returns the active NSURL. Again, this is a bit different between the two web views.
 */
@property (nonatomic, strong) NSURL *URL;

/*
 * Assign a delegate view for this webview.
 */
- (void) setDelegateViews: (id) delegateView;

/*
 * Load an NSURLRequest in the active webview.
 */
- (void) loadRequest: (NSURLRequest *) request;

/*
 * Convenience method to load a request from a string.
 */
- (void) loadRequestFromString: (NSString *) urlNameAsString;


/*
 * Convenience method to load a string with baseURL.
 */
- (void)loadWebString:(NSString *)string baseURL:(nullable NSURL *)baseURL;

/*
 * Returns true if it is possible to go back, false otherwise.
 */
- (BOOL) canGoBack;

/*
 * Returns true if it is possible to go forward, false otherwise.
 */
- (BOOL) canGoForward;

/*
 * Reload an NSURLRequest in the active webview.
 */
- (void)reload;

/*
 * Stop Loading an NSURLRequest in the active webview.
 */
- (void)stopLoading;

/*
 * Go Back in the active webview.
 */
- (void)goBack;

/*
 * Go Forward in the active webview.
 */
- (void)goForward;

/*
 * UIWebView has stringByEvaluatingJavaScriptFromString, which is synchronous.
 * WKWebView has evaluateJavaScript, which is asynchronous.
 * Since it's far easier to implement the latter in UIWebView, we define it here and do that.
 */
- (void) evaluateJavaScript:(NSString *)javaScriptString completionHandler: (void (^)(id data, NSError * error)) completionHandler;


@end
