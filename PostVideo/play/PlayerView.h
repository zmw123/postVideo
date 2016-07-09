//
//  PlayerView.h
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlayerViewDelegate;

@interface PlayerView : UIView
@property (weak, nonatomic) id<PlayerViewDelegate> delegate;
@property (strong, nonatomic) UIViewController *showVC;
@property(assign, nonatomic) UIInterfaceOrientationMask supportInterOrtation;
- (id)initWithFrame:(CGRect)frame url:(NSURL *)url;
@end

@protocol PlayerViewDelegate <NSObject>
@optional
- (void)playerView:(PlayerView *)view clickBack:(UIButton *)btn;

@end
