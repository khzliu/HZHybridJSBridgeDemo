//
//  HZHybridWebView.h
//  app
//
//  Created by 刘华舟 on 15/5/19.
//  Copyright (c) 2015年 hdaren. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFNetworking.h"

// Needed for WKNavigationDelegate and WKUIDelegate
#import <WebKit/WebKit.h>
// Used to define the webView property below
#import "HZWebViewProvider.h"

// Required for calls to UIWebView and WKWebView to "see" our categories
#import "UIWebView+HZUIWebView.h"
#import "WKWebView+HZWKWebView.h"

@class HZHybridWebView;

@protocol HZHybridWebViewDelegate <NSObject>

@required

//确定是否应该允许导航
- (BOOL)hybridWebView:(HZHybridWebView*)hybridWebView shouldStartDecidePolicy:(NSURLRequest *) request;

@optional

//开始加载
- (void)hybridWebViewDidStartNavigation:(HZHybridWebView*)hybridWebView;
//加载失败
- (void)hybridWebView:(HZHybridWebView*)hybridWebView failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error;
//完成加载
- (void)hybridWebView:(HZHybridWebView*)hybridWebView finishLoadOrNavigation: (NSURLRequest *) request;

//开始下载html文件
- (void)hybridWebView:(HZHybridWebView *)hybridWebView startDownloadHtml:(NSURLRequest *) request;
//完成下载html文件
- (void)hybridWebView:(HZHybridWebView *)hybridWebView didDownloadHtml:(NSURLRequest *) request html:(NSString *)html;

//下载html文件失败
- (void)hybridWebView:(HZHybridWebView *)hybridWebView failDownloadHtml:(NSURLRequest *)request response:(NSURLResponse *)resp withError: (NSError *) error;

//WKWebView 对 javascript 传递消息的代理
- (void)hybridUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

//WKWebView 对 javascript的alert的处理
- (void)hybridWebView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler;
//WKWebView 对 javascript的confirm的处理
- (void)hybridWebView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

//WKWebView 输入框
- (void)hybridWebView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler;



//划动滚轮
- (void)hybridScrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface HZHybridWebView : UIView

@property (nonatomic, assign) BOOL isWKWebView;

@property(nonatomic ,weak) id<HZHybridWebViewDelegate>delegate;

@property (weak, nonatomic) UIScrollView *scrollView;

// The main web view that is set up in the viewDidLoad method.
@property (nonatomic, strong) UIView <HZWebViewProvider> *webView;

//执行脚本
- (void) evaluateJavaScript:(NSString *)javaScriptString finishHandler: (void (^)(id data, NSError * error)) finishHandler;

//加载页面
- (void)loadRequest:(NSURLRequest *)request;

//加载网页
- (void)loadRequestFromString:(NSString *)urlNameAsString;

//加载网页用baseURL
- (void) loadHTMLString:(NSString *)urlString baseURL:(NSURL *)url;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and URL string.
 
 If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @param error The error that occured while constructing the request.
 
 @return An `NSMutableURLRequest` object.
 */
- (void)loadWithMethod:(NSString *)method
             URLString:(NSString *)URLString
            parameters:(id)parameters
                 error:(NSError *__autoreleasing *)error;


/**
 @deprecated This method has been deprecated. Use -multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:error: instead.
 */
- (void)multipartLoadWithMethod:(NSString *)method
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                           data:(NSData *)data;
/**
 下载一个html页面
 */

- (void)downloadHtmlMethod:(NSString *)method
             URLString:(NSString *)URLString
            parameters:(id)parameters
              completed:(void(^)(NSString* html,NSString* mainDocPath))completedHandler
                 error:(NSError *__autoreleasing *)error;

/**
 clear all webview's cache
 */
+ (void)clearAllCache;

/**
 clear all webview's cookies
 */
+ (void)clearAllCookies;

@end
