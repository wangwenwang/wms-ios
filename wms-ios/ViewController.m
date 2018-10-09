//
//  ViewController.m
//  wms-ios
//
//  Created by wenwang wang on 2018/6/19.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ViewController.h"
#import <ZipArchive.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ScanCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <WXApi.h>
#import "RichURLSessionProtocol.h"
#import "RegisterViewController.h"

@interface ViewController () {
    
    NSURLConnection *_urlConnection;
    NSURLRequest *_request;
    BOOL _authenticated;
}

@property (weak, nonatomic) IBOutlet UIButton *registerBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [_registerBtn setBackgroundColor:[UIColor colorWithRed:47/255.0 green:95/255.0 blue:199/255.0 alpha:1.0]];
    [_registerBtn.layer setCornerRadius:5.0f];
    
    [NSURLProtocol registerClass:[RichURLSessionProtocol class]];
    
    
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
    NSLog(@"zipPath:%@", zipPath);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *unzipPath = [documentpath stringByAppendingPathComponent:@"/test"];
    NSLog(@"unzipPath:%@", unzipPath);
    
    // Unzip
    [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
    
    // 加载URL
    NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    _request = [NSURLRequest requestWithURL:url];
    
    //    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    //    [self.webView loadHTMLString:htmlString baseURL:url];
    
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
    
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
        
        //微信
        NSLog(@"YESWX");
    }else {
        
        // 移除微信按钮
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            for (int i = 0; i < 20; i++) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')", @"NO"];
                    NSLog(@"%@",jsStr);
                    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
                });
                usleep(100000);
            }
        });
    }
    
    // 显示版本号
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (int i = 0; i < 20; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
                NSString *jsStrVersion = [NSString stringWithFormat:@"VersionShow('版本:%@')", app_Version];
                NSLog(@"%@",jsStrVersion);
                [_webView stringByEvaluatingJavaScriptFromString:jsStrVersion];
            });
            usleep(100000);
        }
    });
    
    
    NSString *jsStr = [NSString stringWithFormat:@"QRScanAjax('%@', '%@', '%@', '%@',)" ,@"1" ,@"2" ,@"3" ,@"4"];
    NSLog(@"%@",jsStr);
    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
    return;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (IBAction)registerOnclick:(UIButton *)sender {
    
    RegisterViewController *vc = [[RegisterViewController alloc] init];
//    vc
}




- (void)webViewDidFinishLoad:(UIWebView *)webView{
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * qrscanDes = @"";
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            qrscanDes = jsVal.toString;
            break;
        }
        if([qrscanDes isEqualToString:@"调用app原生扫描二维码/条码"]) {
            
            [self scanQRCode];
        }else if([qrscanDes isEqualToString:@"播放警告音"]) {
            
            [self playSoundName:@"wrong01.wav"];
        }else if([qrscanDes isEqualToString:@"微信登录"]) {
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_wms";
            dispatch_async(dispatch_get_main_queue(), ^{
                [WXApi sendReq:req];
            });
        }
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        else if([qrscanDes isEqualToString:@"登录页面已加载"]) {
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                
                //微信
                NSLog(@"YESWX");
            }else {
                
                // 移除微信按钮
                NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')", @"NO"];
                NSLog(@"%@",jsStr);
                [_webView stringByEvaluatingJavaScriptFromString:jsStr];
            }
            
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            NSString *jsStrVersion = [NSString stringWithFormat:@"VersionShow('版本:%@')", app_Version];
            NSLog(@"%@",jsStrVersion);
            [_webView stringByEvaluatingJavaScriptFromString:jsStrVersion];
        }
        NSLog(@"%@",qrscanDes);
    };
}


#pragma mark - 功能函数

// 跳到扫码控制器
- (void)skipScan {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        ScanCodeViewController *vc = [[ScanCodeViewController alloc] init];
        vc.webView = self.webView;
        [self presentViewController:vc animated:YES completion:nil];
    });
}


- (void)scanQRCode {
    
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [self skipScan];
                    });
                    // 用户第一次同意了访问相机权限
                    NSLog(@"用户第一次同意了访问相机权限 - - %@", [NSThread currentThread]);
                    
                } else {
                    // 用户第一次拒绝了访问相机权限
                    NSLog(@"用户第一次拒绝了访问相机权限 - - %@", [NSThread currentThread]);
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) {
            
            // 用户允许当前应用访问相机
            [self skipScan];
        } else if (status == AVAuthorizationStatusDenied) {
            
            // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请去-> [设置 - 隐私 - 相机 - wms] 打开访问开关" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"未检测到您的摄像头" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)playSoundName:(NSString *)name {
    
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];
    
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, LMsoundCompleteCallback, NULL);
    AudioServicesPlaySystemSound(soundID); // 播放音效
}

void LMsoundCompleteCallback(SystemSoundID soundID, void *clientData){
    
}








// NSURLConnection适配
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
    else
    {
        if ([challenge previousFailureCount] == 0)
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
        else
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

#pragma mark - NSURLSessionDelegate代理方法 HTTPS ---开始---
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    // 判断服务器返回的证书是否是服务器信任的
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential)
        {
            disposition = NSURLSessionAuthChallengeUseCredential; // 使用证书
        }
        else
        {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling; // 忽略证书 默认的做法
        }
    }
    else
    {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge; // 取消请求,忽略证书
    }
    if (completionHandler)// 安装证书
    {
        completionHandler(disposition, credential);
    }
}


#pragma mark - Webview delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSLog(@"Did start loading: %@ auth:%d", [[request URL] absoluteString], _authenticated);
    _authenticated = NO;
    
    // 这里在 首次加载本地request H5的时候 将不能正常请求的https  做一个证书信任方面的处理  拿https://39.108.172.22下的任意一个接口处理下信任问题即可
    _request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://scm.cy-scm.com/wms/RFLogin.do"]];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
    [_urlConnection start];
    
    // 这里做一个  特有化处理  因为第一次加载的H5 是本地资源路径  如果是  url资源，可以注释掉
    if ([[[request URL] absoluteString] containsString:@"dist/index.html"])
    {
        return YES;
    }
    
    if (!_authenticated)
    {
        _authenticated = NO;
        _urlConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
        [_urlConnection start];
        return NO;
    }
    return YES;
}

#pragma mark - NURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
    NSLog(@"WebController Got auth challange via NSURLConnection");
    if ([challenge previousFailureCount] == 0)
    {
        _authenticated = YES;
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    } else
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    NSLog(@"WebController received response via NSURLConnection");
    
    // remake a webview call now that authentication has passed ok.
    _authenticated = YES;
    //    [_webView loadRequest:_request];  //  如果加载的是url 而不是本地资源路径  那么注释放开即可
    
    // Cancel the URL connection otherwise we double up (webview + url connection, same url = no good!)
    [_urlConnection cancel];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

@end
