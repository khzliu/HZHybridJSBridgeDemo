//
//  YYXQBaseViewController.m
//  app
//
//  Created by 刘华舟 on 15/11/30.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "YYXQBaseViewController.h"

@interface YYXQBaseViewController ()
@end

@implementation YYXQBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
}



- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (BOOL)rootVCIsCruentViewController
{
    UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *rootVC = appRootVC;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    if (!rootVC) {
        return NO;
    }
    
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabVC = (UITabBarController *)rootVC;
        UIViewController *seletedVC = tabVC.selectedViewController;
        
        if (!seletedVC) {
            return NO;
        }
        
        if ([seletedVC isKindOfClass:[UINavigationController class]]) {
            UINavigationController* naviVC = (UINavigationController *)seletedVC;
            UIViewController* topVC = [naviVC topViewController];
            
            if ([self isEqual:topVC] || [topVC.childViewControllers containsObject:self]) {
                return YES;
            }
        }else{
            if ([self isEqual:seletedVC] || [seletedVC.childViewControllers containsObject:self]) {
                return YES;
            }
        }
        
    }else{
        if ([self isEqual:rootVC] || [rootVC.childViewControllers containsObject:self]) {
            return YES;
        }
    }
    
    
    return NO;
}



@end
