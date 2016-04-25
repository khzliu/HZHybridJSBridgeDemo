//
//  YYXQJSOCBridgeManager.h
//  app
//
//  Created by 刘华舟 on 15/12/2.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYXQJSOCBridgeProtocol.h"

#import "YYXQBaseViewController.h"
#import "HZHybridWebView.h"

#import <UIKit/UIKit.h>

@class YYXQJSOCBridgeManager;

#undef yyxq_weak
#if __has_feature(objc_arc_weak)
#define yyxq_weak weak
#else
#define yyxq_weak unsafe_unretained
#endif

extern const float YYXQInitialProgressValue;
extern const float YYXQInteractiveProgressValue;
extern const float YYXQFinalProgressValue;

typedef void (^YYXQWebViewProgressBlock)(float progress);

@protocol YYXQWebViewProgressDelegate <NSObject>

- (void)webViewProgress:(YYXQJSOCBridgeManager *)bridge updateProgress:(float)progress;

@end

@protocol YYXQWKWebViewTitleDelegate <NSObject>

- (void)hybridWebView:(HZHybridWebView *)hybridWebView title:(NSString *)title;

@end

@protocol YYXQJSOCBridgeWebDelegate <NSObject>
//导航
- (BOOL)bridgeWebView:(HZHybridWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request;

//开始加载
- (void)bridgeWebViewDidStartLoad:(HZHybridWebView *)webView;
//加载失败
- (void)bridgeWebView:(HZHybridWebView *)webView didFailLoadWithError:(NSError *)error;
//完成加载
- (void)bridgeWebViewDidFinishLoad:(HZHybridWebView *)webView;

//开始下载html文件
- (void)brideWebView:(HZHybridWebView *)hybridWebView startDownloadHtml:(NSURLRequest *) request;
//完成下载html文件
- (void)brideWebView:(HZHybridWebView *)hybridWebView didDownloadHtml:(NSURLRequest *) request html:(NSString *)html;
//下载html文件失败
- (void)brideWebView:(HZHybridWebView *)hybridWebView failDownloadHtml:(NSURLRequest *)request response:(NSURLResponse *)resp withError: (NSError *) error;

//WKWebView 对 javascript的alert的处理
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler;

//WKWebView 对 javascript的confirm的处理
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

//WKWebView 输入框
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler;

//划动滚轮
- (void)bridgeScrollViewDidScroll:(UIScrollView *)scrollView;

@end


@interface YYXQJSOCBridgeManager : NSObject<UIWebViewDelegate>


@property (nonatomic, yyxq_weak) id<YYXQWebViewProgressDelegate>progressDelegate;
@property (nonatomic, yyxq_weak) id<YYXQWKWebViewTitleDelegate>titleDelegate;

@property (nonatomic, copy) YYXQWebViewProgressBlock progressBlock;
@property (nonatomic, readonly) float progress; // 0.0..1.0

//重置进度条
- (void)reset;

//@property (weak, nonatomic) id<YYXQBaseViewProvider> bridgeDelegate;
@property (weak, nonatomic) id bridgeDelegate;
@property (weak, nonatomic) id<YYXQJSOCBridgeWebDelegate> webDelegate;


- (instancetype)initWithDelegate:(id)delegate webView:(HZHybridWebView *)webView;

@property (assign, nonatomic, getter=isBind) BOOL bind;
@property (assign, nonatomic, getter=isLog) BOOL log;


//@property (strong, nonatomic, readonly) NSDictionary* agent;
//版本号
- (NSDictionary *)agent;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data callback:(NSString *)cb;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype;

//获取WKWebView的YuntuUIWebViewJavascriptBridge.js.txt的String
+ (NSString *)javascriptFileStringForWKWebView;

//是否打开Javascript 的 log
- (void)enableLogging:(BOOL)log;


//调用javascript的函数
- (void)executeJavascript:(NSString *)jsCommand;


//调用javascript已经注册过的javascript函数
- (void)callJavascriptRegistedMethod:(NSString *)name params:(YYXQJSOCBridgeMessage *)msg completed:(YYXQJSOCActionCallback)block;

@end
