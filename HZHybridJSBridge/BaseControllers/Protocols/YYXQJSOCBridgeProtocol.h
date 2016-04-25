//
//  YYXQJSOCBridgeProtocol.h
//  app
//
//  Created by 刘华舟 on 15/12/2.
//  Copyright © 2015年 hdaren. All rights reserved.
//

/** 
 
 
 -write by khzliu */

#ifndef YYXQJSOCBridgeProtocol_h
#define YYXQJSOCBridgeProtocol_h


#define _YYXQUIWebJavascriptBridgeJSName @"YuntuUIWebJavaScriptBridge.js"   //给UIWebView用的js
#define _YYXQWKWebJavascriptBridgeJSName @"YuntuWKWebJavaScriptBridge.js"   //给WKWebView用的js
#define VERSION(main,sub) @(main * 1000 + sub)
#define _YYXQWebJavascriptBridgeVersion VERSION(1,2)  //版本号

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

static const NSInteger kYYXQHyBridJSTypeActionMinIndex = 1000;
static const NSInteger kYYXQHyBridJSTypeActionMaxIndex = 10000;

//首先创建一个实现了JSExport协议的协议
@protocol YYXQJSOCBridgeProtocol <JSExport>


//@property (strong, nonatomic, readonly) NSDictionary* agent;
//版本号
- (NSDictionary *)agent;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data callback:(NSString *)cb;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data;

//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype;

//同步调用方法
-(NSString*)syncall:(NSNumber *)jstype data:(NSDictionary*)data extra:(NSDictionary*)extra;

//获取地理位置信息

//清理cookie

//设置cookie
@end

#endif /* YYXQJSOCBridgeProtocol_h */
