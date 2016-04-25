//
//  WKCookieSyncManager.h
//  app
//
//  Created by 刘华舟 on 15/12/18.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WKCookieSyncManager : NSObject

@property (strong,nonatomic) WKProcessPool* processPool;

+ (WKCookieSyncManager *)shareManager;

- (void)shareCookiesForWKWebView;

@end
