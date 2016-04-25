//
//  YYXQBaseViewProvider.h
//  app
//
//  Created by 刘华舟 on 15/11/30.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef  NSDictionary YYXQJSOCBridgeMessage;
typedef void(^YYXQJSOCActionCallback)(NSDictionary *);

#define YYXQJSOCBridgeMessageJSType  @"js_type"
#define YYXQJSOCBridgeMessageData  @"resp_data"


@protocol YYXQBaseViewProvider<NSObject>


@optional

/*!
 @brief 分析参数 加载页面
 @param data NSDictionary
 @param nil
 */
- (void)analysisDataAndStartToLoadPage;


/** 同步方法 -write by khzliu */

//获取图片字符串
- (NSString*)yyxqJSCallSyncTransparentPNG:(NSDictionary *)data extra:(NSDictionary *)extra;

/** 异步方法 -write by khzliu */
/*!
 @brief 调起订单快递信息页面
 @param id data
 @param nil
 */
-(void)yyxqJSCallShowMessage:(YYXQJSOCBridgeMessage *)data extra:(YYXQJSOCBridgeMessage *)extra completed:(YYXQJSOCActionCallback)block;




@end
