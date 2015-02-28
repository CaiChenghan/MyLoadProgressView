//
//  MyWebView.h
//  MyLoadProgressView
//
//  Created by 蔡成汉 on 15/2/27.
//  Copyright (c) 2015年 JW. All rights reserved.
//

/**
 *  具有加载进度的WebView
 */

#import <UIKit/UIKit.h>

@class MyWebView;

@protocol MyWebViewDelegate <NSObject>

@optional
- (BOOL)myWebView:(MyWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)myWebViewDidStartLoad:(MyWebView *)webView;
- (void)myWebViewDidFinishLoad:(MyWebView *)webView;
- (void)myWebView:(MyWebView *)webView didFailLoadWithError:(NSError *)error;

/**
 *  加载进度 -- 会被多次调用
 *
 *  @param webView  当前运行的webView
 *  @param progress 加载进度，其结为0~1之间的数值
 */
- (void)myWebViewProgress:(MyWebView *)webView loadProgress:(float)progress;

@end

@interface MyWebView : UIWebView<UIWebViewDelegate>

@property (nonatomic , weak) id<MyWebViewDelegate>myWebDelegate;

/**
 *  当前的进度
 */
@property (nonatomic , readonly , getter=loadProgress) CGFloat currentProgress;

@end
