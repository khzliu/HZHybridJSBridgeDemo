//
//  YYXQJSOCBridgeManager.m
//  app
//
//  Created by 刘华舟 on 15/12/2.
//  Copyright © 2015年 hdaren. All rights reserved.
//

#import "YYXQJSOCBridgeManager.h"

#import "HZCachingURLProtocol.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UIDevice.h>

#import "YYXQJSOCBridge.h"

#import "NSMassKit.h"
#import "JSONKit.h"


#define YuntuBridgeErrorCatchMethodName @"bridgeErrorCatch"

#define YuntuBridgeAsyncMethodSelectorMap @"JSCallerAsyncMap"
#define YuntuBridgeSyncMethodSelectorMap @"JSCallerSyncMap"

const float YYXQInitialProgressValue = 0.1f;
const float YYXQInteractiveProgressValue = 0.5f;
const float YYXQFinalProgressValue = 0.9f;

NSString *completeRPCURLPath = @"/yyxqwebviewprogressproxy/complete";

@interface YYXQJSOCBridgeManager()<HZHybridWebViewDelegate>

@property (strong, nonatomic) JSContext *jsContext;
@property (assign, nonatomic) BOOL contextUsed; //标记是否用来javascriptCore.framework


@property (weak, nonatomic) HZHybridWebView* hybridWebView;

@property (strong, nonatomic) NSMutableDictionary* respCallbacks;

@end

@implementation YYXQJSOCBridgeManager
{
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (id)init
{
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress
{
    if (_progress < YYXQInitialProgressValue) {
        [self setProgress:YYXQInitialProgressValue];
    }
}

- (void)incrementProgress
{
    float progress = self.progress;
    float maxProgress = _interactive ? YYXQFinalProgressValue : YYXQInteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress
{
    [self setProgress:1.0];
}

- (void)setProgress:(float)progress
{
    // progress should be incremental only
    if (progress > _progress || progress == 0) {
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset
{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}


- (instancetype)initWithDelegate:(id)delegate  webView:(HZHybridWebView *)webView
{
    if (self = [super init]) {
        self.bridgeDelegate = delegate;
        self.webDelegate = delegate;
        webView.delegate = self;
        self.hybridWebView = webView;
        if (self.hybridWebView.isWKWebView) {
            [self.hybridWebView.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
            [self.hybridWebView.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        }
        self.respCallbacks = [NSMutableDictionary dictionary];
        self.bind = NO;
        self.log = NO;
        self.contextUsed = NO;
        [self reset];
    }
    return self;
}

- (JSContext *)jsContext
{
    if (_jsContext == nil) {
        _jsContext = [[JSContext alloc] init];
    }
    return _jsContext;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self.hybridWebView.webView) {
            
            if (self.hybridWebView.isWKWebView) {
                WKWebView* wkWebView = (WKWebView *)object;
                
                if (wkWebView.estimatedProgress <= YYXQInitialProgressValue) {
                    [self startProgress];
                }else if (wkWebView.estimatedProgress > YYXQInitialProgressValue && wkWebView.estimatedProgress < YYXQFinalProgressValue) {
                    [self setProgress:wkWebView.estimatedProgress];
                }else{
                    [self completeProgress];
                }
            }
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
        
    }else if ([keyPath isEqualToString:@"title"]){
        if (object == self.hybridWebView.webView){
            if (self.hybridWebView.isWKWebView) {
                
                WKWebView* wkWebView = (WKWebView *)object;
                
                if (self.titleDelegate && [self.titleDelegate respondsToSelector:@selector(hybridWebView:title:)]) {
                    [self.titleDelegate hybridWebView:object title:wkWebView.title];
                }
            }
        }else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
        
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)bindBridgeToJSContextWithWebView:(HZHybridWebView *)hybridWebView
{
    if (!hybridWebView) { return NO;}
    
    if (!hybridWebView.isWKWebView) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(injectBridgeObjectToJSForUIWebView) name:kNotificationHTMLURLIntercept object:nil];
        
    }else{
        /** 打开javascript的debug模式 -write by khzliu */
        self.log = YES;
        
        self.bind = YES;
    }
    
    
    return YES;
    
    /*-----------------------------例子-----------------------------
     //同样我们也用刚才的方式模拟一下js调用方法
     [context evaluateScript:@"person=new Object();\
     person.firstname='Bill';\
     person.lastname='Gates';\
     person.age=56;\
     person.eyecolor='blue';"];
     
     
     NSString *jsStr1=@"NativeWebBridgeObject.callData(112, person)";
     [context evaluateScript:jsStr1];
     
     -----------------------------例子-----------------------------*/
}

//植入YuntuBridge for UIViewView；
- (void)injectBridgeObjectToJSForUIWebView
{
    /** 加载成功之后 把javascript 对象 注入 -write by khzliu */
    //首先创建JSContext 对象（此处通过当前webView的键获取到jscontext）
    self.jsContext = [self.hybridWebView.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    //第二，js是通过对象调用的，我们假设js里面有一个对象 NativeWebBridgeObject 在调用方法
    // NativeWebBridgeObject 提供一个query(number jstype, object data )方法，参数为
    //首先创建我们新建类的对象，将他赋值给js的对象
    __weak typeof(self) wself = self;
    YYXQJSOCBridge* bridge = [[YYXQJSOCBridge alloc] init];
    bridge.delegate = wself;
    self.jsContext[@"YuntuBridge"] = bridge;
    
    _contextUsed = YES;
    
    //注入JS 文件
    [self injectJavascriptFile:YES hybirdWebView:self.hybridWebView];
    
    /** 打开javascript的debug模式 -write by khzliu */
    self.log = YES;
    
    self.bind = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//获取WKWebView的YuntuUIWebViewJavascriptBridge.js.txt的String
+ (NSString *)javascriptFileStringForWKWebView
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *filePath = [bundle pathForResource:_YYXQWKWebJavascriptBridgeJSName ofType:@"txt"];
    NSString *js = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

    NSString* jsCommand = [NSString stringWithFormat:@";(function(AGENT) {\n%@\n})(%@);",js , [[self class] _serializeMessage:[[self class] wkAgent]]];
    
    return jsCommand;
}

//注入本地的YuntuUIWebViewJavascriptBridge.js.txt文件
- (void)injectJavascriptFile:(BOOL)shouldInject hybirdWebView:(HZHybridWebView *)hybridWebView {
    if(shouldInject){
        NSBundle *bundle = [NSBundle mainBundle];

        NSString *filePath = [bundle pathForResource:_YYXQUIWebJavascriptBridgeJSName ofType:@"txt"];
        NSString *js = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [self.jsContext evaluateScript:js];
    }
}

//打开网页的javascript的alert弹窗
- (void)enableLogging:(BOOL)log
{
    self.log = log;
}

- (void)dealloc {
    
    if (_hybridWebView.isWKWebView) {
        [_hybridWebView.webView removeObserver:self forKeyPath:@"estimatedProgress"];
        [_hybridWebView.webView removeObserver:self forKeyPath:@"title"];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _progressDelegate = nil;
    _progressBlock = nil;
    _bridgeDelegate = nil;
    _webDelegate = nil;
    _jsContext = nil;
    _respCallbacks = nil;
    _currentURL = nil;
}

+ (NSDictionary *)wkAgent
{
    return @{@"version":_YYXQWebJavascriptBridgeVersion,
             @"app_version":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
             @"os":@[[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]],
             @"device":@{@"type":[[UIDevice currentDevice] model],
                         @"height":[NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.height],
                         @"width":[NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.width]}
             };
}


//获取版本号
- (NSDictionary *)agent
{
    return @{@"version":_YYXQWebJavascriptBridgeVersion,
             @"app_version":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
             @"os":@[[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]],
             @"device":@{@"type":[[UIDevice currentDevice] model],
                         @"height":[NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.height],
                         @"width":[NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.width]}
             };
    
}
//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype
{
    [self call:jstype data:nil];
}


//JSOCBridge 入口函数
- (void)call:(NSNumber *)jstype data:(NSDictionary *)data
{
    [self call:jstype data:data callback:nil];
}


- (void)call:(NSNumber *)jstype data:(NSDictionary *)data callback:(NSString *)cb
{
    
    if (cb && cb.length > 0 && ![cb isEqualToString:@"undefined"]) {
        [self.respCallbacks setObject:cb forKey:[jstype stringValue]];
    }
    
    if([jstype integerValue] >= kYYXQHyBridJSTypeActionMinIndex && [jstype integerValue] < kYYXQHyBridJSTypeActionMaxIndex){
        //获取函数
        SEL seleter = [self analysisDataFetchAsyncSelector:[jstype stringValue]];
        if (!seleter) {
            //错误处理
            [self errLogWorningJSType:jstype data:data callback:cb];
            return;
        }
        
        BOOL hasHandler = [self.bridgeDelegate respondsToSelector:seleter];
        if (self.bridgeDelegate && hasHandler) {
            
            
            YYXQJSOCBridgeMessage * dict = [data dictForKey:@"data"];
            
            YYXQJSOCBridgeMessage * extra = [data dictForKey:@"extra"];
            
            /** 启用主线程来更新UI操作 to fix "“This application is modifying the autolayout engine” error" -write by khzliu */
            __weak typeof(self) wself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                YYXQJSOCActionCallback callback  =  nil;

                if (cb && cb.length > 0 && ![cb isEqualToString:@"undefined"]) {
                    callback = ^(NSDictionary* data){
                        [wself callRespData:data JSType:jstype];
                    };
                }
                // code here
                void (*action)(id, SEL, NSDictionary *, NSDictionary *, YYXQJSOCActionCallback) = (void (*)(id, SEL, NSDictionary *, NSDictionary *, YYXQJSOCActionCallback)) objc_msgSend;
                
                action(wself.bridgeDelegate, seleter, dict, extra, callback);
                
                //[wself.bridgeDelegate performSelector:seleter withObject:messDict afterDelay:0.0f];
            });
            
        }else{
            //错误处理
            [self errLogWorningJSType:jstype delegate:self.bridgeDelegate selecter:seleter];
        }
        
    }else{
        //错误处理
        [self errLogWorningJSType:jstype data:data callback:cb];
    }
}

-(NSString*)syncall:(NSNumber *)jstype data:(NSDictionary*)data extra:(NSDictionary*)extra
{
    if ([jstype integerValue] == 0) {
        return @"";
    }
    
    if([jstype integerValue] >= kYYXQHyBridJSTypeActionMinIndex && [jstype integerValue] < kYYXQHyBridJSTypeActionMaxIndex){
        //获取函数
        SEL seleter = [self analysisDataFetchSyncSelector:[jstype stringValue]];
        if (!seleter) {
            //错误处理
            return [NSString stringWithFormat:@"{ret:1,msg:'no method for tag:%d'}", [jstype integerValue]];
        }
        
        BOOL hasHandler = [self.bridgeDelegate respondsToSelector:seleter];
        if (self.bridgeDelegate && hasHandler) {
            
            id (*action)(id, SEL, NSDictionary *, NSDictionary *) = (id (*)(id, SEL, NSDictionary *, NSDictionary *)) objc_msgSend;
            
            return action(self.bridgeDelegate, seleter, data, extra);
            
        }else{
            //错误处理
            return [NSString stringWithFormat:@"{ret:1,msg:'no method for tag:%d'}", [jstype integerValue]];
        }
        
    }else{
        //错误处理
        return @"";
    }
}


//获取异步处理方法名称
- (SEL)analysisDataFetchAsyncSelector:(NSString *)jsTag
{

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:YuntuBridgeAsyncMethodSelectorMap ofType:@"plist"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString* methodName = [dict stringForKey:jsTag];
    if (methodName && methodName.length > 0) {
        return NSSelectorFromString(methodName);
    }
    return nil;
}

//获取异步处理方法名称
- (SEL)analysisDataFetchSyncSelector:(NSString *)jsTag
{
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:YuntuBridgeSyncMethodSelectorMap ofType:@"plist"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString* methodName = [dict stringForKey:jsTag];
    if (methodName && methodName.length > 0) {
        return NSSelectorFromString(methodName);
    }
    return nil;
}

//错误处理 无此命令
- (void)errLogWorningJSType:(NSNumber *)jstype delegate:(id)delegate selecter:(SEL)selecter
{
    NSLog(@"YYXQJSOCBridge: WARNING: YYXQJSOCBridge command %@ No responser: delegate:%@, method:%@", [jstype stringValue], delegate, NSStringFromSelector(selecter));
}

//错误处理 无此命令
- (void)errLogWorningJSType:(NSNumber *)jstype data:(NSDictionary *)data callback:(NSString *)cb
{
    NSLog(@"YYXQJSOCBridge: WARNING: Received unknown YYXQJSOCBridge command: %@", [jstype stringValue]);
    
    NSString *message = [NSString stringWithFormat:@"NO This Method Code: %@", [jstype stringValue]];
    if (self.jsContext && self.isLog) {
        
        NSMutableDictionary* respData = [NSMutableDictionary dictionary];
        if (data) {
            [respData setObject:data forKey:@"data"];
        }
        
        [respData setObject:message forKey:@"message"];
        
        [respData setObject:jstype forKey:@"code"];
        
        [respData setObject:[[self class] wkAgent] forKey:@"agent"];
        
        if (cb.length <= 0) {
            [self callJavascriptRegistedMethod:YuntuBridgeErrorCatchMethodName params:respData completed:nil];
            return;
        }
        
        NSString *messageJSON = [[self class] _serializeMessage:respData];   //消息json序列化
        
        /** 转义消息中的非法字符 -write by khzliu */
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
        if (messageJSON == nil || messageJSON.length <= 0) {
            messageJSON = @"{}";
        }
        NSString* javascriptCommand = [NSString stringWithFormat:@"window.Yuntu.callback('%@',%@)", cb, messageJSON];
        
        if (self.contextUsed) {
            [self.jsContext evaluateScript:javascriptCommand];
        }else{
            [self.hybridWebView evaluateJavaScript:javascriptCommand finishHandler:nil];
        }
    }
}



//调用javascript的callback 函数
- (void)callRespData:(id)respData JSType:(NSNumber *)jstype
{
    if (![respData isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSString* respCallback = [self.respCallbacks stringForKey:[jstype stringValue]];
    
    if (!respCallback || respCallback.length <=0) {
        return;
    }
    
    NSString *messageJSON = [[self class] _serializeMessage:respData];   //消息json序列化
    
    /** 转义消息中的非法字符 -write by khzliu */
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    /** 下面这条语句非常关键，改语句执行了一个已注入的javascript对象的方法 messageJSON 则是要传递的参数 -write by khzliu */
    if (messageJSON == nil || messageJSON.length <= 0) {
        messageJSON = @"{}";
    }
    NSString* javascriptCommand = [NSString stringWithFormat:@"window.Yuntu.callback('%@',%@)", respCallback, messageJSON];
    
    NSLog(@"invoke javascript callback:%@",javascriptCommand);
    
    if (self.contextUsed) {
        [self.jsContext evaluateScript:javascriptCommand];
    }else{
        [self.hybridWebView evaluateJavaScript:javascriptCommand finishHandler:nil];
    }
}

//调用javascript的函数
- (void)executeJavascript:(NSString *)javascriptCommand
{
    if (self.contextUsed) {
        [self.jsContext evaluateScript:javascriptCommand];
    }else{
        [self.hybridWebView evaluateJavaScript:javascriptCommand finishHandler:nil];
    }
}



//调用已经注册过的javascript函数
- (void)callJavascriptRegistedMethod:(NSString *)name params:(YYXQJSOCBridgeMessage *)msg completed:(YYXQJSOCActionCallback)block
{
    NSString* messageJSON = [YYXQJSOCBridgeManager _serializeMessage:msg];
    
    /** 转义消息中的非法字符 -write by khzliu */
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
//    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    if (messageJSON == nil || messageJSON.length <= 0) {
        messageJSON = @"{}";
    }
    NSString *javascriptCommand = [NSString stringWithFormat:@"window.Yuntu.callHandler('%@',%@)", name, messageJSON];
    
    if(block){
        if (self.contextUsed) {
            block([[self.jsContext evaluateScript:javascriptCommand] toDictionary]);
        }else{
            [self.hybridWebView evaluateJavaScript:javascriptCommand finishHandler:^(id data, NSError *error) {
                if (!error) {
                    block(data);
                }else{
                    block(@{});
                }
            }];
        }
    }else{
        if (self.contextUsed) {
           [[self.jsContext evaluateScript:javascriptCommand] toDictionary];
        }else{
            [self.hybridWebView evaluateJavaScript:javascriptCommand finishHandler:nil];
        }
    }
    
}

/** 序列化json字符串 NSDicitonary转NSString-write by khzliu */
+ (NSString *)_serializeMessage:(id)message {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
}

/** 类型转换 json string to NSDictionray -write by khzliu */
- (NSArray*)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}


#pragma mark -

#pragma mark HZHybridWebViewDelegate
- (BOOL)hybridWebView:(HZHybridWebView*)hybridWebView shouldStartDecidePolicy:(NSURLRequest *)request
{
    if (!hybridWebView.isWKWebView) {
        if ([request.URL.path isEqualToString:completeRPCURLPath]) {
            [self completeProgress];
            return NO;
        }
    }
    
    
    BOOL ret = YES;
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebView:shouldStartLoadWithRequest:)]) {
        ret = [self.webDelegate bridgeWebView:hybridWebView shouldStartLoadWithRequest:request];
    }
    
    //针对UIWebView的progress
    if (!hybridWebView.isWKWebView) {
        BOOL isFragmentJump = NO;
        if (request.URL.fragment) {
            NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
            isFragmentJump = [nonFragmentURL isEqualToString:hybridWebView.webView.request.URL.absoluteString];
        }
        
        BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
        
        BOOL isHTTPOrLocalFile = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"] || [request.URL.scheme isEqualToString:@"file"];
        if (ret && !isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation) {
            _currentURL = request.URL;
            [self reset];
        }
    }else{
        [self reset];
    }
    
    return ret;
}

//开始加载
- (void)hybridWebViewDidStartNavigation:(HZHybridWebView*)hybridWebView
{
   
    //连接桥
    [self bindBridgeToJSContextWithWebView:hybridWebView];
    
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebViewDidStartLoad:)]) {
        [self.webDelegate bridgeWebViewDidStartLoad:hybridWebView];
    }

    
    if (!hybridWebView.isWKWebView) {
        /** 首次加载成功之后 增加进度条刻度 -write by khzliu */
        _loadingCount++;
        _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
        
        [self startProgress];
    }
}
//加载失败
- (void)hybridWebView:(HZHybridWebView*)hybridWebView failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error{
    
   
    
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebView:didFailLoadWithError:)]) {
        [self.webDelegate bridgeWebView:hybridWebView didFailLoadWithError:error];
    }
    
    if(!hybridWebView.isWKWebView)
    {
        //快进进度条
        _loadingCount--;
        [self incrementProgress];
        
        __block NSString *readyState = nil;
        __block typeof(self) wself = self;
        [hybridWebView evaluateJavaScript:@"document.readyState" finishHandler:^(NSString* string , NSError* error){
            readyState = [string copy];
            
            BOOL interactive = [readyState isEqualToString:@"interactive"];
            
            NSString* scheme = hybridWebView.webView.request.mainDocumentURL.scheme;
            NSString* host = hybridWebView.webView.request.mainDocumentURL.host;
            
            if (interactive) {
                _interactive = YES;
                NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", scheme, host, completeRPCURLPath];
                [hybridWebView evaluateJavaScript:waitForCompleteJS finishHandler:nil];
            }
            
            
            BOOL isNotRedirect = _currentURL && [_currentURL isEqual:hybridWebView.webView.request.mainDocumentURL];
            
            
            BOOL complete = [readyState isEqualToString:@"complete"];
            if ((complete && isNotRedirect) || error) {
                [wself completeProgress];
            }
        }];
    }else{
        [self reset];
    }
    
}



//完成加载
- (void)hybridWebView:(HZHybridWebView*)hybridWebView finishLoadOrNavigation: (NSURLRequest *) request
{
    
    /** 这行代码是解决javascript引起的 Memory Leaks on Xmlhttprequest -write by khzliu */
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitDiskImageCacheEnabled"];//自己添加的，原文没有提到。
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitOfflineWebApplicationCacheEnabled"];//自己添加的，原文没有提到。
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebViewDidFinishLoad:)]) {
        [self.webDelegate bridgeWebViewDidFinishLoad:hybridWebView];
    }

    if(!hybridWebView.isWKWebView){
        //快进进度条
        _loadingCount--;
        [self incrementProgress];
        
        __block typeof(self) wself = self;
        [hybridWebView evaluateJavaScript:@"document.readyState" finishHandler:^(NSString* string , NSError* error){
            NSString *readyState = [string copy];
            BOOL interactive = [readyState isEqualToString:@"interactive"];
            if (interactive) {
                _interactive = YES;
                NSString* scheme = hybridWebView.webView.request.mainDocumentURL.scheme;
                NSString* host = hybridWebView.webView.request.mainDocumentURL.host;

                NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", scheme, host, completeRPCURLPath];
                [hybridWebView evaluateJavaScript:waitForCompleteJS finishHandler:nil];
            }
        
            
            BOOL isNotRedirect = _currentURL && [_currentURL isEqual:hybridWebView.webView.request.mainDocumentURL];
            
            BOOL complete = [readyState isEqualToString:@"complete"];
            if (complete && isNotRedirect) {
                [wself completeProgress];
            }
        }];
    }else{
        [self reset];
    }
}

- (void)hybridUserContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary* msgData = message.body;
    if (![msgData isKindOfClass:[NSDictionary class]]) {
        NSLog(@"YuntuWKBridge: WARNING: Invalid %@ received: %@", [msgData class], msgData);
        return;
    }

    
    id jstag = [msgData objectForKey:@"js_tag"];
    id data = [msgData objectForKey:@"js_data"];
    NSString* callback = [msgData objectForKey:@"js_cb"];
    
    if (jstag && [jstag isKindOfClass:[NSNumber class]]) {
        if (data) {
            if (callback) {
                [self call:jstag data:data callback:callback];
            }else{
                [self call:jstag data:data];
            }
        }else{
            [self call:jstag];
        }
    }else{
        NSLog(@"YuntuWKBridge: WARNING: Null Message Body");
        return;
    }

}

- (void)hybridWebView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler
{
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.webDelegate bridgeWebView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler();
    }
}

- (void)hybridWebView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    if(self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]){
        [self.webDelegate bridgeWebView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler(NO);
    }
}

- (void)hybridWebView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    /** 处理自定义同步方法 -write by khzliu */
    if (prompt != nil && [prompt length] > 0 && [prompt characterAtIndex:0] == '{') {
        NSDictionary* messageData = [prompt objectFromJSONString];
        NSNumber* jsType = [messageData numberForKey:@"js_tag" nilValue:@(0)];
        NSDictionary* data = [messageData dictForKey:@"data"];
        NSDictionary* extra = (defaultText&&[defaultText length]>0)?[defaultText objectFromJSONString]:@{};
        completionHandler([self syncall:jsType data:data extra:extra]);
        return;
    }
    
    if(self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeWebView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]){
        [self.webDelegate bridgeWebView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
    }else{
        completionHandler(defaultText);
    }
}


#pragma mark UIScrollViewDelegate
- (void)hybridScrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(bridgeScrollViewDidScroll:)]) {
        [self.webDelegate bridgeScrollViewDidScroll:scrollView];
    }
}


#pragma mark -
#pragma mark Method Forwarding
// for future UIWebViewDelegate impl

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    
    if ([self.webDelegate respondsToSelector:aSelector])
        return YES;
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if(!signature) {
        if([self.webDelegate respondsToSelector:selector]) {
            return [(NSObject *)self.webDelegate methodSignatureForSelector:selector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation*)invocation
{
    if ([self.webDelegate respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:self.webDelegate];
    }
}

//开始下载html文件
- (void)hybridWebView:(HZHybridWebView *)hybridWebView startDownloadHtml:(NSURLRequest *) request
{
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(brideWebView:startDownloadHtml:)]) {
        [self.webDelegate brideWebView:hybridWebView startDownloadHtml:request];
    }
}
//开始下载html文件
- (void)hybridWebView:(HZHybridWebView *)hybridWebView didDownloadHtml:(NSURLRequest *)request html:(NSString *)html
{
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(brideWebView:didDownloadHtml:html:)]) {
        [self.webDelegate brideWebView:hybridWebView didDownloadHtml:request html:html];
    }
}

//下载html文件失败
- (void)hybridWebView:(HZHybridWebView *)hybridWebView failDownloadHtml:(NSURLRequest *)request response:(NSURLResponse *)resp withError: (NSError *) error
{

    
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(brideWebView:failDownloadHtml:response:withError:)]) {
        [self.webDelegate brideWebView:hybridWebView failDownloadHtml:request response:resp withError:error];
    }
    
}


@end
