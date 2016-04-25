//
//  YYXQJSOCBridge.h
//  app
//
//  Created by 刘华舟 on 16/2/24.
//  Copyright © 2016年 hdaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYXQJSOCBridgeProtocol.h"

@interface YYXQJSOCBridge : NSObject<YYXQJSOCBridgeProtocol>

@property (weak, nonatomic) id delegate;

@end
