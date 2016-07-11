//
//  UCloudDanmuView.m
//  UCloudDanumuDemo
//
//  Created by chen on 15/6/28.
//  Copyright (c) 2015年 chen. All rights reserved.
//

#import "UCloudDanmuView.h"

@implementation UCloudDanmuView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
    }
    return self;
}

#pragma mark - Private
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches
{
    [super touchesEstimatedPropertiesUpdated:touches];
}

@end
