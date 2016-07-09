//
//  PlayerView.m
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "PlayerView.h"
#import "PlayerMenuView.h"
#import <Masonry.h>
#import <libksygpulive/libksygpulive.h>
#import "UCloudDanmuParser.h"

@interface PlayerView()<PlayerMenuViewDelegate, UCloudDanmuTime>
@property (strong, nonatomic) PlayerMenuView *menuView;
@property (strong, nonatomic) KSYMoviePlayerController *player;
@property (strong, nonatomic) NSURL *url;

@property (assign, nonatomic) BOOL isFullScreen;
@property (assign, nonatomic) float minHeight;
@property (assign, nonatomic) float minWidth;
@property (strong, nonatomic) UCloudDanmuParser *danmuParser;
@end

@implementation PlayerView
- (id)initWithFrame:(CGRect)frame url:(NSURL *)url
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initDanmu];
        [self initUI];
        self.url = url;
        self.minHeight = frame.size.height;
        self.minWidth = frame.size.width;
        self.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)initUI
{
    self.menuView = [[PlayerMenuView alloc] initWithFrame:self.frame];
    self.menuView.delegate = self;
    [self addSubview:self.menuView];
    
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 2.f;
    
    self.menuView.layer.borderColor = [UIColor greenColor].CGColor;
    self.menuView.layer.borderWidth = 2.f;
}

- (void)initDanmu
{
    self.danmuParser = [[UCloudDanmuParser alloc] init];
    self.danmuParser.delegate = self;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xml"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [self.danmuParser startWithFileUrl:url orFileData:nil showInView:self completion:^(BOOL result, id error) {
        [self.danmuParser danMuRestart];
    }];
}

#pragma mark - PlayerMenuViewDelegate
- (void)clickPlayOrPauseBtn:(UIButton *)btn playing:(BOOL)isPlaying
{
    if (self.player)
    {
        if (isPlaying)
        {
            [self.player play];
            [self.danmuParser danMuResume];
            [self bringSubviewToFront:self.menuView];
        }
        else
        {
            [self.player pause];
            [self.danmuParser danMuPause];
            [self bringSubviewToFront:self.menuView];
        }
    }
    else
    {
        [self initPlayer];
    }
}

- (void)sliderValueChange:(UISlider *)slider value:(float)value
{
    float duration = self.player.duration;
    float current = duration*value;
    [self.player setCurrentPlaybackTime:current];
}

- (void)clickBackBtn:(UIButton *)btn
{
    [self stopVideo];
    [self.danmuParser danMuStop];
    if (self.isFullScreen)
    {
        __weak typeof(self) weakSelf = self;
        [self clickFullScreenBtn:btn completion:^{
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(playerView:clickBack:)])
            {
                [weakSelf.delegate playerView:weakSelf clickBack:btn];
            }
        }];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:clickBack:)])
        {
            [self.delegate playerView:self clickBack:btn];
        }
    }
}

- (void)clickFullScreenBtn:(UIButton *)btn completion:(void(^)(void))completion
{
    __weak typeof(self) weakSelf = self;
    [self.player pause];
    if(!self.isFullScreen)
    {
        UIDeviceOrientation deviceOr = [UIDevice currentDevice].orientation;
        if (deviceOr == UIInterfaceOrientationLandscapeRight)
        {
            self.supportInterOrtation = UIInterfaceOrientationMaskLandscapeRight;
            [self awakeSupportInterOrtation:self.showVC completion:^{
                weakSelf.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                weakSelf.player.view.bounds = self.bounds;
                weakSelf.menuView.frame = self.bounds;
                [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
                [weakSelf.player play];
                [weakSelf bringSubviewToFront:weakSelf.menuView];
                if (completion)
                {
                    completion();
                }
            }];
        }
        else
        {
            self.supportInterOrtation = UIInterfaceOrientationMaskLandscapeLeft;
            [self awakeSupportInterOrtation:self.showVC completion:^() {
                weakSelf.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                weakSelf.player.view.bounds = self.bounds;
                weakSelf.menuView.frame = self.bounds;
                [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
                [weakSelf.player play];
                [weakSelf bringSubviewToFront:weakSelf.menuView];
                if (completion)
                {
                    completion();
                }
            }];
        }
    }
    else
    {
        self.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        [self awakeSupportInterOrtation:self.showVC completion:^() {
            weakSelf.frame = CGRectMake(0, 0, self.minWidth, self.minHeight);
            weakSelf.player.view.bounds = self.bounds;
            weakSelf.menuView.frame = self.bounds;
            [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
            [weakSelf.player play];
            [weakSelf bringSubviewToFront:weakSelf.menuView];
            if (completion)
            {
                completion();
            }
        }];
    }
    
    self.isFullScreen = !self.isFullScreen;
}

#pragma mark - Player
-(void)handlePlayerNotify:(NSNotification*)notify
{
    if (!_player)
    {
        return;
    }
    if (MPMediaPlaybackIsPreparedToPlayDidChangeNotification ==  notify.name)
    {
        //        stat.text = [NSString stringWithFormat:@"player prepared"];
        // using autoPlay to start live stream
        //        [_player play];
        NSString *serverIp = [_player serverAddress];
        NSLog(@"KSYPlayerVC: %@ -- ip:%@", _url, serverIp);
    }
    if (MPMoviePlayerPlaybackStateDidChangeNotification ==  notify.name)
    {
        NSLog(@"------------------------");
        NSLog(@"player playback state: %ld", (long)_player.playbackState);
        NSLog(@"------------------------");
    }
    if (MPMoviePlayerLoadStateDidChangeNotification ==  notify.name)
    {
        NSLog(@"player load state: %ld", (long)_player.loadState);
        if (MPMovieLoadStateStalled & _player.loadState)
        {
            //            stat.text = [NSString stringWithFormat:@"player start caching"];
            NSLog(@"player start caching");
        }
        
        if (_player.bufferEmptyCount && (MPMovieLoadStatePlayable & _player.loadState || MPMovieLoadStatePlaythroughOK & _player.loadState))
        {
            NSLog(@"player finish caching");
            NSString *message = [[NSString alloc]initWithFormat:@"loading occurs, %d - %0.3fs", (int)_player.bufferEmptyCount, _player.bufferEmptyDuration];
            [self toast:message];
        }
    }
    if (MPMoviePlayerPlaybackDidFinishNotification ==  notify.name)
    {
        NSLog(@"player finish state: %ld", (long)_player.playbackState);
        NSLog(@"player download flow size: %f MB", _player.readSize);
        NSLog(@"buffer monitor  result: \n   empty count: %d, lasting: %f seconds",
              (int)_player.bufferEmptyCount,
              _player.bufferEmptyDuration);
        int reason = [[[notify userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
        if (reason ==  MPMovieFinishReasonPlaybackEnded)
        {
            //            stat.text = [NSString stringWithFormat:@"player finish"];
        }
        else if (reason == MPMovieFinishReasonPlaybackError)
        {
            //            stat.text = [NSString stringWithFormat:@"player Error : %@", [[notify userInfo] valueForKey:@"error"]];
        }
        else if (reason == MPMovieFinishReasonUserExited)
        {
            //            stat.text = [NSString stringWithFormat:@"player userExited"];
        }
    }
    if (MPMovieNaturalSizeAvailableNotification ==  notify.name)
    {
        NSLog(@"video size %.0f-%.0f", _player.naturalSize.width, _player.naturalSize.height);
    }
    if (MPMoviePlayerFirstVideoFrameRenderedNotification == notify.name)
    {
        //        int fvr_costtime = (int)((long long int)([self getCurrentTime] * 1000) - prepared_time);
        //        NSLog(@"first video frame show, cost time : %dms!\n", fvr_costtime);
    }
    
    if (MPMoviePlayerFirstAudioFrameRenderedNotification == notify.name)
    {
        //        far_costtime = (int)((long long int)([self getCurrentTime] * 1000) - prepared_time);
        //        NSLog(@"first audio frame render, cost time : %dms!\n", far_costtime);
    }
    
    if (MPMoviePlayerSuggestReloadNotification == notify.name)
    {
        NSLog(@"suggest using reload function!\n");
    }
}
- (void) toast:(NSString*)message
{
    UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil, nil];
    [toast show];
    
    double duration = 0.5; // duration in seconds
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
}

- (void)setupObservers
{
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMediaPlaybackIsPreparedToPlayDidChangeNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerPlaybackStateDidChangeNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerPlaybackDidFinishNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerLoadStateDidChangeNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMovieNaturalSizeAvailableNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerFirstVideoFrameRenderedNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerFirstAudioFrameRenderedNotification)
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(handlePlayerNotify:)
                                                name:(MPMoviePlayerSuggestReloadNotification)
                                              object:nil];
}

- (void)releaseObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerPlaybackDidFinishNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerLoadStateDidChangeNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMovieNaturalSizeAvailableNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerFirstVideoFrameRenderedNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerFirstAudioFrameRenderedNotification
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:MPMoviePlayerSuggestReloadNotification
                                                 object:nil];
}
- (void)initPlayer
{
    if (_player)
    {
        return;
    }
    _player = [[KSYMoviePlayerController alloc] initWithContentURL: _url];
    
    _player.logBlock = ^(NSString *logJson)
    {
        NSLog(@"logJson is %@",logJson);
    };
    
    _player.controlStyle = MPMovieControlStyleNone;
    [_player.view setFrame: self.bounds];  // player's frame must match parent's
    [self addSubview: _player.view];
    
    [self sendSubviewToBack:_player.view];
    self.autoresizesSubviews = TRUE;
    _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _player.shouldAutoplay = TRUE;
//    _player.shouldEnableVideoPostProcessing = TRUE;
    _player.scalingMode = MPMovieScalingModeAspectFit;
    _player.shouldEnableKSYStatModule = TRUE;
    _player.shouldUseHWCodec = YES;
    _player.shouldLoop = NO;
    NSKeyValueObservingOptions opts = NSKeyValueObservingOptionNew;
    [_player addObserver:self forKeyPath:@"currentPlaybackTime" options:opts context:nil];
    [_player prepareToPlay];
    
    NSLog(@"version:%@", [self.player getVersion]);
}
- (void)reloadVideo
{
    if (_player)
    {
        [_player reload:_url is_flush:FALSE];
    }
}

- (void)stopVideo
{
    if (_player)
    {
        NSLog(@"player download flow size: %f MB", _player.readSize);
        NSLog(@"buffer monitor  result: \n   empty count: %d, lasting: %f seconds", (int)_player.bufferEmptyCount, _player.bufferEmptyDuration);
        [_player stop];
        [_player removeObserver:self forKeyPath:@"currentPlaybackTime" context:nil];
        [_player.view removeFromSuperview];
        _player = nil;
        [self removeFromSuperview];
    }
}

- (void)rotate:(float)degress
{
    if (_player)
    {
        _player.rotateDegress = degress;
    }
}

- (void)changeContentMode
{
    MPMovieScalingMode content_mode = self.player.scalingMode;
    content_mode++;
    if(content_mode > MPMovieScalingModeFill)
        content_mode = MPMovieScalingModeNone;
    if (_player)
    {
        _player.scalingMode = content_mode;
    }
}

- (void)remoteControlReceivedWithEvent: (UIEvent *) receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl)
    {
        switch (receivedEvent.subtype)
        {
            case UIEventSubtypeRemoteControlPlay:
                [_player play];
                NSLog(@"play");
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [_player pause];
                NSLog(@"pause");
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                
                break;
                
            default:
                break;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"currentPlaybackTime"] )
    {
        NSTimeInterval position = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        NSLog(@">>>>>>>>>>>>>>>>> current playback position:%.1fs\n", position);
        
        float progress = position/self.player.duration;
        [self.menuView updateProgress:progress];
        
        float duration = self.player.duration;
        NSInteger leave = duration - position;
        NSString *time = [NSString stringWithFormat:@"%02d:%02d", (int)(leave / 60), (int)(leave % 60)];
        [self.menuView updateTimeLabel:time];
    }
}

#pragma mark - 屏幕旋转
- (void)awakeSupportInterOrtation:(UIViewController *)showVC completion:(void(^)(void))block
{
    UIViewController *vc = [[UIViewController alloc] init];
    void(^completion)() = ^() {
        [showVC dismissViewControllerAnimated:NO completion:nil];
        
        if (block)
        {
            block();
        }
    };
    
    // This check is needed if you need to support iOS version older than 7.0
    BOOL canUseTransitionCoordinator = [showVC respondsToSelector:@selector(transitionCoordinator)];
    BOOL animated = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0)
    {
        animated = NO;
    }
    else
    {
        animated = YES;
    }
    if (canUseTransitionCoordinator)
    {
        [showVC presentViewController:vc animated:animated completion:nil];
        [showVC.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            completion();
        }];
    }
    else
    {
        [showVC presentViewController:vc animated:NO completion:completion];
    }
}

#pragma mark - UCloudDanmuTime
- (NSTimeInterval)getCurrentTime
{
    return self.player.currentPlaybackTime;
}
@end
