//
//  AppDelegate.m
//  PostVideo
//
//  Created by zmw on 16/6/30.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "AppDelegate.h"
#import "TableViewController.h"
#import <KS3YunSDK/KS3YunSDK.h>

NSString * const strAccessKey = @"ZHfrDw0iuxQpojtnvhVQ";
NSString * const strSecretKey = @"V3fxcnw1ek7wcj6TUpwlEnMnH73eEkLUK/hx+5EE";
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[KS3Client initialize] connectWithAccessKey:strAccessKey withSecretKey:strSecretKey];
    [[KS3Client initialize] setBucketDomainWithRegion:KS3BucketBeijing];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    /**
     *  这里移动要注意，条件判断成功的是在播放器播放过程中返回的
     下面的是播放器没有弹出来的所支持的设备方向
     */
    if (self.playerView)
    {
        return self.playerView.supportInterOrtation;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}
@end
