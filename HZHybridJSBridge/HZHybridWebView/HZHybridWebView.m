//
//  HZHybridWebView.m
//  app
//
//  Created by 刘华舟 on 15/5/19.
//  Copyright (c) 2015年 hdaren. All rights reserved.
//

#import "HZHybridWebView.h"
#import "JKTransparentPNG.h"
#import "WKCookieSyncManager.h"
#import "YYXQJSOCBridgeManager.h"

#import "NSMassKit.h"

#import "HZCachingURLProtocol.h"

#define kYYXQJSCSSDownloadBaseURL @"http://www.demo.com/app/"

#define kYYXQWebViewBaseURLDomain @"http://www.demo.com/"


@interface HZHybridWebView()<WKScriptMessageHandler,UIScrollViewDelegate>

@property (strong, nonatomic) AFHTTPRequestOperationManager* requestManager;
@property (strong, nonatomic) WKUserContentController* userCtnCrl;

@end

@implementation HZHybridWebView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        // Check if WKWebView is available
        // If it is present, create a WKWebView. If not, create a UIWebView.
        if (NSClassFromString(@"WKWebView")) {
            
            self.userCtnCrl = [[WKUserContentController alloc] init];
            [self.userCtnCrl addScriptMessageHandler:self name:@"YuntuBridge"];
            
            NSString* jsSrc = [YYXQJSOCBridgeManager javascriptFileStringForWKWebView];
            [self.userCtnCrl addUserScript:[[WKUserScript alloc] initWithSource:jsSrc injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
            
            //fix iOS8 WKWebView Ajax Request not share cookies
            [self updateWKWebViewCookiesForIOS8];
            

            
            WKWebViewConfiguration* wkWebConf = [[WKWebViewConfiguration alloc] init];
            
            [wkWebConf setApplicationNameForUserAgent:[HZCachingURLProtocol loadUserAgent:NO]];
            
            wkWebConf.userContentController = self.userCtnCrl;
            
            wkWebConf.processPool = [WKCookieSyncManager shareManager].processPool;
            
            WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:[self frame] configuration:wkWebConf];
            
            self.scrollView = wkWebView.scrollView;
            _webView = wkWebView;
            _isWKWebView = YES;
        } else {
            UIWebView *uiWebView = [[UIWebView alloc] initWithFrame:[self frame]];
            self.scrollView = uiWebView.scrollView;
            _webView = uiWebView;
            _isWKWebView = NO;
        }
        
        self.webView.autoresizesSubviews = YES;
        
        // Add the webView to the current view.
        [self addSubview: [self webView]];
        
        // Assign this view controller as the delegate view.
        // The delegate methods are below, and include methods for UIWebViewDelegate, WKNavigationDelegate, and WKUIDelegate
        [[self webView] setDelegateViews: self];
        
        // Ensure that everything will resize on device rotate.
        [[self webView] setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        self.requestManager = [AFHTTPRequestOperationManager manager];
        self.requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        }
    return self;
}

- (void)dealloc{
    
    [_webView setDelegateViews:nil];
    _webView = nil;
    
    [self removeObserverWKWebViewCookiesForIOS8];
}

- (AFHTTPRequestOperationManager*)requestManager
{
    if (_requestManager == nil) {
        _requestManager = [AFHTTPRequestOperationManager manager];
        _requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return _requestManager;
}

- (void)removeObserverWKWebViewCookiesForIOS8
{
    if (NSClassFromString(@"WKWebView")) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0f) {
            
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
        }
    }
}

- (void)updateWKWebViewCookiesForIOS8
{
    if (NSClassFromString(@"WKWebView")) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0f) {
 
            NSMutableString* str = [NSMutableString string];
            for (NSHTTPCookie * cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
                if ([cookie.domain isEqualToString:kYYXQWebViewBaseURLDomain]) {
                    [str appendString:[NSString stringWithFormat:@"document.cookie = '%@=%@';",cookie.name,cookie.value]];
                }
            }       
            [self evaluateJavaScript:str finishHandler:nil];
            
        }
    }
}

//执行脚本
- (void) evaluateJavaScript:(NSString *)javaScriptString finishHandler: (void (^)(id data, NSError * error)) finishHandler
{
    if(finishHandler){
        [self.webView evaluateJavaScript:javaScriptString completionHandler:^(id data, NSError *error) {
            finishHandler(data,error);
        }];
    }else{
        [self.webView evaluateJavaScript:javaScriptString completionHandler:nil];
    }
    
}

- (void)loadRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

- (void)loadWithMethod:(NSString *)method
             URLString:(NSString *)URLString
            parameters:(id)parameters
                 error:(NSError *__autoreleasing *)error
{
    if ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
        return;
    }
    
    //去掉URL中的空格
    URLString = [URLString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURLRequest* request = [self.requestManager.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    

    //开始下载html文件
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:startDownloadHtml:)])
    {
        [self.delegate hybridWebView:self startDownloadHtml:request];
    }
    __weak typeof(self) wself = self;
    AFHTTPRequestOperation * operation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
      {
          
          NSString* htmlString = [wself replaceLocalJSCSSToHtmlString:operation.responseString url:operation.request.URL.absoluteString];
          
          //html文件下载完成
          if(wself.delegate && [wself.delegate respondsToSelector:@selector(hybridWebView:didDownloadHtml:html:)])
          {
              [wself.delegate hybridWebView:wself didDownloadHtml:request html:htmlString];
          }
          
          NSString* mainDocumentPath = [wself fatchMainDocumentURLForRequestString:URLString];
         
//          NSString * string = @"(<br\\s*/>\\s*)+";
//           htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<br /><br />" withString:@"<br/>"];
//          NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:string options:NSRegularExpressionCaseInsensitive error:nil];
//          
//          htmlString = [regex stringByReplacingMatchesInString:htmlString options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, htmlString.length) withTemplate:@"<br/>"];
          
          [wself loadHTMLString:htmlString baseURL:[NSURL URLWithString:mainDocumentPath]];
              
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
          //html下载失败
          if(wself.delegate &&[wself.delegate respondsToSelector:@selector(hybridWebView:failDownloadHtml:response:withError:)]){
    
              [wself.delegate hybridWebView:wself failDownloadHtml:operation.request response:operation.response withError:error];
          }
      }];
    
    [self.requestManager.operationQueue addOperation:operation];
    
}

- (void)multipartLoadWithMethod:(NSString *)method
                      URLString:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                           data:(NSData *)data
{
    if ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
    }
    
    NSString* name = [NSMassKit objectFrom:parameters ofKey:@"name" nilValue:@"data"];
    NSString* file = [NSMassKit objectFrom:parameters ofKey:@"filename" nilValue:@"uploadFile"];
    NSString* type = [NSMassKit objectFrom:parameters ofKey:@"mimetype" nilValue:@"application/octet-stream"];
    
    //去掉URL中的空格
    URLString = [URLString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURLRequest* request = [self.requestManager.requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data
                                    name:name
                                fileName:file
                                mimeType:type];
    } error:nil];
    
    //开始下载html文件
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:startDownloadHtml:)])
    {
        [self.delegate hybridWebView:self startDownloadHtml:request];
    }
    
    __weak typeof(self) wself = self;
    AFHTTPRequestOperation * operation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
      {
          
          NSString* htmlString = [wself replaceLocalJSCSSToHtmlString:operation.responseString url:operation.request.URL.absoluteString];
          //html文件下载完成
          if(wself.delegate && [wself.delegate respondsToSelector:@selector(hybridWebView:didDownloadHtml:html:)])
          {
              [wself.delegate hybridWebView:wself didDownloadHtml:request html:htmlString];
          }
          
          NSString* mainDocumentPath = [wself fatchMainDocumentURLForRequestString:URLString];
          [wself loadHTMLString:htmlString baseURL:[NSURL URLWithString:mainDocumentPath]];
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          //html下载失败
          if(wself.delegate &&[wself.delegate respondsToSelector:@selector(hybridWebView:failDownloadHtml:response:withError:)]){
              [wself.delegate hybridWebView:wself failDownloadHtml:operation.request response:operation.response withError:error];
          }
      }];
    
    [self.requestManager.operationQueue addOperation:operation];
}

//下载一个html页面
- (void)downloadHtmlMethod:(NSString *)method
             URLString:(NSString *)URLString
            parameters:(id)parameters
             completed:(void(^)(NSString* html,NSString* mainDocPath))completedHandler
                 error:(NSError *__autoreleasing *)error
{
    if ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
        
        return;
    }
    
    //去掉URL中的空格
    URLString = [URLString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURLRequest* request = [self.requestManager.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    
    //开始下载html文件
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:startDownloadHtml:)])
    {
        [self.delegate hybridWebView:self startDownloadHtml:request];
    }
    __weak typeof(self) wself = self;
    AFHTTPRequestOperation * operation = [self.requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
      {
          
          NSString* htmlString = [wself replaceLocalJSCSSToHtmlString:operation.responseString url:operation.request.URL.absoluteString];
          
          //html文件下载完成
          if(wself.delegate && [wself.delegate respondsToSelector:@selector(hybridWebView:didDownloadHtml:html:)])
          {
              [wself.delegate hybridWebView:wself didDownloadHtml:request html:htmlString];
          }
          
          NSString* mainDocumentPath = [wself fatchMainDocumentURLForRequestString:URLString];
          
          if(completedHandler){
              completedHandler(htmlString,mainDocumentPath);
          }
          
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          
          //html下载失败
          if(wself.delegate &&[wself.delegate respondsToSelector:@selector(hybridWebView:failDownloadHtml:response:withError:)]){

              [wself.delegate hybridWebView:wself failDownloadHtml:operation.request response:operation.response withError:error];
          }
      }];
    
    [self.requestManager.operationQueue addOperation:operation];
}

//获取mainDocumentURL
- (NSString *)fatchMainDocumentURLForRequestString:(NSString *)reqStr
{
    NSURL * URL = [NSURL URLWithString:reqStr];
    NSString* resultStr = URL.relativeString;
    
    if ([resultStr hasSuffix:@"/"]) {
        return resultStr;
    }
    
    NSArray* array = [resultStr pathComponents];
    
    if (array.count >= 3) {
        NSString* str = [NSString stringWithFormat:@"%@//", [array firstObject]];

        for (NSInteger i = 1; i < array.count-1; i++) {
            str = [NSString stringWithFormat:@"%@%@/", str, [array valueAtIndex:(int)i]];
        }
        
        return str;
    }
    return [resultStr substringToIndex:resultStr.length-[resultStr lastPathComponent].length];
}

//替换html中本地的css与js文件
- (NSString *)replaceLocalJSCSSToHtmlString:(NSString *)htmlString url:(NSString *)url
{
    //替换加载本地的css文件 正则表达式<link\s+rel\s*=\s*[",']stylesheet[",']\s+type\s*=\s*[",']text/css[",']\s+href\s*=\s*[",']o2_m_css/([^",']+)[",']\s*>\s*</link>
    NSString* parternBase = kYYXQWebViewBaseURLDomain;
    NSString* parternBaseRegex = [parternBase stringByReplacingOccurrencesOfString:@"." withString:@"[.]"];
    NSString* cssRegex = [NSString stringWithFormat:@"<link\\s+rel\\s*=\\s*[\",']stylesheet[\",']\\s+type\\s*=\\s*[\",']text/css[\",']\\s+href\\s*=\\s*[\",']%@o2_m_css/([^\",']+)[\",']\\s*>\\s*</link>", parternBaseRegex];
    //替换加载本地的js文件 正则表达式<script\s+type\s*=\s*[",']text/javascript[",']\s+src\s*=\s*[",']o2_m_script/([^",']+)[",']\s*>\s*</script>
    NSString* jsRegex = [NSString stringWithFormat:@"<script\\s+type\\s*=\\s*[\",']text/javascript[\",']\\s+src\\s*=\\s*[\",']%@o2_m_script/([^\",']+)[\",']\\s*>\\s*</script>", parternBaseRegex];
    NSString* pattern = [NSString stringWithFormat:@"(%@)|(%@)", cssRegex, jsRegex];
    
//    NSString *cachesPath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject], kYYXQBaseConfigJSCSSDownloadDirName];
    
    NSArray* results = [self parseHtml:htmlString withRegex:pattern];
    NSMutableString* resultHtml = [NSMutableString string];
    
    static NSRegularExpression * transparentPNGRegex = nil;
    if (transparentPNGRegex == nil) {
        NSString* pattern = @"\\s+src\\s*=\\s*[',\"]\\s*http[s]?://[^/,',\"]+[/][^',\"]*_empty_(\\d+)x(\\d+)[.]png\\s*[',\"]";
        NSError *error = NULL;
        transparentPNGRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    }
    NSMutableDictionary* pngCache = [NSMutableDictionary dictionary];
    
    //在HTML的head最前端注入一个拦截地址
    BOOL injectForUIWebView = NO;
    
    for (NSObject* obj in results) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString* str = (NSString*)obj;
            if ([str length] > 20) {
                [self tryToLoadTransparentPNG:str result:resultHtml
                                        regex:transparentPNGRegex
                                        cache:pngCache];
                continue;
            }
            
            [resultHtml appendString:str];
            continue;
        }
        NSArray* arr = (NSArray*)obj;        
        
       //检查是否是UIWebView 并且未注入过
        if (NSClassFromString(@"WKWebView") == nil && !injectForUIWebView) {
            NSString* injectStr = @"\n<link rel=\"stylesheet\" type=\"text/css\" href=\"yyxqapp://xxx.yyy.zzz/inject.notifaciton\"></link>\n";
            [resultHtml appendString:injectStr];
            injectForUIWebView = YES;
        }
        
        
        if ([@"js" compare:[arr objectAtIndex:0]] == 0) {
            
            //这里是要替换的字符串
            NSData* data = [NSData dataWithContentsOfFile:@""];
            
            if (data == nil || data.length <= 0) {
                NSString* orgStr = [NSString stringWithFormat:@"<script type='text/javascript' src='%@o2_m_script/%@'></script>", kYYXQJSCSSDownloadBaseURL, [arr objectAtIndex:1]];
                [resultHtml appendString:orgStr];
                
                //保存错误日志
                NSString* logs = [NSString stringWithFormat:@"iOS WebView js resource replace error:\n\
                                  url:%@\n\
                                  match:%@\n", url, orgStr];
                [self saveWebViewErrorLog:logs];
            }else{
                NSString* fileString = [NSString stringWithFormat:@"<script>\n%@\n</script>",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                [resultHtml appendString:fileString];
            }
            continue;
        }
        
        if ([@"css" compare:[arr objectAtIndex:0]] == 0) {
            
            //这里是要替换的字符串
            NSData* data = [NSData dataWithContentsOfFile:@""];
            
            if (data == nil || data.length <= 0) {
                NSString* orgStr = [NSString stringWithFormat:@"<link rel='sytlesheet' type='text/css' href='%@o2_m_css/%@'></link>", kYYXQJSCSSDownloadBaseURL, [arr objectAtIndex:1]];
                
                [resultHtml appendString:orgStr];
                
                //保存错误日志
                NSString* logs = [NSString stringWithFormat:@"iOS WebView css resource replace error:\n\
                                  url:%@\n\
                                  match:%@\n", url, orgStr];
                [self saveWebViewErrorLog:logs];
            }else{
                NSString* fileString = [NSString stringWithFormat:@"<style>\n%@\n</style>",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                [resultHtml appendString:fileString];
            }
            continue;
        }
    }
    
    return resultHtml;
}

//替换本地html种的占位图 
- (void)tryToLoadTransparentPNG:(NSString*)html
                         result:(NSMutableString*)result
                          regex:(NSRegularExpression*)regex
                          cache:(NSMutableDictionary*)cache
{
    NSArray* matches = [regex matchesInString:html options:0
                                        range:NSMakeRange(0, [html length])];
    
    if(!matches){
        [result appendString:html];
        return;
    }
    
    NSInteger lp = 0;
    for (NSTextCheckingResult* cr in matches) {
        if(cr.range.location > lp){
            [result appendString:[html substringWithRange:NSMakeRange(lp, cr.range.location - lp)]];
        }
        NSString* w = [html substringWithRange:[cr rangeAtIndex:1]];
        NSString* h = [html substringWithRange:[cr rangeAtIndex:2]];
        
        NSString* key = [NSString stringWithFormat:@"%@x%@", w,h];
        NSString* png = [cache stringForKey:key nilValue:nil];
        if (!png) {
            png = [JKTransparentPNG Base64Text:CGSizeMake([w intValue], [h intValue])];
            [cache setObject:png forKey:key];
        }
        
        [result appendFormat:@" src=\"data:image/png;base64,%@\" ", png];
        
        lp = cr.range.location + cr.range.length;
    }
    if (lp < 1) {
        [result appendString:html];
        return;
    }
    if (lp < [html length]) {
        [result appendString:[html substringFromIndex:lp]];
    };
    
    
}

//匹配html中的js,css字符串以及引用的名称
- (NSArray*)parseHtml:(NSString*)html withRegex:(NSString*)pattern
{
    if (html == nil) {
        return [NSArray array];
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray* matches = [regex matchesInString:html options:0
                                        range:NSMakeRange(0, [html length])];
    NSMutableArray* result = [NSMutableArray array];
    
    if(matches){
        NSInteger lp = 0;
        for (NSTextCheckingResult* cr in matches) {
            if(cr.range.location > lp){
                [result addObject:[html substringWithRange:NSMakeRange(lp, cr.range.location - lp)]];
            }
            NSRange r = [cr rangeAtIndex:2];//css
            if (r.location != NSNotFound) {
                [result addObject:@[@"css",[html substringWithRange:r]]];
            }else{
                r = [cr rangeAtIndex:4];//js
                if (r.location != NSNotFound){
                    [result addObject:@[@"js",[html substringWithRange:r]]];
                }
            }
            lp = cr.range.location + cr.range.length;
        }
        if (lp < 1) {
            [result addObject:html];
            return result;
        }
        if (lp < [html length]) {
            [result addObject:[html substringFromIndex:lp]];
        };
    }
    
    return result;
}

//记录crash log数据
- (void)saveWebViewErrorLog:(NSString *)logs{
    
    
}

- (void)loadRequestFromString:(NSString *)urlNameAsString{
    // Just to show *something* on load, we go to our favorite site.
    [[self webView] loadRequestFromString:urlNameAsString];
}

//加载网页用baseURL
- (void) loadHTMLString:(NSString *)urlString baseURL:(NSURL *)url
{
    if (urlString == nil) {
        return;
    }
    [[self webView] loadWebString:urlString baseURL:url];
}

/*
 * Enable rotating the view when the device rotates.
 */
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation
{
    return YES;
}

/*
 * This more or less ensures that the status bar is hidden for this view.
 * We also set UIStatusBarHidden to true in the Info.plist file.
 * We hide the status bar so we can use the full screen height without worrying about an offset for the status bar.
 */
- (BOOL) prefersStatusBarHidden
{
    //return YES;
    return NO;
}

#pragma mark - UIWebView Delegate Methods

/*
 * Called on iOS devices that do not have WKWebView when the UIWebView requests to start loading a URL request.
 * Note that it just calls shouldStartDecidePolicy, which is a shared delegate method.
 * Returning YES here would allow the request to complete, returning NO would stop it.
 */
- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType
{
    return [self shouldStartDecidePolicy: request];
}

/*
 * Called on iOS devices that do not have WKWebView when the UIWebView starts loading a URL request.
 * Note that it just calls didStartNavigation, which is a shared delegate method.
 */
- (void) webViewDidStartLoad: (UIWebView *) webView
{
    [self didStartNavigation];
}

/*
 * Called on iOS devices that do not have WKWebView when a URL request load failed.
 * Note that it just calls failLoadOrNavigation, which is a shared delegate method.
 */
- (void) webView: (UIWebView *) webView didFailLoadWithError: (NSError *) error
{
    [self failLoadOrNavigation: [webView request] withError: error];
}

/*
 * Called on iOS devices that do not have WKWebView when the UIWebView finishes loading a URL request.
 * Note that it just calls finishLoadOrNavigation, which is a shared delegate method.
 */
- (void) webViewDidFinishLoad: (UIWebView *) webView
{
    [self finishLoadOrNavigation: [webView request]];
}

#pragma mark - WKWebView Delegate Methods

/*
 * Called on iOS devices that have WKWebView when the web view wants to start navigation.
 * Note that it calls shouldStartDecidePolicy, which is a shared delegate method,
 * but it's essentially passing the result of that method into decisionHandler, which is a block.
 */
- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
{
    decisionHandler([self shouldStartDecidePolicy: [navigationAction request]]);
}

/*
 * Called on iOS devices that have WKWebView when the web view starts loading a URL request.
 * Note that it just calls didStartNavigation, which is a shared delegate method.
 */
- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (WKNavigation *) navigation
{
    [self didStartNavigation];
}

/*
 * Called on iOS devices that have WKWebView when the web view fails to load a URL request.
 * Note that it just calls failLoadOrNavigation, which is a shared delegate method,
 * but it has to retrieve the active request from the web view as WKNavigation doesn't contain a reference to it.
 */
- (void) webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self failLoadOrNavigation: [webView request] withError: error];
}

/*
 * Called on iOS devices that have WKWebView when the web view begins loading a URL request.
 * This could call some sort of shared delegate method, but is unused currently.
 */
- (void) webView: (WKWebView *) webView didCommitNavigation: (WKNavigation *) navigation
{
    
}

/*
 * Called on iOS devices that have WKWebView when the web view fails to load a URL request.
 * Note that it just calls failLoadOrNavigation, which is a shared delegate method.
 */
- (void) webView: (WKWebView *) webView didFailNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self failLoadOrNavigation: [webView request] withError: error];
}

/*
 * Called on iOS devices that have WKWebView when the web view finishes loading a URL request.
 * Note that it just calls finishLoadOrNavigation, which is a shared delegate method.
 */
- (void) webView: (WKWebView *) webView didFinishNavigation: (WKNavigation *) navigation
{
    [self finishLoadOrNavigation: [webView request]];
}



#pragma mark - Shared Delegate Methods

/*
 * This is called whenever the web view wants to navigate.
 */
- (BOOL) shouldStartDecidePolicy: (NSURLRequest *) request
{
    // Determine whether or not navigation should be allowed.
    // Return YES if it should, NO if not.
    
    BOOL ret = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:shouldStartDecidePolicy:)]) {
        ret = [self.delegate hybridWebView:self shouldStartDecidePolicy:request];
    }
    
    return ret;
}

/*
 * This is called whenever the web view has started navigating.
 */
- (void) didStartNavigation
{
    // Update things like loading indicators here.
    if (self.delegate && [self.delegate respondsToSelector:@selector(hybridWebViewDidStartNavigation:)]) {
        [self.delegate hybridWebViewDidStartNavigation:self];
    }
}

/*
 * This is called when navigation failed.
 */
- (void) failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error
{
    // Notify the user that navigation failed, provide information on the error, and so on.
    if (self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:failLoadOrNavigation:withError:)]) {
        [self.delegate hybridWebView:self failLoadOrNavigation:request withError:error];
    }
}

/*
 * This is called when navigation succeeds and is complete.
 */
- (void) finishLoadOrNavigation: (NSURLRequest *) request
{
    // Remove the loading indicator, maybe update the navigation bar's title if you have one.
    if (self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:finishLoadOrNavigation:)]) {
        [self.delegate hybridWebView:self finishLoadOrNavigation:request];
    }
}

/*
 * This is called when javascript call native code.
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (self.isWKWebView && self.delegate && [self.delegate respondsToSelector:@selector(hybridUserContentController:didReceiveScriptMessage:)]) {
        [self.delegate hybridUserContentController:userContentController didReceiveScriptMessage:message];
    }
}

/*
 * This is called when javascript call alert.
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler
{
    NSLog(@"message:%@",message);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]){
        [self.delegate hybridWebView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler();
    }
}

/*
 * This is called when javascript call confirm.
 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    NSLog(@"message:%@",message);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]){
        [self.delegate hybridWebView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler(NO);
    }
}

//WKWebView 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(hybridWebView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]){
        [self.delegate hybridWebView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler(defaultText);
    }
}

+ (void)clearAllCache
{
    if (NSClassFromString(@"WKWebView")) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
            NSSet *websiteDataTypes
            = [NSSet setWithArray:@[
                                    WKWebsiteDataTypeDiskCache,
                                    WKWebsiteDataTypeOfflineWebApplicationCache,
                                    //WKWebsiteDataTypeMemoryCache,
                                    WKWebsiteDataTypeLocalStorage,
                                    //WKWebsiteDataTypeCookies,
                                    WKWebsiteDataTypeSessionStorage,
                                    WKWebsiteDataTypeIndexedDBDatabases,
                                    WKWebsiteDataTypeWebSQLDatabases
                                    ]];
            //// All kinds of data
            //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
            //// Date from
            NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
            //// Execute
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
                // Done
            }];
        }else{
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cache/WebKit"];
            NSError *errors;
            [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        }
    }else{
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
}


+ (void)clearAllCookies
{
    if (NSClassFromString(@"WKWebView")) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
            NSSet *websiteDataTypes
            = [NSSet setWithArray:@[
                                    //WKWebsiteDataTypeDiskCache,
                                    //WKWebsiteDataTypeOfflineWebApplicationCache,
                                    //WKWebsiteDataTypeMemoryCache,
                                    //WKWebsiteDataTypeLocalStorage,
                                    WKWebsiteDataTypeCookies,
                                    //WKWebsiteDataTypeSessionStorage,
                                    //WKWebsiteDataTypeIndexedDBDatabases,
                                    //WKWebsiteDataTypeWebSQLDatabases
                                    ]];
            //// All kinds of data
            //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
            //// Date from
            NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
            //// Execute
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
                // Done
            }];
        }else{
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
            NSError *errors;
            [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        }
    }
    
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(hybridScrollViewDidScroll:)]) {
        [self.delegate hybridScrollViewDidScroll:self.scrollView];
    }
}




@end
