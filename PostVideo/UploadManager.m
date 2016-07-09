//
//  UploadManager.m
//  PostVideo
//
//  Created by zmw on 16/7/4.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "UploadManager.h"


@interface UploadManager()<MultiUploadModelDelegate>
{
}
@property (strong, nonatomic) NSMutableArray *uploadModels;
@end

@implementation UploadManager
static UploadManager *manager = nil;
+ (instancetype)shareInstance
{
    if (!manager)
    {
        manager = [[UploadManager alloc] init];
        manager.uploadModels = [NSMutableArray arrayWithArray:[UploadManager getModels]];
    }
    return manager;
}

- (NSArray *)getAllModels
{
    for (MultiUploadModel *model in self.uploadModels)
    {
        if (model.uploadId.length > 0 && !model.muilt)
        {
            //需要断点续传的
            model.delegate = self;
            [model reStart];
        }
    }
    return [NSArray arrayWithArray:self.uploadModels];
}

- (void)addUpload:(NSURL *)url fileName:(NSString *)name bucketName:(NSString *)bucketName
{
    MultiUploadModel *model = [[MultiUploadModel alloc] init];
    model.fileUrl = url;
    model.fileName = name;
    model.bucketName = bucketName;
    [self.uploadModels addObject:model];
    model.delegate = self;
    [model start];
}

- (void)save
{
    [UploadManager save:self.uploadModels];
}

#pragma mark - MultiUploadModelDelegate
- (void)uploadModel:(MultiUploadModel *)model progress:(float)progress
{
    if (self.block)
    {
        self.block(ActionType_Progress, model, progress, nil);
    }
}

- (void)uploadModel:(MultiUploadModel *)model error:(NSError *)error
{
    if (self.block)
    {
        self.block(ActionType_Error, model, 0, error);
    }
}

- (void)uploadModelEnd:(MultiUploadModel *)model
{
    [self.uploadModels removeObject:model];
    [self save];
    if (self.block)
    {
        self.block(ActionType_End, model, 0, nil);
    }
}

- (void)uploadModelStart:(MultiUploadModel *)model
{
    if (self.block)
    {
        self.block(ActionType_Start, model, 0, nil);
    }
}

#pragma mark - save
+ (NSString *)DocumentDirectory
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"modelData.text"];
    return path;
}

+ (void)save:(NSArray *)models
{
    NSString *path = [UploadManager DocumentDirectory];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [NSKeyedArchiver archiveRootObject:models toFile:path];
}

+ (NSArray *)getModels
{
    NSArray *models = [NSKeyedUnarchiver unarchiveObjectWithFile:[UploadManager DocumentDirectory]];
    return models;
}
@end
