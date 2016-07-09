//
//  UploadManager.h
//  PostVideo
//
//  Created by zmw on 16/7/4.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiUploadModel.h"

typedef NS_ENUM(NSInteger , ActionType) {
    ActionType_Start,
    ActionType_Progress,
    ActionType_Error,
    ActionType_End,
};

typedef void(^UploadManagerBlock) (ActionType type ,MultiUploadModel *model, float progress, id object);
@interface UploadManager : NSObject
@property (copy, nonatomic) UploadManagerBlock block;
+ (instancetype)shareInstance;
- (NSArray *)getAllModels;
- (void)addUpload:(NSURL *)url fileName:(NSString *)name bucketName:(NSString *)bucketName;
- (void)save;
@end
