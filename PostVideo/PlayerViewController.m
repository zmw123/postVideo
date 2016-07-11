//
//  PlayerViewController.m
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "PlayerViewController.h"
#import <Masonry.h>
#import "AppDelegate.h"
#import "MaxPlayerView.h"


@interface PlayerViewController()

@property (strong, nonatomic) MaxPlayerView *maxView;
@property (strong, nonatomic) NSArray *data;
@end
@implementation PlayerViewController
- (id)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        _url = url;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.maxView = [[MaxPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width) url:self.url];
    self.maxView.showVC = self;
    __weak typeof(self) weakSelf = self;
    self.maxView.videoPlayerGoBackBlock = ^{
        __strong typeof(self) strongSelf = weakSelf;
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            
        }];
        [strongSelf.navigationController setNavigationBarHidden:NO animated:YES];
        
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"ZXVideoPlayer_DidLockScreen"];
        
        strongSelf.maxView = nil;
    };
    
    self.maxView.videoPlayerWillChangeToOriginalScreenModeBlock = ^(){
        NSLog(@"切换为竖屏模式");
    };
    self.maxView .videoPlayerWillChangeToFullScreenModeBlock = ^(){
        NSLog(@"切换为全屏模式");
    };
    [self.maxView showInView:self.view];
    
    AppDelegate *del = [UIApplication sharedApplication].delegate;
    del.playerView = self.maxView;
}

- (void)play
{
    self.maxView = [[MaxPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width) url:self.url];
    self.maxView.showVC = self;
    [self.maxView showInView:self.view];
}


-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.maxView)
    {
        return self.maxView.supportInterOrtation;
    }
    else
    {
        /**
         *  这个在播放之外的程序支持的设备方向
         */
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
