# HZHybridJSBridge

基于WKWebView/UIWebview的Hybrid APP开发框架

## HZHybridWebview

HZHybridWebview在基于WKWebView/UIWebview添加了系统和第三方API，同时将一些性能关键的地方在运行时编译为原生UI，如转场、导航等，使其兼有Web的灵活和原生的性能。
特征如下：<br/>

* 运用WKWebview解决了UIWebview占中内存大，过于笨重的问题
* 集成自定义应用接口
* 统一处理网络问题
* 基于Javascript.framework 和 WebKit.framework的高性能，加速数据加载、点击响应和滚动速度
* 支持iOS 7+
* iOS与Html5之间事件/数据交互功能
* Web与Native界面直接的混合布局和混合渲染功能
* 加速数据加载、点击响应和滚动速度
* 常用手势支持、界面切换动画
* 执行Html5中指定Javascript脚本功能
＊ IOS开发中常用的网络请求框架，缓存管理等工具接口
＊ 统一的生命周期管理，窗口系统，用户体验

## 主要类和文件
YYXQJSOCBridgeManager: 实现Javascript与Native的高效的通讯
YYXQHybridBaseController: HTML解析Web容器
YYXQNativeViewController: 原生控制器
YYXQJSOCBridge: Web和Native桥接对象
YuntuUIWebJavaScriptBridge.js.txt: Javascript端的交互对象for UIWebView
YuntuWKWebJavaScriptBridge.js.txt: Javascript端的交互对象for UIWebView

## 示例
详细查看[Demo中的ViewController](HZHybridJSBridgeDemo/HZHybridJSBridgeDemo/ViewController.m)

	- (void)viewDidLoad {
    	[super viewDidLoad];
    	
	    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"test_os_js_bridge" ofType:@"html"];
	    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	    [self.hybridWebView loadHTMLString:htmlString baseURL:[NSURL URLWithString:filePath]];
	}

