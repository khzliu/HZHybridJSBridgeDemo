//
//  YYXQHybridBaseController.h
//  app
//
//  Created by 刘华舟 on 15/11/30.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "YYXQBaseViewController.h"

//view
#import "HZHybridWebView.h"
#import "YYXQWebViewProcessView.h"


//tools
#import "YYXQJSOCBridgeManager.h"
#import "HZWebViewManager.h"


/** 
 
 AppWeb展示框架基类控制器
 
 
 -write by khzliu */



@interface YYXQHybridBaseController : YYXQBaseViewController<YYXQJSOCBridgeWebDelegate>


@property (weak, nonatomic) HZHybridWebView* hybridWebView;
@property (nonatomic, assign) BOOL loadSuccessed;
@property (nonatomic, assign) BOOL isFllowTitle;
@property (strong, nonatomic) YYXQWebViewProcessView* progressView;

@property (strong, nonatomic) YYXQJSOCBridgeManager *bridgeManager;


//加载本地内置的页面
- (void)showLocalPageWithFileName:(NSString *)name fileType:(NSString *)type;

@end
