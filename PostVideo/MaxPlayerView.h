//
//  MaxPlayerView.h
//  PostVideo
//
//  Created by zmw on 16/7/11.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kZXVideoPlayerOriginalWidth  MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define kZXVideoPlayerOriginalHeight (kZXVideoPlayerOriginalWidth * (11.0 / 16.0))

@interface MaxPlayerView : UIView
@property(assign, nonatomic) UIInterfaceOrientationMask supportInterOrtation;
@property (strong, nonatomic) UIViewController *showVC;
/// 竖屏模式下点击返回
@property (nonatomic, copy) void(^videoPlayerGoBackBlock)(void);
/// 将要切换到竖屏模式
@property (nonatomic, copy) void(^videoPlayerWillChangeToOriginalScreenModeBlock)();
/// 将要切换到全屏模式
@property (nonatomic, copy) void(^videoPlayerWillChangeToFullScreenModeBlock)();

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url;
/// 展示播放器
- (void)showInView:(UIView *)view;
@end
