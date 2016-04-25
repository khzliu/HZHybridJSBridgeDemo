//
//  ViewController.m
//  HZHybridJSBridgeDemo
//
//  Created by 刘华舟 on 16/4/25.
//  Copyright © 2016年 khzliu. All rights reserved.
//

#import "ViewController.h"
#import "NSMassKit.h"
#import "JKTransparentPNG.h"
#import "JSONKit.h"
#import "HZJSBlockAlertView.h"
@interface ViewController ()<HZJSBlockAlertViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self analysisDataAndStartToLoadPage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


/*!
 @brief 分析参数 加载页面
 @param data NSDictionary
 @param nil
 */
- (void)analysisDataAndStartToLoadPage
{
    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"test_os_js_bridge" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.hybridWebView loadHTMLString:htmlString baseURL:[NSURL URLWithString:filePath]];
    return;
    
}

#pragma mark -
#pragma mark JSBridgeSyncMehtod

//获取图片字符串
- (NSString*)yyxqJSCallSyncTransparentPNG:(NSDictionary *)data extra:(NSDictionary *)extra
{
    if (data && [data isKindOfClass:[NSDictionary class]] && data.count > 1) {
        CGFloat width = [[data numberForKey:@"width" nilValue:@(1)] floatValue];
        CGFloat height = [[data numberForKey:@"height" nilValue:@(1)] floatValue];
        NSString* str = [JKTransparentPNG Base64Text:CGSizeMake(width, height)];
        if (str == nil) {
            str = @"";
        }
        NSDictionary* ret = @{@"ret":@0,
                              @"msg":@"success",
                              @"result":@{
                                      @"str":str
                                      }};
        return [ret JSONString];
    }else{
        return @"{ret:1,msg:'miss params'}";
    }
    
}

/*!
 @brief 显示对话框
 @param id data
 @param nil
 */
- (void)yyxqJSCallShowAlert:(YYXQJSOCBridgeMessage *)dict extra:(YYXQJSOCBridgeMessage *)extra completed:(YYXQJSOCActionCallback)block
{
    
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        NSString* title = [dict stringForKey:@"title" nilValue:@""];
        NSString* message = [dict stringForKey:@"message" nilValue:@""];
        NSArray* buttons = [dict arrayForKey:@"buttons"];
        HZJSBlockAlertView* alertView = [[HZJSBlockAlertView alloc] initWithTitle:title message:message jsDelegate:self buttons:buttons];
        if (alertView) {
            alertView.respBlock = block;
            [alertView show];
        }else{
            if (block) {
                NSDictionary* ret = @{@"ret":@1,
                                      @"msg":@"buttons array is empty"};
                block(ret);
            }
        }
    }else{
        if (block) {
            NSDictionary* ret = @{@"ret":@1,
                                  @"msg":@"no params"};
            block(ret);
        }
    }
    
}

#pragma mark HZJSBlockAlertViewDelegate
- (void)alertViewDismiss:(void (^)(NSDictionary *))respBlock clickIndex:(NSInteger)index
{
    if (respBlock) {
        NSDictionary* ret = @{@"ret":@0,
                              @"msg":@"success",
                              @"result":@{
                                      @"index":[NSNumber numberWithInteger:index]
                                      }};
        respBlock(ret);
    }
}
@end
