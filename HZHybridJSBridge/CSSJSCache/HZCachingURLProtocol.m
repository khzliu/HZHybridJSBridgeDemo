//
//  HZCachingURLProtocol.m
//  app
//
//  Created by 刘华舟 on 15/5/28.
//  Copyright (c) 2015年 hdaren. All rights reserved.
//

#import "HZCachingURLProtocol.h"
#import "Reachability.h"
#import "NSString+SHA1.h"
#import "NSMassKit.h"
#import <UIKit/UIKit.h>

#define WORKAROUND_MUTABLE_COPY_LEAK 1
#define kYYXQCustomProtocolScheme @"yyxqapp"       //拦截的协议名
#define kYYXQCustomDomainHost   @"localhost"     //拦截的域名
#define kYYXQCSSJSFileCacheDirName @"yyxq.app.cache"          //缓存文件名称

#define kYYXQHeaderREFERER                  @"REFERER"
#define kYYXQHeaderREFERERValue             @"http://www.kangxihui.com"

#define JSCSSCacheData NSDictionary*

#define JSCSSCacheDataMEType @"metype"
#define JSCSSCacheDataSRC   @"src"

#if WORKAROUND_MUTABLE_COPY_LEAK
// required to workaround http://openradar.appspot.com/11596316
@interface NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround;

@end
#endif

@interface HZCachedData : NSObject <NSCoding>
@property (nonatomic, readwrite, strong) NSData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@property (nonatomic, readwrite, strong) NSURLRequest *redirectRequest;
@end

static NSString *HZCachingURLHeader = @"X-HZCache";

@interface HZCachingURLProtocol () // <NSURLConnectionDelegate, NSURLConnectionDataDelegate> iOS5-only
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;

@property (nonatomic, readwrite, weak) id heckUIWebViewCtr;

- (void)appendData:(NSData *)newData;
@end

static NSObject *HZCachingSupportedSchemesMonitor;
static NSSet *HZCachingSupportedSchemes;

@implementation HZCachingURLProtocol
@synthesize connection = connection_;
@synthesize data = data_;
@synthesize response = response_;

+ (void)initialize
{
    if (self == [HZCachingURLProtocol class])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            HZCachingSupportedSchemesMonitor = [NSObject new];
        });
        
        //[self setSupportedSchemes:[NSSet setWithObjects:@"http", @"https", @"ftp", nil]];
        [self setSupportedSchemes:[NSSet setWithObjects:@"http", @"https", kYYXQCustomProtocolScheme, nil]];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // only handle http requests we haven't marked with our header.
    if ([[self supportedSchemes] containsObject:[[request URL] scheme]] &&
        ([request valueForHTTPHeaderField:HZCachingURLHeader] == nil))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHTMLURLIntercept object:nil];
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest* connectionRequest = [request mutableCopy];
    
    [connectionRequest setValue:kYYXQHeaderREFERERValue forHTTPHeaderField:kYYXQHeaderREFERER];
    
    [connectionRequest setValue:[self userAgentString:[connectionRequest valueForHTTPHeaderField:@"User-Agent"]] forHTTPHeaderField:@"User-Agent"];
    
    return connectionRequest;
}


- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest
{
    // This stores in the Caches directory, which can be deleted when space is low, but we only use it for offline access
    NSString *cachesPath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject], kYYXQCSSJSFileCacheDirName];
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:cachesPath isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *fileName = [[[aRequest URL] absoluteString] sha1];
    return [cachesPath stringByAppendingPathComponent:fileName];
}

+ (NSString *)loadUserAgent:(BOOL)reload
{
    static NSString* userAgent = nil;
    if (userAgent == nil || reload) {
        //#yyxq,1.9.0#iphone7,1#iOS,9.3#320#960#a/b/c;
        NSMutableArray* msgArray = [NSMutableArray array];
        [msgArray addObject:[NSString stringWithFormat:@"|yyxq,%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];//应用信息和版本
        [msgArray addObject:[[UIDevice currentDevice] model]];//手机型号
        [msgArray addObject:[NSString stringWithFormat:@"%@,%@",[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]]];//手机系统版本
        [msgArray addObject:@([UIScreen mainScreen].bounds.size.width)];//手机屏宽度
        [msgArray addObject:@([UIScreen mainScreen].bounds.size.height)];//手机屏幕高度
        NSString* debug = [[NSUserDefaults standardUserDefaults] objectForKey:@"abc"];
        if (debug == nil) {
            debug = @"a";
        }
        [msgArray addObject:debug];
        
        userAgent = [msgArray componentsJoinedByString:@"|"];
    }
    return userAgent;
}

+ (NSString *)userAgentString:(NSString *)str
{
    NSString* userAgent = [self loadUserAgent:NO];
    if (str == nil) {
        return userAgent;
    }
        
    return [NSString stringWithFormat:@"%@%@",str,userAgent];
}
- (void)startLoading
{
    if (![self useCache]) {
        NSMutableURLRequest *connectionRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
        [[self request] mutableCopyWorkaround];
#else
        [[self request] mutableCopy];
#endif
        // we need to mark this request with our header so we know not to handle it in +[NSURLProtocol canInitWithRequest:].
        [connectionRequest setValue:HZCachingURLHeader forHTTPHeaderField:HZCachingURLHeader];
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest
                                                                    delegate:self];
        [self setConnection:connection];
    }else {
        HZCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachePathForRequest:[self request]]];
        if (cache) {
            NSData *data = [cache data];
            NSURLResponse *response = [cache response];
            NSURLRequest *redirectRequest = [cache redirectRequest];
            if (redirectRequest) {
                [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
            } else {
                
                [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed]; // we handle caching ourselves.
                [[self client] URLProtocol:self didLoadData:data];
                [[self client] URLProtocolDidFinishLoading:self];
            }
        }else {
            
            //加载本地的Config下载的文件
            JSCSSCacheData dataDict = [self loadLocalCSSJSFileWithRequest:self.request];
            
            if (dataDict) {
                
                NSData* data = [dataDict objectForKey:JSCSSCacheDataSRC];
                NSString* metype = [dataDict stringForKey:JSCSSCacheDataMEType nilValue:@"text/html"];
                
                NSString *cachePath = [self cachePathForRequest:[self request]];
                HZCachedData *cache = [HZCachedData new];
                NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL]
                                                                    MIMEType:metype
                                                       expectedContentLength:-1
                                                            textEncodingName:nil];
                [cache setResponse:response];
                
                if (data) {
                    [cache setData:data];
                    [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
                }
                
                [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed]; // we handle caching ourselves.
                [[self client] URLProtocol:self didLoadData:data];
                [[self client] URLProtocolDidFinishLoading:self];
                
            }else{
                [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
            }
        }
    }
}

- (void)stopLoading
{
    [[self connection] cancel];
}

// NSURLConnection delegates (generally we pass these on to our client)

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    // Thanks to Nick Dowell https://gist.github.com/1885821
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
        [request mutableCopyWorkaround];
#else
        [request mutableCopy];
#endif
        // We need to remove our header so we know to handle this request and cache it.
        // There are 3 requests in flight: the outside request, which we handled, the internal request,
        // which we marked with our header, and the redirectableRequest, which we're modifying here.
        // The redirectable request will cause a new outside request from the NSURLProtocolClient, which
        // must not be marked with our header.
        [redirectableRequest setValue:nil forHTTPHeaderField:HZCachingURLHeader];
        
        NSString *cachePath = [self cachePathForRequest:[self request]];
        HZCachedData *cache = [HZCachedData new];
        [cache setResponse:response];
        [cache setData:[self data]];
        [cache setRedirectRequest:redirectableRequest];
        [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    NSString *cachePath = [self cachePathForRequest:[self request]];
    
    //判断是否要存
    if ([self useSave]) {
        HZCachedData *cache = [HZCachedData new];
        [cache setResponse:[self response]];
        
        /** 如果接收到数据才进行保存，如果没有接收到数据那就不保存了 -write by khzliu */
        if (self.data) {
            [cache setData:[self data]];
            [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
        }
    }
    
    
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

- (BOOL) useCache
{
    BOOL reachable = (BOOL) [[Reachability reachabilityWithHostName:[[[self request] URL] host]] currentReachabilityStatus] != NotReachable;
    
    if (reachable) {
        NSString *urlstring = [[[self request] URL] absoluteString];
        if ([urlstring containsString:kYYXQCustomDomainHost]) {
            return YES;
        }else{
            return NO;
        }
    }
    return reachable;
}

- (BOOL)useSave{
    NSString *urlstring = [[[self request] URL] absoluteString];
    if ([urlstring containsString:kYYXQCustomDomainHost]) {
        return YES;
    }else{
        return NO;
    }
}

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}

+ (NSSet *)supportedSchemes {
    NSSet *supportedSchemes;
    @synchronized(HZCachingSupportedSchemesMonitor)
    {
        supportedSchemes = HZCachingSupportedSchemes;
    }
    return supportedSchemes;
}

+ (void)setSupportedSchemes:(NSSet *)supportedSchemes
{
    @synchronized(HZCachingSupportedSchemesMonitor)
    {
        HZCachingSupportedSchemes = supportedSchemes;
    }
}

//加载本地config下载的文件
- (JSCSSCacheData)loadLocalCSSJSFileWithRequest:(NSURLRequest *)request
{
    NSString* requestString = request.URL.absoluteString;
    NSString* protocolString = [NSString stringWithFormat:@"%@://%@/", kYYXQCustomProtocolScheme,kYYXQCustomDomainHost];
    if (requestString.length <= protocolString.length) {
        return nil;
    }
    
    NSString* paramsString = [requestString substringFromIndex:protocolString.length];
    
    if (paramsString) {
        NSArray *params = [paramsString componentsSeparatedByString:@"/"];
        
        if (params && params.count == 2) {
            NSString* fileType = [params firstObject];
            NSString* fileName = [params lastObject];
            
            // This stores in the Config directory
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            
            BOOL isDir = NO;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL existed = [fileManager fileExistsAtPath:cachesPath isDirectory:&isDir];
            if ( isDir == YES && existed == YES )
            {
                NSString *srcPath = [NSString stringWithFormat:@"%@/%@",cachesPath,fileName];
                
                NSData *data = [NSData dataWithContentsOfFile:srcPath];
                
                if (data == nil) {
                    return nil;
                }
                
                NSMutableDictionary* cacheDict = [NSMutableDictionary dictionary];
                
                NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"METypeMap" ofType:@"plist"];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
                NSString* metype = [dict stringForKey:fileType nilValue:@"text/html"];
                
                [cacheDict setObject:metype forKey:JSCSSCacheDataMEType];
                [cacheDict setObject:data forKey:JSCSSCacheDataSRC];
                
                return cacheDict;
            }
        }
    }
    return nil;
}


//清空所有的Response Cache
+ (BOOL)clearAllResponseCache
{
    // This stores in the Caches directory, which can be deleted when space is low, but we only use it for offline access
    NSString *cachesPath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject], kYYXQCSSJSFileCacheDirName];
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:cachesPath isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:nil];
        return YES;
    }else{
        return [fileManager removeItemAtPath:cachesPath error:nil];
    }
    return NO;
}

//清空某个url对应的Response Cache
+ (BOOL)clearResponseCacheWithAbsoluteString:(NSString *)str
{
    
    // This stores in the Caches directory, which can be deleted when space is low, but we only use it for offline access
    NSString *fileName = [str sha1];
    
    NSString *cachesPath = [NSString stringWithFormat:@"%@/%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject], kYYXQCSSJSFileCacheDirName,fileName];
    
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:cachesPath isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        return YES;
    }else{
        return [fileManager removeItemAtPath:cachesPath error:nil];
    }
    return NO;
}

@end

static NSString *const kDataKey = @"data";
static NSString *const kResponseKey = @"response";
static NSString *const kRedirectRequestKey = @"redirectRequest";

@implementation HZCachedData
@synthesize data = data_;
@synthesize response = response_;
@synthesize redirectRequest = redirectRequest_;

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self data] forKey:kDataKey];
    [aCoder encodeObject:[self response] forKey:kResponseKey];
    [aCoder encodeObject:[self redirectRequest] forKey:kRedirectRequestKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil) {
        [self setData:[aDecoder decodeObjectForKey:kDataKey]];
        [self setResponse:[aDecoder decodeObjectForKey:kResponseKey]];
        [self setRedirectRequest:[aDecoder decodeObjectForKey:kRedirectRequestKey]];
    }
    
    return self;
}

@end

#if WORKAROUND_MUTABLE_COPY_LEAK
@implementation NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    if ([self HTTPBodyStream]) {
        [mutableURLRequest setHTTPBodyStream:[self HTTPBodyStream]];
    } else {
        [mutableURLRequest setHTTPBody:[self HTTPBody]];
    }
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];
    
    return mutableURLRequest;
}

@end
#endif
