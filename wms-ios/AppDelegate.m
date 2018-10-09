//
//  AppDelegate.m
//  wms-ios
//
//  Created by wenwang wang on 2018/6/19.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "AppDelegate.h"
#import <WXApi.h>
#import <AFNetworking.h>
#import "NSString+toDict.h"
#import "NSDictionary+toString.h"
#import "ViewController.h"

@interface AppDelegate ()<WXApiDelegate>

@property (weak, nonatomic) UIWebView *webView;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    [WXApi registerApp:@"wxf1af3db4c541e417"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWebView:) name:kReceive_WebView_Notification object:nil];
    return YES;
}


- (void)receiveWebView:(NSNotification *)aNotification {
    
    _webView = aNotification.userInfo[@"webView"];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [WXApi handleOpenURL:url delegate:self];
}

// 授权回调的结果
- (void)onResp:(BaseResp *)resp {
    
    NSLog(@"resp:%d", resp.errCode);
    
    if([resp isKindOfClass:[SendAuthResp class]]) {
        
        SendAuthResp *rep = (SendAuthResp *)resp;
        if(resp.errCode == -2) {
            
            NSLog(@"用户取消");
        }else if(resp.errCode == -4) {
            
            NSLog(@"用户拒绝授权");
        }else {
            
            NSString *code = rep.code;
            NSString *appid = @"wxf1af3db4c541e417";
            NSString *appsecret = @"ecc5d4852c173e928fe48aa8b6334110";
            NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", appid, appsecret, code];
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                NSDictionary *result = [[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
                NSString *access_token = result[@"access_token"];
                NSString *openid = result[@"openid"];
                [self wxLogin:access_token andOpenid:openid];
                NSLog(@"请求access_token成功");
                [self RFWeixinLogin:openid];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                NSLog(@"请求access_token失败");
            }];
        }
    }
}


// 获取wms用户信息
- (void)RFWeixinLogin:(NSString *)openid {
    
//    openid = @"o13ss00CRgONcueMcdllF4taidso";
    NSString *WarehouseCode = @"";
    NSString *UserID = @"";
    
    NSString *params = [NSString stringWithFormat:@"{\"OpenId\":\"%@\"}", openid];
    NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"https://scm.cy-scm.com/wms/RFWeixinLogin.do?WarehouseCode=%@&UserID=%@&params=%@", WarehouseCode, UserID, paramsEncoding];
    NSLog(@"请求wms用户信息参数：%@",url);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:@"cyscm" forHTTPHeaderField:@"AuthCode"];
    [manager.requestSerializer setValue:@"" forHTTPHeaderField:@"AuthID"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *result = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
        
        int status = [result[@"status"] intValue];
        id data = result[@"data"];
        NSString *Msg = result[@"Msg"];
        
        if(status == 1) {
            if([data isKindOfClass:[NSString class]]) {
                
                NSString *jsStr = [NSString stringWithFormat:@"WXBind_NO_Ajax('%@')",openid];
                NSLog(@"%@",jsStr);
                [_webView stringByEvaluatingJavaScriptFromString:jsStr];
                NSLog(@"微信未注册");
            }else if([data isKindOfClass:[NSArray class]]) {
                
//                NSDictionary *dataDict = data[0];
//                NSString *UserID = dataDict[@"UserID"];
//                NSString *UserName = dataDict[@"UserName"];
//                NSString *TenantCode = dataDict[@"TenantCode"];
//                NSString *WarehouseCode = dataDict[@"WarehouseCode"];
//                NSString *WarehouseName = dataDict[@"WarehouseName"];
//                NSString *jsStr = [NSString stringWithFormat:@"WXBind_YES_Ajax('%@', '%@', '%@', '%@', '%@')", UserID, UserName, TenantCode, WarehouseCode, WarehouseName];
                
                NSString *params = [result toString];
                NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *jsStr = [NSString stringWithFormat:@"WXBind_YES_Ajax('%@')", paramsEncoding];
                NSLog(@"%@",jsStr);
                [_webView stringByEvaluatingJavaScriptFromString:jsStr];
                
                NSLog(@"请求wms用户信息成功");
            }
        } else {
            
            NSLog(@"%@", Msg);
        }
        NSLog(@"%@", result);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"请求wms用户信息失败");
    }];
}


// 获取微信个人信息
- (void)wxLogin:(NSString *)access_token andOpenid:(NSString *)openid {
    
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", access_token, openid];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *result =[[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
        NSLog(@"请求个人信息成功");
        NSLog(@"%@", result);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"请求个人信息失败");
    }];
}

@end



//@implementation NSURLRequest(ViewController)
//+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
//
//    return YES;
//}
//@end

