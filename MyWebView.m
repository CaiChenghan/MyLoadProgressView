//
//  MyWebView.m
//  MyLoadProgressView
//
//  Created by 蔡成汉 on 15/2/27.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "MyWebView.h"

NSString *completeRPCURLPath = @"/webviewprogressproxy/complete";

const float MyInitialProgressValue = 0.1f;
const float MyInteractiveProgressValue = 0.5f;
const float MyFinalProgressValue = 0.9f;

@interface MyWebView ()
{
    NSUInteger loadingCount;
    NSUInteger maxLoadCount;
    
    /**
     *  当前加载的url -- 判断url是否重定向
     */
    NSURL *currentURL;
    
    /**
     *  当前加载的进度
     */
    CGFloat currentLoadProgress;
    
    BOOL interactive;
}
@end

@implementation MyWebView

/**
 *  重写的initia方法
 *
 *  @param frame 实例化的webView的大小
 *
 *  @return 实例化之后的webView
 */
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        maxLoadCount = loadingCount = 0;
        //默认值currentLoadProgress = 99;
        currentLoadProgress = 99;
        interactive = NO;
        self.delegate = self;
    }
    return self;
}

/**
 *  是否进行请求加载
 *
 *  @param webView        当前运行的webView
 *  @param request        当前请求
 *  @param navigationType <#navigationType description#>
 *
 *  @return YES表示加载继续，NO表示停止加载
 */
-(BOOL)webView:(MyWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{    
    if ([request.URL.path isEqualToString:completeRPCURLPath]) {
        [self completeProgress:webView];
        return NO;
    }
    
    BOOL ret = YES;
    if ([self respondsToSelector:@selector(myWebView:shouldStartLoadWithRequest:navigationType:)])
    {
        ret = [self.myWebDelegate myWebView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (ret && !isFragmentJump && isHTTP && isTopLevelNavigation) {
        currentURL = request.URL;
        [self reset:webView];
    }
    return ret;
}

/**
 *  开始加载
 *
 *  @param webView 当前运行的webView
 */
-(void)webViewDidStartLoad:(MyWebView *)webView
{
    if ([self.myWebDelegate respondsToSelector:@selector(myWebViewDidStartLoad:)])
    {
        [self.myWebDelegate myWebViewDidStartLoad:webView];
    }
    loadingCount++;
    maxLoadCount = fmax(maxLoadCount, loadingCount);
    
    [self startProgress:webView];
}

/**
 *  加载完成
 *
 *  @param webView 当前运行的webView
 */
-(void)webViewDidFinishLoad:(MyWebView *)webView
{
    if ([self.myWebDelegate respondsToSelector:@selector(myWebViewDidFinishLoad:)])
    {
        [self.myWebDelegate myWebViewDidFinishLoad:webView];
    }
    loadingCount--;
    [self incrementProgress:webView];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL tpInteractive = [readyState isEqualToString:@"interactive"];
    if (tpInteractive)
    {
        interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.request.mainDocumentURL.scheme, webView.request.mainDocumentURL.host, completeRPCURLPath];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = currentURL && [currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect)
    {
        [self completeProgress:webView];
    }
}

/**
 *  webView加载错误
 *
 *  @param webView 当前运行的webView
 *  @param error   错误
 */
-(void)webView:(MyWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([self.myWebDelegate respondsToSelector:@selector(myWebViewDidFinishLoad:)])
    {
        [self.myWebDelegate myWebView:webView didFailLoadWithError:error];
    }
    loadingCount--;
    [self incrementProgress:webView];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL tpInteractive = [readyState isEqualToString:@"interactive"];
    if (tpInteractive)
    {
        interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.request.mainDocumentURL.scheme, webView.request.mainDocumentURL.host, completeRPCURLPath];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = currentURL && [currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if ((complete && isNotRedirect) || error)
    {
        [self completeProgress:webView];
    }
}


/**
 *  进度结果处理 -- 阀门掌控、数据委托
 *
 *  @param progress 进度值
 *  @param webView  当前使用的webView
 */
-(void)setprogress:(CGFloat)progress webView:(MyWebView *)webView
{
    if (progress == 0 && (currentLoadProgress == 1 || currentLoadProgress == 99))
    {
        //新的开始标记
        currentLoadProgress = progress;
        if ([self.myWebDelegate respondsToSelector:@selector(myWebViewProgress:loadProgress:)])
        {
            [self.myWebDelegate myWebViewProgress:webView loadProgress:progress];
        }
    }
    else
    {
        if (progress > currentLoadProgress)
        {
            currentLoadProgress = progress;
            if ([self.myWebDelegate respondsToSelector:@selector(myWebViewProgress:loadProgress:)])
            {
                [self.myWebDelegate myWebViewProgress:webView loadProgress:progress];
            }
        }
    }
}



/**
 *  重置
 */
- (void)reset:(MyWebView *)webView
{
    maxLoadCount = loadingCount = 0;
    interactive = NO;
    [self setprogress:0.0 webView:webView];
}

/**
 *  开始加载的进度数值
 *
 *  @param webView 当前使用的webView
 */
- (void)startProgress:(MyWebView *)webView
{
    if (currentLoadProgress < MyInitialProgressValue)
    {
        [self setprogress:MyInitialProgressValue webView:webView];
    }
}

/**
 *  结束加载的进度数值
 *
 *  @param webView 当前使用的webView
 */
- (void)completeProgress:(MyWebView *)webView
{
    [self setprogress:1.0 webView:webView];
}

- (void)incrementProgress:(MyWebView *)webView
{
    float progress = currentLoadProgress;
    float maxProgress = interactive ? MyFinalProgressValue : MyInteractiveProgressValue;
    float remainPercent = (float)loadingCount / (float)maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setprogress:progress webView:webView];
}

/**
 *  set方法，获取readonly的currentProgress数值
 *
 *  @return currentProgress
 */
-(CGFloat)loadProgress
{
    if (currentLoadProgress == 99)
    {
        return 0;
    }
    else
    {
        return currentLoadProgress;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
