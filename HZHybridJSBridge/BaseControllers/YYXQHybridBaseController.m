
//
//  YYXQHybridBaseController.m
//  app
//
//  Created by 刘华舟 on 15/11/30.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "YYXQHybridBaseController.h"


//tools
#import "YYXQJSOCBridgeManager.h"



@interface YYXQHybridBaseController()<YYXQWebViewProgressDelegate,YYXQWKWebViewTitleDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *activity;


@end

@implementation YYXQHybridBaseController


- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.isFllowTitle = YES;
    
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.view.autoresizesSubviews = YES;
    self.navigationController.navigationBar.translucent = NO;
   
    self.loadSuccessed = NO;
   
    HZHybridWebView* webView = [[HZHybridWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    self.hybridWebView = webView;

    
    self.bridgeManager = [[YYXQJSOCBridgeManager alloc] initWithDelegate:self webView:self.hybridWebView];
    
    
    self.bridgeManager.progressDelegate = self;
    self.bridgeManager.titleDelegate = self;
    
    //进度条
    CGFloat progressBarHeight = 2.f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[YYXQWebViewProcessView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activity.center = self.hybridWebView.center;
    self.activity.hidesWhenStopped = YES;
    [self.view addSubview:self.activity];
    
    self.navigationController.navigationBar.hidden = NO;
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;

    [self.navigationController.navigationBar addSubview:self.progressView];
    [self.progressView setProgress:0.0 animated:NO];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.progressView removeFromSuperview];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _hybridWebView.delegate = nil;
    [_hybridWebView loadRequestFromString:@""];
    [_hybridWebView.webView stopLoading];
    [_hybridWebView removeFromSuperview];
    
    _hybridWebView = nil;
    
    //清理UIWebView，避免内存过大
    _bridgeManager = nil;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}


/*!
 @brief 分析参数 加载页面
 @param data NSDictionary
 @param nil
 */
- (void)analysisDataAndStartToLoadPage
{
    //去除设置
}

- (void)showLocalPageWithFileName:(NSString *)name fileType:(NSString *)type
{
    if(name && type){
        NSString *filePath = [[NSBundle mainBundle]pathForResource:name ofType:type];
        NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        if (filePath && htmlString) {
            [self.hybridWebView loadHTMLString:htmlString baseURL:[NSURL URLWithString:filePath]];
        }
    }
}



#pragma mark - YYXQJSOCBridgeWebDelegate
- (BOOL)bridgeWebView:(HZHybridWebView *)hybridWebView shouldStartLoadWithRequest:(NSURLRequest *)request
{
    
    //对从本地加载的数据无须拦截
    if ([request.URL.scheme caseInsensitiveCompare:@"file"] == NSOrderedSame || [request.URL.scheme caseInsensitiveCompare:@"yyxqapp"] == NSOrderedSame || [request.URL.scheme caseInsensitiveCompare:@"about"] == NSOrderedSame) {
        return YES;
    }

    
//    static BOOL isRequestWeb = YES;
//    if (isRequestWeb) {
//        
//        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        
//        __weak typeof(self) wself = self;
//        //  后台执行：
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            
//            NSHTTPURLResponse *response = nil;
//    
//            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
//            if (response.statusCode == 404) {
//                // code for 404
//                // 主线程执行：
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    // 加载本地数据
//                    [wself showLocalPageWithFileName:@"404" fileType:@"html"];
//                });
//            } else if (response.statusCode == 403) {
//                // code for 403
//                // 主线程执行：
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    // 加载本地数据
//                    [wself showLocalPageWithFileName:@"403" fileType:@"html"];
//                });
//            } else if(response.statusCode == 401){
//                // code for 401
//                // 主线程执行：
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    // 加载本地数据
//                    [wself showLocalPageWithFileName:@"401" fileType:@"html"];
//                });
//            }else{
//                if (data) {
//                    // 主线程执行：
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        // 加载本地数据
//                        [hybridWebView.webView loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[request URL]];
//                    });
//                }else{
//                    // 主线程执行：
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        // 加载本地数据
//                        [wself showLocalPageWithFileName:@"error" fileType:@"html"];
//                    });
//                }
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                // 加载本地数据
//                [MBProgressHUD hideAllHUDsForView:wself.view animated:YES];
//            });
//            
//        });
//        
//        isRequestWeb = NO;
//        return NO;
//    }
    
    return YES;
}

//开始加载
- (void)bridgeWebViewDidStartLoad:(HZHybridWebView *)hybridWebView
{
    //    /** 首次加载成功之后 对二次跳转进行小菊花旋转 -write by khzliu */
    //    if (self.loadSuccessed) {
    //        [self.activity startAnimating];
    //    }
}
//加载失败
- (void)bridgeWebView:(HZHybridWebView *)hybridWebView didFailLoadWithError:(NSError *)error{
    //[self.activity stopAnimating];
    //处理加载失败
    //[self showLocalPageWithFileName:@"error" fileType:@"html"];
}

//完成加载
- (void)bridgeWebViewDidFinishLoad:(HZHybridWebView *)hybridWebView
{
    self.loadSuccessed = YES;
    //[self.activity stopAnimating];
    /** 设置web的title -write by khzliu */
    __block NSString* title = nil;
    [hybridWebView.webView evaluateJavaScript:@"document.title" completionHandler:^(NSString* str, NSError *error) {
        title = str;
    }];
    
    if (title && title.length>0) {
        self.title = title;
    }
}

//开始下载html文件
- (void)brideWebView:(HZHybridWebView *)hybridWebView startDownloadHtml:(NSURLRequest *) request
{
    
    
}
//完成下载html文件
- (void)brideWebView:(HZHybridWebView *)hybridWebView didDownloadHtml:(NSURLRequest *) request html:(NSString *)html
{
    
}
//下载html文件失败
- (void)brideWebView:(HZHybridWebView *)hybridWebView failDownloadHtml:(NSURLRequest *)request response:(NSURLResponse *)resp withError: (NSError *) error
{
    
}

//WKWebView弹窗
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler
{
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}
//WKWebView confirm
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    //  js 里面的alert实现，如果不实现，网页的alert函数无效  ,
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}

//WKWebView 输入框
- (void)bridgeWebView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:webView.URL.host preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *input = ((UITextField *)alertController.textFields.firstObject).text;
        completionHandler(input);
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler(nil);
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - NJKWebViewProgressDelegate
-(void)webViewProgress:(YYXQJSOCBridgeManager *)webViewProgress updateProgress:(float)progress
{
    [self.progressView setProgress:progress animated:YES];
}

#pragma mark -
#pragma mark YYXQWKWebViewTitleDelegate

- (void)hybridWebView:(HZHybridWebView *)hybridWebView title:(NSString *)title
{
    if (self.isFllowTitle) {
        if (title.length > 0) {
            self.title = title;
        }
    }
}

- (void)bridgeScrollViewDidScroll:(UIScrollView *)scrollView
{
    
}


@end
