//
//  YYXQBaseViewController.h
//  app
//
//  Created by 刘华舟 on 15/11/30.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YYXQBaseViewProvider.h"


/**
 
 有氧星球 基础 controller
 
 
 -write by khzliu */

@interface YYXQBaseViewController : UIViewController<YYXQBaseViewProvider>

@property (strong, nonatomic) id pageData;
@property (strong, nonatomic) id extraData;
@property (strong, nonatomic) YYXQJSOCActionCallback pageBlock;


//判断当前的viewcontroller 是否是目前最上层的controller
- (BOOL)rootVCIsCruentViewController;



@end
