//
//  UCloudDanmu.h
//  UCloudDanumuDemo
//
//  Created by yisanmao on 15/12/2.
//  Copyright © 2015年 chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UCloudDanmuType)
{
    //1从左至右滚动弹幕|6从右至左滚动弹幕|5顶端固定弹幕|4底端固定弹幕|7高级弹幕|8脚本弹幕
    UCloudDanmu_RightToLeft = 1,
    UCloudDanmu_LeftToRight = 6,
    UCloudDanmu_Top = 5,
    UCloudDanmu_Bottom = 4,
};

@interface UCloudDanmu : NSObject
@property (assign, nonatomic) UCloudDanmuType type;
@property (assign, nonatomic) NSTimeInterval time;
@property (strong, nonatomic) UIColor *color;
@property (assign, nonatomic) NSInteger fontSize;
@property (strong, nonatomic) NSString *detail;
@end
