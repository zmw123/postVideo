//
//  PlayerViewController.m
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"
#import <Masonry.h>
#import "AppDelegate.h"
@interface PlayerViewController()<PlayerViewDelegate>
@property (strong, nonatomic) PlayerView *playerView;
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
    self.playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width) url:self.url];
    self.playerView.delegate = self;
    self.playerView.showVC = self;
    [self.view addSubview:self.playerView];
    
    AppDelegate *del = [UIApplication sharedApplication].delegate;
    del.playerView = self.playerView;
}

- (void)playerView:(PlayerView *)view clickBack:(UIButton *)btn
{
    [view removeFromSuperview];
    self.playerView = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.playerView)
    {
        return self.playerView.supportInterOrtation;
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
