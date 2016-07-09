//
//  PlayerMenuView.m
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "PlayerMenuView.h"
#import "UCloudProgressView.h"
#import <Masonry.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UCloudBrightnessView.h"

#define PlayImageName @"icon_bottomview_play_button_normal.png"
#define PauseImageName @"icon_bottomview_pause_button_normal.png"

typedef NS_ENUM(NSInteger, GesDirection)
{
    Dir_H,
    Dir_V_L,
    Dir_V_R,
};

@interface PlayerMenuView()
@property(strong, nonatomic) UILabel *timeLabel;
@property(strong, nonatomic) UISlider *slider;
@property(strong, nonatomic) UIImageView *playImageView;
@property(strong, nonatomic) UIView *bottomView;

@property(strong, nonatomic) UIButton *backBtn;
@property(strong, nonatomic) UIButton *fullScreenBtn;
@property(strong, nonatomic) UIView *topView;

@property(strong, nonatomic) UCloudBrightnessView *brightnessView;
@property(assign, nonatomic) GesDirection direc;
@property (nonatomic) CGFloat voiceNormal;
@property (nonatomic) CGFloat brightNomal;
@property(assign, nonatomic) BOOL isPlaying;
@end

#define BottomViewH 60
#define PlayBtnLeft 20
#define LabelRight 20
#define PlayBtnDelProgressView 20
#define ProgressViewDelLabel 20
#define ImageW 40

@implementation PlayerMenuView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initUI];
        self.isPlaying = YES;
        self.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
        
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panGes];
    }
    return self;
}

- (void)initUI
{
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [UIColor blackColor];
    self.bottomView.alpha = 0.2;
    [self addSubview:self.bottomView];
    
    self.playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:PlayImageName]];
    self.playImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause:)];
    [self.playImageView addGestureRecognizer:tap];
    [self.bottomView addSubview:self.playImageView];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.timeLabel.text = @"00:00";
    self.timeLabel.textColor = [UIColor whiteColor];
    [self.timeLabel sizeToFit];
    [self.bottomView addSubview:self.timeLabel];
    
    self.slider = [[UISlider alloc] init];
    self.slider.continuous = NO;
    [self.slider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    [self.bottomView addSubview:self.slider];
    
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [UIColor blackColor];
    self.topView.alpha = 0.2;
    [self addSubview:self.topView];
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backBtn setBackgroundImage:[UIImage imageNamed:@"icon_topview_left_button_normal"] forState:UIControlStateNormal];
    [self.backBtn setBackgroundImage:[UIImage imageNamed:@"icon_topview_left__button_selected"] forState:UIControlStateHighlighted];
    [self.backBtn addTarget:self action:@selector(clickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.backBtn];
    
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"icon_topview_right_button_normal"] forState:UIControlStateNormal];
    [self.fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"icon_topview_right_button_selected"] forState:UIControlStateHighlighted];
    [self.fullScreenBtn addTarget:self action:@selector(clickFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.fullScreenBtn];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(0.f);
        make.right.equalTo(self).offset(0.f);
        make.bottom.equalTo(self).offset(0.f);
        make.height.mas_equalTo(BottomViewH);
    }];
    
    [self.playImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView.mas_left).offset(PlayBtnLeft);
        make.centerY.equalTo(self.bottomView.mas_centerY).offset(0.f);
        make.size.mas_equalTo(CGSizeMake(ImageW, ImageW));
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView.mas_right).offset(-LabelRight);
        make.centerY.equalTo(self.bottomView.mas_centerY).offset(0.f);
        make.size.mas_equalTo(self.timeLabel.frame.size);
    }];
    
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomView.mas_centerY).offset(0.f);
        make.left.equalTo(self.playImageView.mas_right).offset(PlayBtnDelProgressView);
        make.right.equalTo(self.timeLabel.mas_left).offset(-ProgressViewDelLabel);
    }];
    
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(0.f);
        make.right.equalTo(self).offset(0.f);
        make.top.equalTo(self).offset(0.f);
        make.height.mas_equalTo(BottomViewH);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView.mas_left).offset(PlayBtnLeft);
        make.centerY.equalTo(self.topView.mas_centerY).offset(0.f);
        make.size.mas_equalTo(CGSizeMake(ImageW, ImageW));
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topView.mas_right).offset(-LabelRight);
        make.centerY.equalTo(self.topView.mas_centerY).offset(0.f);
        make.size.mas_equalTo(CGSizeMake(ImageW, ImageW));
    }];
}

#pragma mark - 外部调用接口
- (void)updateProgress:(float)progress
{
    self.slider.value = progress;
}

- (void)updateTimeLabel:(NSString *)text
{
    self.timeLabel.text = text;
}

#pragma mark - 事件
- (void)playOrPause:(UITapGestureRecognizer *)tap
{
    if (self.isPlaying)
    {
        self.playImageView.image = [UIImage imageNamed:PauseImageName];
    }
    else
    {
        self.playImageView.image = [UIImage imageNamed:PlayImageName];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickPlayOrPauseBtn:playing:)])
    {
        [self.delegate clickPlayOrPauseBtn:self.playImageView playing:self.isPlaying];
    }
    self.isPlaying = !self.isPlaying;
}

- (void)valueChange:(UISlider *)sli
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderValueChange:value:)])
    {
        [self.delegate sliderValueChange:sli value:sli.value];
    }
}

- (void)clickBack:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickBackBtn:)])
    {
        [self.delegate clickBackBtn:btn];
    }
}

- (void)clickFullScreen:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickFullScreenBtn:completion:)])
    {
        [self.delegate clickFullScreenBtn:btn completion:^{
            
        }];
    }
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        [self showOrHiddenMenu];
    }
}

- (void)pan:(UIPanGestureRecognizer *)pan
{
    CGFloat delta = 0.f;
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        self.voiceNormal = [MPMusicPlayerController applicationMusicPlayer].volume;
        self.brightNomal = [UIScreen mainScreen].brightness;
        
        CGPoint point = [pan translationInView:self];
        if (fabs(point.x) < fabs(point.y))
        {
            point = [pan locationInView:self];
            //竖直   音量或者亮度
            if (point.x < self.frame.size.width/2.0)
            {
                //左侧
                self.direc = Dir_V_L;
            }
            else
            {
                //右侧
                self.direc = Dir_V_R;
                if (!self.brightnessView)
                {
                    self.brightnessView = [[UCloudBrightnessView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
                    
                    
                    [self.brightnessView setProgress:[UIScreen mainScreen].brightness];
                }
                UIWindow *window = [UIApplication sharedApplication].keyWindow;
                UIView *superView = self.superview;
                if (CGAffineTransformEqualToTransform(superView.transform, CGAffineTransformIdentity))
                {
                    self.brightnessView.center = window.center;
                }
                else
                {
                    
                    self.brightnessView.center = self.center;
                }
                
                [self addSubview:self.brightnessView];
            }
        }
        else
        {
            //水平   进度
            self.direc = Dir_H;
        }
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint p = [pan translationInView:self];
        if (self.direc == Dir_H)
        {
            delta = p.x/self.frame.size.width*2;
        }
        else
        {
            delta = -p.y/self.frame.size.height*2;
        }
        
        switch (self.direc)
        {
            case Dir_H:
            {
                CGFloat value = self.slider.value + delta;
                if (value >= 0 && value <= 1)
                {
                    self.slider.value = value;
                }
            }break;
            case Dir_V_R:
            {
                [self.brightnessView setProgress:(self.brightNomal + delta)];
                
                [UIScreen mainScreen].brightness = self.brightNomal + delta;
            }break;
            case Dir_V_L:
            {
                [MPMusicPlayerController applicationMusicPlayer].volume = self.voiceNormal + delta;
            }break;
            default:
                break;
        }
    }
    else if (pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateFailed)
    {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5f animations:^{
            
            [weakSelf.brightnessView removeFromSuperview];
            
        }];
    }
}

#pragma mark - hidden
- (void)showOrHiddenMenu
{
    BOOL needHidden = self.bottomView.hidden;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bottomView.hidden = !self.bottomView.hidden;
        self.topView.hidden = !self.topView.hidden;
        if (needHidden)
        {
         [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showOrHiddenMenu) object:nil];
         [self performSelector:@selector(showOrHiddenMenu) withObject:nil afterDelay:5.f];
        }
    });
}
@end
