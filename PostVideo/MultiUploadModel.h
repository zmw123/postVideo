//
//  MultiUploadModel.h
//  PostVideo
//
//  Created by zmw on 16/6/30.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KS3YunSDK/KS3YunSDK.h>

@protocol MultiUploadModelDelegate;

@interface MultiUploadModel : NSObject<NSCoding>
@property (strong, nonatomic) KS3MultipartUpload *muilt;
/**
 *  用于断点续传
 */
@property (strong, nonatomic) NSString *uploadId;
@property (strong, nonatomic) NSString *bucketName;
/**
 *  最终在控制台显示的名字
 */
@property (strong, nonatomic) NSString *fileName;
/**
 *  只能使相册的原始URL
 */
@property (strong, nonatomic) NSURL *fileUrl;
@property (weak, nonatomic) id<MultiUploadModelDelegate> delegate;
/**
 *  适用第一次发送
 */
- (void)start;
/**
 *  开始断点续传
 */
- (void)reStart;
/**
 *  取消
 */
- (BOOL)cancle;

- (NSString *)pathWithBucketName:(NSString *)bucketName bucketKey:(NSString *)bucketKey;

/**
 *  对上传的文件转码(异步操作)
 *
 *  @param bucket  bucket
 *  @param fileKey 文件名字
 *  @param url     文件路径
 */
+ (void)convertVideo:(NSString *)bucket fileName:(NSString *)fileKey fileUrl:(NSURL *)url;
@end

@protocol MultiUploadModelDelegate <NSObject>

- (void)uploadModelStart:(MultiUploadModel *)model;
- (void)uploadModel:(MultiUploadModel *)model error:(NSError *)error;
- (void)uploadModelEnd:(MultiUploadModel *)model;
- (void)uploadModel:(MultiUploadModel *)model progress:(float)progress;

@end