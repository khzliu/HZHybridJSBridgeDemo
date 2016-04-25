//
//  YYXQWebViewProcessView.h
//  app
//
//  Created by 刘华舟 on 15/12/7.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYXQWebViewProcessView : UIView

@property (nonatomic) float progress;

@property (nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration; // default 0.1
@property (nonatomic) NSTimeInterval fadeAnimationDuration; // default 0.27
@property (nonatomic) NSTimeInterval fadeOutDelay; // default 0.1

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end
