//
//  HZJSBlockAlertView.h
//  app
//
//  Created by 刘华舟 on 16/3/8.
//  Copyright © 2016年 hdaren. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HZJSBlockAlertViewDelegate <NSObject>

- (void)alertViewDismiss:(void(^)(NSDictionary *))respBlock clickIndex:(NSInteger)index;

@end

@interface HZJSBlockAlertView : UIAlertView

@property (strong, nonatomic) void(^respBlock)(NSDictionary *);
@property (weak, nonatomic) id<HZJSBlockAlertViewDelegate> jsDelegate;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message jsDelegate:(id)jsDelegate buttons:(NSArray *)buttons;

@end
