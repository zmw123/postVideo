//
//  UCloudDanmuParser.h
//  UCloudDanumuDemo
//
//  Created by yisanmao on 15/12/2.
//  Copyright © 2015年 chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UCloudDanmuManager.h"


typedef void(^ParserBlock)(BOOL result , id error);

@protocol UCloudDanmuTime <NSObject>

- (NSTimeInterval)getCurrentTime;

@end

@interface UCloudDanmuParser : NSObject
/**
 *  获取当前应该刷新弹幕的时间
 */
@property (weak, nonatomic) id<UCloudDanmuTime> delegate;
/**
 *  弹幕的实际控制类，可以有次得到弹幕view
 */
@property (strong, nonatomic) UCloudDanmuManager *danMuManager;
/**
 *  开始解析
 *
 *  @param url        XML路径
 *  @param data       XML 数据
 *  @param showView   弹幕显示的view
 *  @param completion 回掉闭包
 */
- (void)startWithFileUrl:(NSURL *)url orFileData:(NSData *)data showInView:(UIView *)showView completion:(ParserBlock)completion;
/**
 *  停止弹幕
 */
- (void)danMuStop;
/**
 *  暂停弹幕
 */
- (void)danMuPause;
/**
 *  恢复弹幕
 */
- (void)danMuResume;

/**
 *  开始弹幕
 */
- (void)danMuRestart;

/**
 *  重置弹幕
 *
 *  @param frame 弹幕显示的frame
 */
- (void)resetDanmuWithFrame:(CGRect)frame;
@end
