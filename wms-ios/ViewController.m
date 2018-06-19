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

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UIWebView *webView;

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
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //            [self playSoundName:@"wrong01.wav"];
        });
    });
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
        if([qrscanDes isEqualToString:@"我想调用app原生扫描二维码/条码"]) {
            
            [self scanQRCode];
        }else if([qrscanDes isEqualToString:@"我想播放警告音"]) {
            
            [self playSoundName:@"wrong01.wav"];
        }
        NSLog(@"%@",qrscanDes);
    };
}


#pragma mark - 功能函数

// 跳到扫码控制器
- (void)skipScan {
    
    ScanCodeViewController *vc = [[ScanCodeViewController alloc] init];
    vc.webView = self.webView;
    [self presentViewController:vc animated:YES completion:nil];
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
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请去-> [设置 - 隐私 - 相机 - 雪花(订单)] 打开访问开关" preferredStyle:(UIAlertControllerStyleAlert)];
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
