//
//  WKWebView+HZWKWebView.m
//  HZWebView
//
//  Created by 刘华舟 on 15/5/11.
//  Copyright (c) 2015年 云图. All rights reserved.
//

#import "WKWebView+HZWKWebView.h"
#import <objc/runtime.h>

@implementation WKWebView (HZWKWebView)

/*
 * Sets a given delegateView as the delegate for this web view.
 */
- (void) setDelegateViews: (id <WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>) delegateView
{
    [self setNavigationDelegate: delegateView];
    [self setUIDelegate: delegateView];
    [self.scrollView setDelegate:delegateView];
}


/*
 * Getter for the active request. UIWebView has this, but WKWebView does not, so we add it here.
 */
- (NSURLRequest *) request
{
    return objc_getAssociatedObject(self, @selector(request));//@selector = &
}

/*
 * Setter for the active request.
 */
- (void) setRequest: (NSURLRequest *) request
{
    objc_setAssociatedObject(self, @selector(request), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*
 * This is swizzled in place of loadRequest in the load method.
 * Just updates the request reference before requesting.
 */
- (void) altLoadRequest: (NSURLRequest *) request
{
    [self setRequest: request];
    
    // Since we swizzled with loadRequest, this will actually call the original loadRequest.
    [self altLoadRequest: request];
}

/*
 * Essentially creates a URL request from a string and then loads it.
 */
- (void) loadRequestFromString: (NSString *) urlNameAsString
{
    [self loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString: urlNameAsString]]];
}

/*
 * Convenience method to load a string from baseURL.
 */
- (void)loadWebString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    if (string == nil) {
        return;
    }
    [self loadHTMLString:string baseURL:baseURL];
}
/*
 * Convenience method to load a data from Local.
 */
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL
{
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        [self loadData:data MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:baseURL];
    }
    
    #endif
    
}

/*
 * This doesn't do anything, as there's no good analogue to scalesPagesToFit in WKWebView.
 */
- (void) setScalesPagesToFit: (BOOL) setPages
{
    return; // not supported in WKWebView
}

/*
 * This class method is called when the runtime is loading.
 * We override this method to replace (swizzle) the loadRequest method with altLoadRequest.
 * That way, every time another class calls loadRequest, it'll actually call altLoadRequest.
 */
+ (void) load
{
    
    static dispatch_once_t onceToken;
    
    // We want to make sure this is only done once!
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // Get the representation of the method names to swizzle.
        SEL originalSelector = @selector(loadRequest:);
        SEL swizzledSelector = @selector(altLoadRequest:);
        
        // Get references to the methods to swizzle.
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // Attempt to add the new method in place of the old method.
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        // If we succeeded, put the old method in place of the new method.
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            // Otherwise, just swap their implementations.
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


@end