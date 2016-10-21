//
//  AppDelegate.m
//  TCShow
//
//  Created by AlexiChen on 16/4/11.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


+ (instancetype)sharedAppDelegate
{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)configAppLaunch
{
    [IMAPlatform configHostClass:[TCShowHost class]];
    [[NSClassFromString(@"UICalloutBarButton") appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#if kIsIMAAppFromBase
#else
// 一般用户自己App都会重写该方法
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configAppLaunch];
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}
#endif

- (void)enterMainUI
{
    NSNumber *has = [[NSUserDefaults standardUserDefaults] objectForKey:@"HasReadUserProtocol"];
    if (!has || !has.boolValue)
    {
        UserProtocolViewController *vc = [[UserProtocolViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nav;
        return;
    }
    
    
    self.window.rootViewController = [[TarBarController alloc] init];
}
@end
