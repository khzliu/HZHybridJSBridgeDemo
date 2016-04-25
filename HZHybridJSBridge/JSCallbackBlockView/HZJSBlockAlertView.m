//
//  HZJSBlockAlertView.m
//  app
//
//  Created by 刘华舟 on 16/3/8.
//  Copyright © 2016年 hdaren. All rights reserved.
//

#import "HZJSBlockAlertView.h"

@interface HZJSBlockAlertView()<UIAlertViewDelegate>

@end

@implementation HZJSBlockAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message jsDelegate:(id)jsDelegate buttons:(NSArray *)buttons
{
    
    if (!buttons) {
        return nil;
    }
    
    if (buttons.count <= 1) {
        NSString* btnStr = @"确定";
        if ([buttons firstObject] && [[buttons firstObject] isKindOfClass:[NSString class]]) {
            btnStr = [buttons firstObject];
        }
        if (self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:btnStr, nil]) {
            self.jsDelegate = jsDelegate;
        }
    }else if(buttons.count == 2){
        NSString* cancelStr = @"取消";
        NSString* confirmStr = @"确定";
        if ([buttons firstObject] && [[buttons firstObject] isKindOfClass:[NSString class]]) {
            cancelStr = [buttons firstObject];
        }
        if ([buttons objectAtIndex:1] && [[buttons objectAtIndex:1] isKindOfClass:[NSString class]]) {
            confirmStr = [buttons objectAtIndex:1];
        }
        if (self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:cancelStr, confirmStr, nil]) {
            self.jsDelegate = jsDelegate;
        }
    }else if(buttons.count >= 3){
        NSString* leftStr = @"左";
        NSString* centerStr = @"中";
        NSString* rightStr = @"右";
        if ([buttons firstObject] && [[buttons firstObject] isKindOfClass:[NSString class]]) {
            leftStr = [buttons firstObject];
        }
        if ([buttons objectAtIndex:1] && [[buttons objectAtIndex:1] isKindOfClass:[NSString class]]) {
            centerStr = [buttons objectAtIndex:1];
        }
        if ([buttons objectAtIndex:2] && [[buttons objectAtIndex:2] isKindOfClass:[NSString class]]) {
            rightStr = [buttons objectAtIndex:2];
        }
        if (self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:leftStr, centerStr, rightStr, nil]) {
            self.jsDelegate = jsDelegate;
        }
        
    }
    
    return self;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (self.jsDelegate && [self.jsDelegate respondsToSelector:@selector(alertViewDismiss:clickIndex:)]) {
        [self.jsDelegate alertViewDismiss:self.respBlock clickIndex:buttonIndex];
    }
}



@end
