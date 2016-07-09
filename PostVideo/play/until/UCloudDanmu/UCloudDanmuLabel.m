//
//  UCloudDanmuLabel.m
//  UCloudDanumuDemo
//
//  Created by chen on 15/7/2.
//  Copyright (c) 2015年 chen. All rights reserved.
//

#import "UCloudDanmuLabel.h"

#define ARC4RANDOM_MAX      0x100000000

#define ROLL_ANIMATION_DURATION_TIME 5

#define FADE_ANIMATION_DURATION_TIME 2
#define ANIMATION_DELAY_TIME 3

@interface UCloudDanmuLabel ()

@property (nonatomic, strong) UCloudDanmu *info;
@property (nonatomic, readwrite) DanmuState danmuState;
@property (nonatomic, readwrite) CGFloat animationDuartion;

@property (nonatomic, readwrite) CGFloat speed;
@property (nonatomic, readwrite) CGFloat currentRightX;

@property (nonatomic) NSUInteger nChannel;
@property (nonatomic, weak)   UIView *superView;

@property (nonatomic) CGFloat originalX;

@end

@implementation UCloudDanmuLabel

- (void)dealloc
{
    _info = nil;
}

#pragma mark - Private

- (void)p_initData
{
    self.textColor = _info.color;
    UIFont *font = [UIFont systemFontOfSize:_info.fontSize];
    self.font = font;
    self.text = _info.detail;
}

- (void)p_initFrame:(CGFloat)offsetX
{
    if (self.isMoveModeFadeOut)
    {
        NSInteger plus = ((arc4random() % 2) + 1) == 1 ? 1 : -1;
        offsetX = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 30.0f)*plus;
        NSString *content = self.info.detail;
        CGSize size = [UCloudDanmuUtil getSizeWithString:content withFont:self.font size:(CGSize){MAXFLOAT, CHANNEL_HEIGHT}];
        CGRect frame = (CGRect){(CGPoint){0, 0}, size};
        self.frame = frame;
        
        CGPoint center = _superView.center;
        center.x += offsetX;
        self.center = center;
    }
    else
    {
        NSString *content = self.info.detail;
        CGSize size = [UCloudDanmuUtil getSizeWithString:content withFont:self.font size:(CGSize){MAXFLOAT, CHANNEL_HEIGHT}];
        CGRect frame = (CGRect){(CGPoint){_superView.frame.size.width + offsetX, 0}, size};
        self.frame = frame;
        _originalX = frame.origin.x + frame.size.width;
    }
}

- (void)p_rollAnimation:(CGFloat)time delay:(NSTimeInterval)waitTime
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.danmuState = DanmuStateAnimationing;
        [UIView animateWithDuration:time delay:waitTime options:UIViewAnimationOptionCurveLinear animations:^{
            CGRect frame = self.frame;
            frame.origin.x = -self.frame.size.width;
            self.frame = frame;
        } completion:^(BOOL finished) {
            if (finished)
                [self removeDanmu];
        }];
    });
}

- (void)p_fadeAnimation:(CGFloat)time delay:(NSTimeInterval)disappearTime waitTime:(NSTimeInterval)waitTime
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (waitTime == 0) {
            self.alpha = 1;
            self.danmuState = DanmuStateAnimationing;
            [UIView animateWithDuration:time delay:disappearTime options:UIViewAnimationOptionCurveLinear animations:^{
                self.alpha = 0.2;
            } completion:^(BOOL finished) {
                if (finished)
                    [self removeDanmu];
            }];
        }
        else
        {
            self.alpha = 0;
            [UIView animateWithDuration:0 delay:waitTime options:UIViewAnimationOptionCurveLinear animations:^{
                self.alpha = 1;
            } completion:^(BOOL finished) {
                self.danmuState = DanmuStateAnimationing;
                [UIView animateWithDuration:time delay:disappearTime options:UIViewAnimationOptionCurveLinear animations:^{
                    self.alpha = 0.2;
                } completion:^(BOOL finished1) {
                    if (finished1)
                        [self removeDanmu];
                }];
            }];
        }
    });
}

#pragma mark - Action

+(id)createWithInfo:(UCloudDanmu *)info inView:(UIView *)view
{
    UCloudDanmuLabel *danmuLabel = [[UCloudDanmuLabel alloc] init];
    
    danmuLabel.info = info;
    danmuLabel.superView = view;
    danmuLabel.nChannel = 0;
    
    [danmuLabel p_initData];
    [danmuLabel p_initFrame:0];
    
    return danmuLabel;
}

- (void)setDanmuChannel:(NSUInteger)channel offset:(CGFloat)xy
{
    if (self.isMoveModeFadeOut)
    {
        self.danmuState = DanmuStateStop;
        self.nChannel = channel;
        CGRect frame = self.frame;
        frame.origin.y = CHANNEL_HEIGHT*_nChannel + xy;
        self.frame = frame;
        [_superView addSubview:self];
    }
    else
    {
        self.danmuState = DanmuStateStop;
        self.nChannel = channel;
        CGRect frame = self.frame;
        frame.origin.x += xy;
        frame.origin.y = CHANNEL_HEIGHT*_nChannel;
        self.frame = frame;
        _originalX = frame.origin.x + frame.size.width;
        [_superView addSubview:self];
    }
}

- (void)animationDanmuItem:(NSTimeInterval)waitTime
{
    if (self.isMoveModeFadeOut)
    {
        [self p_fadeAnimation:FADE_ANIMATION_DURATION_TIME delay:ANIMATION_DELAY_TIME waitTime:waitTime];
    }
    else
    {
        [self p_rollAnimation:self.animationDuartion delay:waitTime];
    }
}

- (void)pause
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isMoveModeFadeOut)
        {
            //    self.danmuState = DanmuStateStop;
            //    self.alpha = 1.0;
            //    [self.layer removeAllAnimations];
        }
        else
        {
            self.danmuState = DanmuStateStop;
            UIView *view = self;
            CALayer *layer = view.layer;
            CGRect rect = view.frame;
            if (layer.presentationLayer)
            {
                rect = ((CALayer *)layer.presentationLayer).frame;
    //            rect.origin.x -= 1;
            }
            view.frame = rect;
            [view.layer removeAllAnimations];
        }
    });
}

- (void)resume:(NSTimeInterval)nowTime
{
    if (self.isMoveModeFadeOut)
    {
        //    CGFloat startTime = self.startTime;
        //    CGFloat time = nowTime - startTime;
        //
        //    CGFloat waitTime = self.startTime;
        //    if (waitTime > nowTime)
        //        waitTime = waitTime - nowTime;
        //    else
        //        waitTime = 0;
        //
        //    if (waitTime > 0) {
        //        [self p_fadeAnimation:self.animationDuartion delay:ANIMATION_DELAY_TIME waitTime:waitTime];
        //    }
        //    else {
        //        [self p_fadeAnimation:time delay:ANIMATION_DELAY_TIME waitTime:0];
        //    }
        if (self.danmuState == DanmuStateStop)
            [self p_fadeAnimation:FADE_ANIMATION_DURATION_TIME delay:ANIMATION_DELAY_TIME waitTime:0];
    }
    else
    {
        CGFloat waitTime = self.startTime;
        if (waitTime > nowTime)
            waitTime = waitTime - nowTime;
        else
            waitTime = 0;
        
        CGFloat time = (self.frame.origin.x + self.frame.size.width)/self.speed;
        [self p_rollAnimation:time delay:waitTime];
    }
}

- (void)removeDanmu
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isMoveModeFadeOut)
        {
            self.danmuState = DanmuStateFinish;
            [self.layer removeAllAnimations];
            [self removeFromSuperview];
        }
        else
        {
            self.danmuState = DanmuStateFinish;
            [self.layer removeAllAnimations];
            [self removeFromSuperview];
        }
    });
}

#pragma mark - Get

- (CGFloat)speed
{
    _speed = _originalX/self.animationDuartion;
    return _speed;
}

- (CGFloat)animationDuartion
{
    if (self.isMoveModeFadeOut)
    {
        //如果是竖屏
        _animationDuartion = FADE_ANIMATION_DURATION_TIME + ANIMATION_DELAY_TIME;
        //如果是横屏，根据不同尺寸，可能有不同的总时间
    }
    else
    {
        _animationDuartion = ROLL_ANIMATION_DURATION_TIME;
    }
    return _animationDuartion;
}

- (CGFloat)currentRightX
{
    switch (self.danmuState)
    {
        case DanmuStateStop:
        {
            _currentRightX = CGRectGetMaxX(self.frame) - _superView.frame.size.width;
            break;
        }
        case DanmuStateAnimationing:
        {
            CALayer *layer = self.layer;
            _currentRightX = _originalX;
            if (layer.presentationLayer)
                _currentRightX = ((CALayer *)layer.presentationLayer).frame.origin.x + self.frame.size.width;
            _currentRightX -= _superView.frame.size.width;
            break;
        }
        case DanmuStateFinish:
        {
            _currentRightX = -_superView.frame.size.width;
            break;
        }
        default:
        {
            break;
        }
    }
    return _currentRightX;
}

#pragma mark -

- (CGFloat)startTime
{
    return self.info.time;
}

- (BOOL)isMoveModeRolling
{
    if (_info.type == UCloudDanmu_LeftToRight || _info.type == UCloudDanmu_RightToLeft)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isMoveModeFadeOut
{
    if (_info.type == UCloudDanmu_Top || _info.type == UCloudDanmu_Bottom)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isPositionTop
{
    if (_info.type == UCloudDanmu_Top)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isPositionMiddle
{
    return NO;
}

- (BOOL)isPositionBottom
{
    if (_info.type == UCloudDanmu_Bottom)
    {
        return YES;
    }
    return NO;
}

@end
