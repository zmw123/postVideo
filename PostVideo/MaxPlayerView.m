//
//  MaxPlayerView.m
//  PostVideo
//
//  Created by zmw on 16/7/11.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "MaxPlayerView.h"
#import "ZXVideoPlayerControlView.h"
#import <libksygpulive/libksygpulive.h>
#import "UCloudDanmuParser.h"

typedef NS_ENUM(NSInteger, ZXPanDirection){
    ZXPanDirectionHorizontal, // 横向移动
    ZXPanDirectionVertical,   // 纵向移动
};

/// 播放器显示和消失的动画时长
static const CGFloat kVideoPlayerControllerAnimationTimeInterval = 0.3f;

@interface MaxPlayerView() <UIGestureRecognizerDelegate, UCloudDanmuTime>
/// 播放器视图
@property (nonatomic, strong) ZXVideoPlayerControlView *videoControl;
/// 是否已经全屏模式
@property (nonatomic, assign) BOOL isFullscreenMode;
/// 是否锁定
@property (nonatomic, assign) BOOL isLocked;
/// 设备方向
@property (nonatomic, assign, readonly, getter=getDeviceOrientation) UIDeviceOrientation deviceOrientation;
/// player duration timer
@property (nonatomic, strong) NSTimer *durationTimer;
/// pan手势移动方向
@property (nonatomic, assign) ZXPanDirection panDirection;
/// 快进退的总时长
@property (nonatomic, assign) CGFloat sumTime;
/// 是否在调节音量
@property (nonatomic, assign) BOOL isVolumeAdjust;
/// 系统音量slider
@property (nonatomic, strong) UISlider *volumeViewSlider;

@property (nonatomic, strong) NSURL *url;
@property (strong, nonatomic) KSYMoviePlayerController *player;
@property (assign, nonatomic) float minHeight;
@property (assign, nonatomic) float minWidth;
@property (strong, nonatomic) UCloudDanmuParser *danmuParser;
@end

@implementation MaxPlayerView
#pragma mark - life cycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor blackColor];
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.layer.borderWidth = 2.f;
        [self addSubview:self.videoControl];
        self.videoControl.frame = self.bounds;
        self.url = url;
        
        self.minHeight = frame.size.height;
        self.minWidth = frame.size.width;
        self.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
        pan.delegate = self;
        [self.videoControl addGestureRecognizer:pan];
        
//        [self configPlayer];
        [self configObserver];
        [self configControlFrame:frame];
        [self configControlAction];
        [self configVolume];
        [self configDanmu];
    }
    return self;
}

#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if([touch.view isKindOfClass:[UISlider class]] || [touch.view isKindOfClass:[UIButton class]] || [touch.view.accessibilityIdentifier isEqualToString:@"TopBar"]) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark - Public Method
/// 展示播放器
- (void)showInView:(UIView *)view
{
    if ([UIApplication sharedApplication].statusBarStyle !=  UIStatusBarStyleLightContent) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    [view addSubview:self];
    
    self.alpha = 0.0;
    [UIView animateWithDuration:kVideoPlayerControllerAnimationTimeInterval animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {}];
}

#pragma mark -
#pragma mark - Private Method
- (void)configDanmu
{
    self.danmuParser = [[UCloudDanmuParser alloc] init];
    self.danmuParser.delegate = self;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xml"];
    NSURL *url = [NSURL fileURLWithPath:path];
    __weak typeof(self) weakSelf = self;
    [self.danmuParser startWithFileUrl:url orFileData:nil showInView:self completion:^(BOOL result, id error) {
        [weakSelf.danmuParser danMuRestart];
        [weakSelf bringSubviewToFront:weakSelf.videoControl];
    }];
}

- (void)configControlFrame:(CGRect)frame
{
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}
/// 控件点击事件
- (void)configControlAction
{
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.lockButton addTarget:self action:@selector(lockButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    // slider
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchCancel];
    
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}

/// 开始播放时根据视频文件长度设置slider最值
- (void)setProgressSliderMaxMinValues
{
    CGFloat duration = self.player.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = floor(duration);
}

/// 监听播放进度
- (void)monitorVideoPlayback
{
    double currentTime = floor(self.player.currentPlaybackTime);
    double totalTime = floor(self.player.duration);
    // 更新时间
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    // 更新播放进度
    self.videoControl.progressSlider.value = ceil(currentTime);
    // 更新缓冲进度
    self.videoControl.bufferProgressView.progress = self.player.playableDuration / self.player.duration;
}

/// 更新播放时间显示
- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime
{
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);
    double secondsRemaining = floor(fmod(totalTime, 60.0));
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

/// 开启定时器
- (void)startDurationTimer
{
    if (self.durationTimer)
    {
        [self.durationTimer setFireDate:[NSDate date]];
    }
    else
    {
        self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSRunLoopCommonModes];
    }
}

/// 暂停定时器
- (void)stopDurationTimer
{
    if (_durationTimer)
    {
        [self.durationTimer setFireDate:[NSDate distantFuture]];
    }
}

/// 控制视图隐藏
- (void)onPayerControlViewHideNotification
{
    if (self.isFullscreenMode)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
}

/// MARK: pan手势处理

/// pan手势触发
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    CGPoint locationPoint = [pan locationInView:self.videoControl];
    CGPoint veloctyPoint = [pan velocityInView:self.videoControl];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: { // 开始移动
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            
            if (x > y)
            { // 水平移动
                self.panDirection = ZXPanDirectionHorizontal;
                self.sumTime = self.player.currentPlaybackTime; // sumTime初值
                [self pause];
                [self stopDurationTimer];
            }
            else if (x < y)
            { // 垂直移动
                self.panDirection = ZXPanDirectionVertical;
                if (locationPoint.x > self.bounds.size.width / 2)
                { // 音量调节
                    self.isVolumeAdjust = YES;
                } else
                { // 亮度调节
                    self.isVolumeAdjust = NO;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged: { // 正在移动
            switch (self.panDirection) {
                case ZXPanDirectionHorizontal:
                {
                    [self horizontalMoved:veloctyPoint.x];
                }
                    break;
                case ZXPanDirectionVertical:
                {
                    [self verticalMoved:veloctyPoint.y];
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
        case UIGestureRecognizerStateEnded: { // 移动停止
            switch (self.panDirection) {
                case ZXPanDirectionHorizontal:
                {
                    [self.player setCurrentPlaybackTime:floor(self.sumTime)];
                    [self play];
                    [self startDurationTimer];
                    [self.videoControl autoFadeOutControlBar];
                }
                    break;
                case ZXPanDirectionVertical:
                {
                    break;
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        default:
            break;
    }
}

/// pan水平移动
- (void)horizontalMoved:(CGFloat)value
{
    // 每次滑动叠加时间
    self.sumTime += value / 200;
    
    // 容错处理
    if (self.sumTime > self.player.duration)
    {
        self.sumTime = self.player.duration;
    }
    else if (self.sumTime < 0)
    {
        self.sumTime = 0;
    }
    
    // 时间更新
    double currentTime = self.sumTime;
    double totalTime = self.player.duration;
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    // 提示视图
    self.videoControl.timeIndicatorView.labelText = self.videoControl.timeLabel.text;
    // 播放进度更新
    self.videoControl.progressSlider.value = self.sumTime;
    
    // 快进or后退 状态调整
    ZXTimeIndicatorPlayState playState = ZXTimeIndicatorPlayStateRewind;
    
    if (value < 0)
    { // left
        playState = ZXTimeIndicatorPlayStateRewind;
    }
    else if (value > 0)
    { // right
        playState = ZXTimeIndicatorPlayStateFastForward;
    }
    
    if (self.videoControl.timeIndicatorView.playState != playState)
    {
        if (value < 0)
        { // left
            NSLog(@"------fast rewind");
            self.videoControl.timeIndicatorView.playState = ZXTimeIndicatorPlayStateRewind;
            [self.videoControl.timeIndicatorView setNeedsLayout];
        }
        else if (value > 0)
        { // right
            NSLog(@"------fast forward");
            self.videoControl.timeIndicatorView.playState = ZXTimeIndicatorPlayStateFastForward;
            [self.videoControl.timeIndicatorView setNeedsLayout];
        }
    }
}


/// pan垂直移动
- (void)verticalMoved:(CGFloat)value
{
    if (self.isVolumeAdjust)
    {
        // 调节系统音量
        // [MPMusicPlayerController applicationMusicPlayer].volume 这种简单的方式调节音量也可以，只是CPU高一点点
        self.volumeViewSlider.value -= value / 10000;
    }
    else
    {
        // 亮度
        [UIScreen mainScreen].brightness -= value / 10000;
    }
}

/// MARK: 系统音量控件

/// 获取系统音量控件
- (void)configVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.center = CGPointMake(-1000, 0);
    [self addSubview:volumeView];
    
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
    
    if (!success) {/* error */}
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

/// 耳机插入、拔出事件
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSInteger routeChangeReason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason)
    {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"---耳机插入");
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            NSLog(@"---耳机拔出");
            // 拔掉耳机继续播放
            [self play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
            
        default:
            break;
    }
}

/// 切换到全屏模式
- (void)changeToFullScreenForOrientation:(UIDeviceOrientation)orientation
{
    if (self.isFullscreenMode)
    {
        return;
    }
    
    if (self.videoControl.isBarShowing)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
    
    if (self.videoPlayerWillChangeToFullScreenModeBlock)
    {
        self.videoPlayerWillChangeToFullScreenModeBlock();
    }
    
    self.frame = [UIScreen mainScreen].bounds;
    
    self.isFullscreenMode = YES;
    self.videoControl.fullScreenButton.hidden = YES;
    self.videoControl.shrinkScreenButton.hidden = NO;
}

/// 切换到竖屏模式
- (void)restoreOriginalScreen
{
    if (!self.isFullscreenMode)
    {
        return;
    }
    
    if ([UIApplication sharedApplication].statusBarHidden)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    
    if (self.videoPlayerWillChangeToOriginalScreenModeBlock)
    {
        self.videoPlayerWillChangeToOriginalScreenModeBlock();
    }
    
    self.frame = CGRectMake(0, 0, kZXVideoPlayerOriginalWidth, kZXVideoPlayerOriginalHeight);
    
    self.isFullscreenMode = NO;
    self.videoControl.fullScreenButton.hidden = NO;
    self.videoControl.shrinkScreenButton.hidden = YES;
}

#pragma mark -
#pragma mark - Action Code

/// 返回按钮点击
- (void)backButtonClick
{
    if (!self.isFullscreenMode)
    { // 如果是竖屏模式，返回关闭
        if (self)
        {
            [self.durationTimer invalidate];
            [self stop];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            
            if (self.videoPlayerGoBackBlock)
            {
                [self.videoControl cancelAutoFadeOutControlBar];
                self.videoPlayerGoBackBlock();
            }
        }
    }
    else
    { // 全屏模式，返回到竖屏模式
        if (self.isLocked)
        { // 解锁
            [self lockButtonClick:self.videoControl.lockButton];
        }
        [self shrinkScreenButtonClick];
    }
}

/// 播放按钮点击
- (void)playButtonClick
{
    if (!self.player)
    {
        [self configPlayer];
    }
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
}

/// 暂停按钮点击
- (void)pauseButtonClick
{
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}

/// 锁屏按钮点击
- (void)lockButtonClick:(UIButton *)lockBtn
{
    lockBtn.selected = !lockBtn.selected;
    
    if (lockBtn.selected)
    { // 锁定
        self.isLocked = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"ZXVideoPlayer_DidLockScreen"];
    }
    else
    { // 解除锁定
        self.isLocked = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"ZXVideoPlayer_DidLockScreen"];
    }
}

/// 全屏按钮点击
- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode)
    {
        return;
    }
    
    if (self.isLocked)
    { // 解锁
        [self lockButtonClick:self.videoControl.lockButton];
    }
    
    self.videoControl.fullScreenButton.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [self clickFullScreen:YES completion:^{
        weakSelf.videoControl.fullScreenButton.enabled = YES;
        weakSelf.isFullscreenMode = YES;
        weakSelf.videoControl.fullScreenButton.hidden = YES;
        weakSelf.videoControl.shrinkScreenButton.hidden = NO;
    }];
}

/// 返回竖屏按钮点击
- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode)
    {
        return;
    }
    
    if (self.isLocked)
    { // 解锁
        [self lockButtonClick:self.videoControl.lockButton];
    }
    
    self.videoControl.shrinkScreenButton.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [self clickFullScreen:NO completion:^{
        weakSelf.videoControl.shrinkScreenButton.enabled = YES;
        weakSelf.isFullscreenMode = NO;
        weakSelf.videoControl.fullScreenButton.hidden = NO;
        weakSelf.videoControl.shrinkScreenButton.hidden = YES;
    }];
}

/// slider 按下事件
- (void)progressSliderTouchBegan:(UISlider *)slider
{
    [self pause];
    [self stopDurationTimer];
    [self.videoControl cancelAutoFadeOutControlBar];
}

/// slider 松开事件
- (void)progressSliderTouchEnded:(UISlider *)slider
{
    [self.player setCurrentPlaybackTime:floor(slider.value)];
    [self.danmuParser danMuStop];
    [self.danmuParser danMuResume];
    [self play];
    [self startDurationTimer];
    [self.videoControl autoFadeOutControlBar];
}

/// slider value changed
- (void)progressSliderValueChanged:(UISlider *)slider
{
    double currentTime = floor(slider.value);
    double totalTime = floor(self.player.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

#pragma mark -
#pragma mark - getters and setters
- (ZXVideoPlayerControlView *)videoControl
{
    if (!_videoControl)
    {
        _videoControl = [[ZXVideoPlayerControlView alloc] init];
    }
    return _videoControl;
}

- (UIDeviceOrientation)getDeviceOrientation
{
    return [UIDevice currentDevice].orientation;
}

#pragma mark - fullScreen
- (void)clickFullScreen:(BOOL)fullScreen completion:(void(^)(void))completion
{
    __weak typeof(self) weakSelf = self;
    [self.player pause];
    if(fullScreen)
    {
        UIDeviceOrientation deviceOr = [UIDevice currentDevice].orientation;
        if (deviceOr == UIInterfaceOrientationLandscapeRight)
        {
            self.supportInterOrtation = UIInterfaceOrientationMaskLandscapeRight;
            [self awakeSupportInterOrtation:self.showVC completion:^{
                weakSelf.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                weakSelf.player.view.bounds = self.bounds;
                weakSelf.videoControl.frame = self.bounds;
                [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
                [weakSelf.player play];
                [weakSelf bringSubviewToFront:weakSelf.videoControl];
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
                weakSelf.videoControl.frame = self.bounds;
                [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
                [weakSelf.player play];
                [weakSelf bringSubviewToFront:weakSelf.videoControl];
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
            weakSelf.videoControl.frame = self.bounds;
            [weakSelf.danmuParser resetDanmuWithFrame:self.bounds];
            [weakSelf.player play];
            [weakSelf bringSubviewToFront:weakSelf.videoControl];
            if (completion)
            {
                completion();
            }
        }];
    }
}

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

#pragma mark -
#pragma mark - player
- (void)configPlayer
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
    _player.scalingMode = MPMovieScalingModeAspectFit;
    _player.shouldEnableKSYStatModule = TRUE;
    _player.shouldUseHWCodec = YES;
    _player.shouldLoop = NO;
    [_player prepareToPlay];
    
    NSLog(@"version:%@", [self.player getVersion]);
}

- (void)pause
{
    [self.player pause];
    [self.danmuParser danMuPause];
}

- (void)play
{
    [self.player play];
    [self.danmuParser danMuResume];
}

- (void)stop
{
    [self.player stop];
    [self.danmuParser danMuStop];
}

-(void)handlePlayerNotify:(NSNotification*)notify
{
    if (!_player)
    {
        return;
    }
    if (MPMediaPlaybackIsPreparedToPlayDidChangeNotification ==  notify.name)
    {
        NSString *serverIp = [_player serverAddress];
        NSLog(@"KSYPlayerVC: %@ -- ip:%@:%f", _url, serverIp, self.player.duration);
        [self startDurationTimer];
        [self setProgressSliderMaxMinValues];
        
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
    }
    if (MPMoviePlayerPlaybackStateDidChangeNotification ==  notify.name)
    {
        if (self.player.playbackState == MPMoviePlaybackStatePlaying)
        {
            self.videoControl.pauseButton.hidden = NO;
            self.videoControl.playButton.hidden = YES;
            [self startDurationTimer];
            
            [self.videoControl.indicatorView stopAnimating];
            [self.videoControl autoFadeOutControlBar];
        }
        else
        {
            self.videoControl.pauseButton.hidden = YES;
            self.videoControl.playButton.hidden = NO;
            [self stopDurationTimer];
            if (self.player.playbackState == MPMoviePlaybackStateStopped)
            {
                [self.videoControl animateShow];
            }
        }

    }
    if (MPMoviePlayerLoadStateDidChangeNotification ==  notify.name)
    {
        NSLog(@"player load state: %ld", (long)_player.loadState);
        if (MPMovieLoadStateStalled & _player.loadState)
        {
            NSLog(@"player start caching");
            [self.videoControl.indicatorView startAnimating];
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
        
    }
    
    if (MPMoviePlayerFirstAudioFrameRenderedNotification == notify.name)
    {
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

- (void)configObserver
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPayerControlViewHideNotification) name:kZXPlayerControlViewHideNotification object:nil];
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
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:kZXPlayerControlViewHideNotification
                                                 object:nil];
}
#pragma mark - UCloudDanmuTime

- (NSTimeInterval)getCurrentTime
{
    return self.player.currentPlaybackTime;
}
@end
