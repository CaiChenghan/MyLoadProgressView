//
//  ViewController.m
//  MyLoadProgressView
//
//  Created by 蔡成汉 on 15/2/27.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "ViewController.h"
#import "MyWebView.h"


@interface ViewController ()<MyWebViewDelegate>
{
    NSURL *_currentURL;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MyWebView";
    
    if ([[UIDevice currentDevice] systemVersion].floatValue>=7.0)
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    MyWebView *myWebView = [[MyWebView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    myWebView.myWebDelegate = self;
    myWebView.scalesPageToFit = YES;
    [myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]];
    [self.view addSubview:myWebView];
}

-(BOOL)myWebView:(MyWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

-(void)myWebViewDidStartLoad:(MyWebView *)webView
{
    
}

-(void)myWebViewDidFinishLoad:(MyWebView *)webView
{
    
}

-(void)myWebView:(MyWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}

-(void)myWebViewProgress:(MyWebView *)webView loadProgress:(float)progress
{
    NSLog(@"%f",progress);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
