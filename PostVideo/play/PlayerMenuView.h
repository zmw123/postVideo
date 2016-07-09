//
//  PlayerMenuView.h
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlayerMenuViewDelegate <NSObject>

- (void)clickPlayOrPauseBtn:(UIImageView *)image playing:(BOOL)isPlaying;
- (void)sliderValueChange:(UISlider *)slider value:(float)value;
- (void)clickBackBtn:(UIButton *)btn;
- (void)clickFullScreenBtn:(UIButton *)btn completion:(void(^)(void))completion;
@end

@interface PlayerMenuView : UIView
@property (weak, nonatomic) id<PlayerMenuViewDelegate> delegate;
- (void)updateProgress:(float)progress;
- (void)updateTimeLabel:(NSString *)text;
@end
