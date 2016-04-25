//
//  HZWebViewManager.h
//  app
//
//  Created by 刘华舟 on 15/12/21.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZHybridWebView.h"

@interface HZWebViewManager : NSObject

@property (strong, nonatomic) HZHybridWebView* hybridWebView;


+ (HZWebViewManager *)shareManager;

- (void)stopAllLoading;

- (void)resetHybridWebView;


@end
