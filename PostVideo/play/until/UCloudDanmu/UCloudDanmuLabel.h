//
//  UCloudDanmuLabel.h
//  UCloudDanumuDemo
//
//  Created by chen on 15/7/2.
//  Copyright (c) 2015年 chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UCloudDanmu.h"
#import "UCloudDanmuUtil.h"

@interface UCloudDanmuLabel : UILabel

@property (nonatomic, readonly) UCloudDanmu *info;;
@property (nonatomic, readonly) DanmuState danmuState;
@property (nonatomic, readonly) CGFloat animationDuartion;

@property (nonatomic, readonly) CGFloat speed;
@property (nonatomic, readonly) CGFloat currentRightX;

@property (nonatomic, readonly) CGFloat startTime;
 
/**
 *  获取对应属性
 */
@property (nonatomic, getter=isMoveModeRolling, readonly) BOOL moveModeRolling;
@property (nonatomic, getter=isMoveModeFadeOut, readonly) BOOL moveModeFadeOut;
@property (nonatomic, getter=isPositionTop,     readonly) BOOL positionTop;
@property (nonatomic, getter=isPositionMiddle,  readonly) BOOL positionMiddle;
@property (nonatomic, getter=isPositionBottom,  readonly) BOOL positionBottom;

+(id)createWithInfo:(UCloudDanmu *)info inView:(UIView *)view;
- (void)setDanmuChannel:(NSUInteger)channel offset:(CGFloat)xy;

- (void)animationDanmuItem:(NSTimeInterval)waitTime;

- (void)pause;

- (void)resume:(NSTimeInterval)nowTime;

- (void)removeDanmu;

@end
