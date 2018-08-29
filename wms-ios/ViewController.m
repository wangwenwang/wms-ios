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

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
    NSLog(@"zipPath:%@", zipPath);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *unzipPath = [documentpath stringByAppendingPathComponent:@"/test"];
    NSLog(@"unzipPath:%@", unzipPath);
    
    // Unzip
    [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSLog(@"htmlPath:%@", htmlPath);
    
    NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    [self.webView loadHTMLString:htmlString baseURL:url];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addBtn:) name:@"fds" object:nil];
    
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]) {
        
        //微信
        NSLog(@"YESWX");
    }else {
        
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
    
    
    NSString *jsStr = [NSString stringWithFormat:@"QRScanAjax('%@', '%@', '%@', '%@',)" ,@"1" ,@"2" ,@"3" ,@"4"];
    NSLog(@"%@",jsStr);
    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
    return;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
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


@end
