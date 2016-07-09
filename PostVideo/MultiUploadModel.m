//
//  MultiUploadModel.m
//  PostVideo
//
//  Created by zmw on 16/6/30.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "MultiUploadModel.h"
#import "MultiUploadModel.h"
#import "KS3Util.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UploadManager.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - upload

@interface MultiUploadModel()<KingSoftServiceRequestDelegate>
@property (assign, nonatomic) NSInteger partSize;
@property (assign, nonatomic) long long fileSize;
@property (assign, nonatomic) long long partLength;
@property (assign, nonatomic) NSInteger totalNum;
@property (assign, nonatomic) NSInteger uploadNum;

@property (strong, nonatomic) ALAsset *asset;
@end

static NSString *kMuilt = @"kMuilt";
static NSString *kPartSize = @"kPartSize";
static NSString *kFileSize = @"kFileSize";
static NSString *kPartLength = @"kPartLength";
static NSString *kTotalNum = @"kTotalNum";
static NSString *kUploadNum = @"kUploadNum";
static NSString *kUploadId = @"kUploadId";
static NSString *kFileUrl = @"kFileUrl";
static NSString *kBucketName = @"kBucketName";
static NSString *kFileName = @"kFileName";

@implementation MultiUploadModel
#pragma mark coding
- (id)initWithCoder:(NSCoder *)aDecoder
{
    MultiUploadModel *manager = [[MultiUploadModel alloc] init];
    manager.partSize = [[aDecoder decodeObjectForKey:kPartSize] integerValue];
    manager.fileSize = [[aDecoder decodeObjectForKey:kFileSize] floatValue];
    manager.partLength = [[aDecoder decodeObjectForKey:kPartLength] floatValue];
    manager.totalNum = [[aDecoder decodeObjectForKey:kTotalNum] integerValue];
    manager.uploadNum = [[aDecoder decodeObjectForKey:kUploadNum] integerValue];
    manager.uploadId = [aDecoder decodeObjectForKey:kUploadId];
    manager.fileUrl = [aDecoder decodeObjectForKey:kFileUrl];
    manager.bucketName = [aDecoder decodeObjectForKey:kBucketName];
    manager.fileName = [aDecoder decodeObjectForKey:kFileName];
    return manager;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.partSize) forKey:kPartSize];
    [aCoder encodeObject:@(self.fileSize) forKey:kFileSize];
    [aCoder encodeObject:@(self.partLength) forKey:kPartLength];
    [aCoder encodeObject:@(self.totalNum) forKey:kTotalNum];
    [aCoder encodeObject:@(self.uploadNum) forKey:kUploadNum];
    [aCoder encodeObject:self.uploadId forKey:kUploadId];
    [aCoder encodeObject:self.fileUrl forKey:kFileUrl];
    [aCoder encodeObject:self.bucketName forKey:kBucketName];
    [aCoder encodeObject:self.fileName forKey:kFileName];
}

- (NSString *)pathWithBucketName:(NSString *)bucketName bucketKey:(NSString *)bucketKey
{
    NSString *strHost = [NSString stringWithFormat:@"http://%@.%@/%@", [[KS3Client initialize]getBucketDomain], bucketName, bucketKey];
    return strHost;
}
#pragma mark - upload
- (id)init
{
    self = [super init];
    if (self)
    {
        _partSize = 5;
        _partLength = 5*1024*1024;
    }
    return self;
}

- (void)start
{
    ALAssetsLibrary *libray = [[ALAssetsLibrary alloc] init];
    __weak typeof(self) weakSelf = self;
    [libray assetForURL:self.fileUrl resultBlock:^(ALAsset *asset) {
        weakSelf.fileSize = asset.defaultRepresentation.size;
        weakSelf.asset = asset;
        if (weakSelf.fileSize < weakSelf.partLength)
        {
            [weakSelf beginSingleUpload];
        }
        else
        {
            [weakSelf beginMultiUpload];
        }
    } failureBlock:^(NSError *error) {
        
    }];
}
//单块上传(文件小于5M)
- (void)beginSingleUpload
{
    NSData *data = [[KS3Client initialize] getUploadPartDataWithPartNum:1 partLength:(int)self.partLength Alasset:self.asset];
    KS3AccessControlList *ControlList = [[KS3AccessControlList alloc] init];
    [ControlList setContronAccess:KingSoftYun_Permission_Public_Read_Write];
    KS3PutObjectRequest *putObjRequest = [[KS3PutObjectRequest alloc] initWithName:self.bucketName
                                                                           withAcl:ControlList
                                                                          grantAcl:nil];
    
    putObjRequest.data = data;
    putObjRequest.delegate = self;
    putObjRequest.filename = self.fileName;//kTestSpecial10;//[fileName lastPathComponent];
    putObjRequest.contentMd5 = [KS3SDKUtil base64md5FromData:putObjRequest.data];
    [putObjRequest setCompleteRequest];
    KS3PutObjectResponse *response = [[KS3Client initialize] putObject:putObjRequest];
    
    //putObjRequest若没设置代理，则是同步的下方判断，
    //putObjRequest若设置了代理，则走上传代理回调,
    if (putObjRequest.delegate == nil)
    {
        NSLog(@"%@",[[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);
        if (response.httpStatusCode == 200)
        {
            NSLog(@"Put object success");
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModelEnd:)])
            {
                [self.delegate uploadModelEnd:self];
            }
        }
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:error:)])
            {
                [self.delegate uploadModel:self error:[NSError errorWithDomain:@"单片上传失败" code:100 userInfo:nil]];
            }
            NSLog(@"Put object failed");
        }
    }
}
//分块上传
- (void)beginMultiUpload
{
    KS3AccessControlList *acl = [[KS3AccessControlList alloc] init];
    [acl setContronAccess:KingSoftYun_Permission_Public_Read];
    
    KS3InitiateMultipartUploadRequest *initMultipartUploadReq = [[KS3InitiateMultipartUploadRequest alloc] initWithKey:self.fileName inBucket:self.bucketName acl:acl grantAcl:nil];
    [initMultipartUploadReq setCompleteRequest];
    
    [initMultipartUploadReq setStrKS3Token:[KS3Util getAuthorization:initMultipartUploadReq]];
    
    self.muilt = [[KS3Client initialize] initiateMultipartUploadWithRequest:initMultipartUploadReq];
    if (self.muilt == nil)
    {
        NSLog(@"Init upload failed, please check access key, scret key and bucket name!");
        return;
    }
    
    self.muilt.uploadType = kUploadAlasset;
    if (!(_partSize > 0 || _partSize != 0))
    {
        _partLength = _fileSize;
    }
    else
    {
        _partLength = _partSize * 1024.0 * 1024.0;
    }
    _totalNum = (ceilf((float)_fileSize / (float)_partLength));
    
    self.uploadId = _muilt.uploadId;
    self.uploadNum = 1;
    [self uploadWithPartNumber:self.uploadNum];
}

- (void)uploadWithPartNumber:(NSInteger)partNumber
{
    @autoreleasepool {
        if (self.muilt.isPaused || self.muilt.isCanceled)
        {
            [_muilt proceed];
        }
        NSData *data = [[KS3Client initialize] getUploadPartDataWithPartNum:partNumber partLength:(int)self.partLength alassetURL:self.fileUrl];
        
        KS3UploadPartRequest *req = [[KS3UploadPartRequest alloc] initWithMultipartUpload:self.muilt partNumber:(int)partNumber data:data generateMD5:NO];
        req.delegate = self;
        req.contentLength = data.length;
        req.contentMd5 = [KS3SDKUtil base64md5FromData:data];
        [req setCompleteRequest];
        [req setStrKS3Token:[KS3Util getAuthorization:req]];
        [[KS3Client initialize] uploadPart:req];
    }
}
#pragma mark - cancle
- (BOOL)cancle
{
    return [self cacleMultiPartUpload];
}

- (BOOL)cacleMultiPartUpload
{
    if (self.muilt == nil)
    {
        return NO;
    }
    KS3AbortMultipartUploadRequest *req = [[KS3AbortMultipartUploadRequest alloc] initWithMultipartUpload:self.muilt];
    [req setCompleteRequest];
    [req setStrKS3Token:[KS3Util getAuthorization:req]];
    KS3AbortMultipartUploadResponse *response = [[KS3Client initialize] abortMultipartUpload:req];
    if (response.httpStatusCode == 204)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - reStart
- (void)reStart
{
    ALAssetsLibrary *libray = [[ALAssetsLibrary alloc] init];
    __weak typeof(self) weakSelf = self;
    [libray assetForURL:self.fileUrl resultBlock:^(ALAsset *asset) {
        if (asset)
        {
            weakSelf.fileSize = asset.defaultRepresentation.size;
            weakSelf.asset = asset;
            [weakSelf reStartModel];
        }
    } failureBlock:^(NSError *error) {
        
    }];
}

- (void)reStartModel
{
    if (!(_partSize > 0 || _partSize != 0))
    {
        _partLength = _fileSize;
    }
    else
    {
        _partLength = _partSize * 1024.0 * 1024.0;
    }
    _totalNum = (ceilf((float)_fileSize / (float)_partLength));
    
    _muilt.uploadId = self.uploadId;
    KS3AccessControlList *acl = [[KS3AccessControlList alloc] init];
    [acl setContronAccess:KingSoftYun_Permission_Public_Read];
    
    KS3InitiateMultipartUploadRequest *initMultipartUploadReq = [[KS3InitiateMultipartUploadRequest alloc] initWithKey:self.fileName inBucket:self.bucketName acl:acl grantAcl:nil];
    [initMultipartUploadReq setCompleteRequest];
    
    [initMultipartUploadReq setStrKS3Token:[KS3Util getAuthorization:initMultipartUploadReq]];
    
    self.muilt = [[KS3Client initialize] initiateMultipartUploadWithRequest:initMultipartUploadReq];
    if (self.muilt == nil)
    {
        NSLog(@"Init upload failed, please check access key, scret key and bucket name!");
        return;
    }
    self.muilt.uploadId = self.uploadId;
    KS3ListPartsRequest *req = [[KS3ListPartsRequest alloc] initWithMultipartUpload:self.muilt];
    [req setCompleteRequest];
    [req setStrKS3Token:[KS3Util getAuthorization:req]];
    KS3ListPartsResponse *response = [[KS3Client initialize] listParts:req];
    
    NSLog(@"response.listResult.parts=%@", [response.listResult.parts firstObject]);
    self.uploadNum = ((KS3Part *)[response.listResult.parts lastObject]).partNumber + 1;
    //进度补齐
    long long alreadyTotalWriten = (_uploadNum - 1) * _partLength ;
    double progress = alreadyTotalWriten / (float)_fileSize;
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:progress:)])
    {
        [self.delegate uploadModel:self progress:progress];
    }
    [self uploadWithPartNumber:_uploadNum];
}

#pragma mark - convert
+ (void)convertVideo:(NSString *)bucket fileName:(NSString *)fileKey fileUrl:(NSURL *)url
{
    KS3ConvertVideoRequest *req = [[KS3ConvertVideoRequest alloc] initWithName:bucket withKeyName:fileKey];
    req.rotateDegress = [MultiUploadModel degressFromVideoFileWithURL:url];
    if (req.rotateDegress == 0)
    {
        req.rotateDegress = 90;
    }
    [req setCompleteRequest];
    [req setStrKS3Token:[KS3Util getAuthorization:req]];
    KS3Response *response = [[KS3Client alloc] convertVideo:req];
    NSLog(@"response:%@", response);
}

+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url
{
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    
    return degress;
}

#pragma mark - KingSoftServiceRequestDelegate
- (void)request:(KS3Request *)request didCompleteWithResponse:(KS3Response *)response
{
    if ([request isKindOfClass:[KS3PutObjectRequest class]]) {
        
        if (response.httpStatusCode == 200) {
            NSLog(@"单块上传成功");
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModelEnd:)])
            {
                [self.delegate uploadModelEnd:self];
            }
        }else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModelEnd:)])
            {
                [self.delegate uploadModelEnd:self];
            }
            NSLog(@"单块上传失败");
        }
        return;
    }
    else if ([request isKindOfClass:[KS3UploadPartRequest class]])
    {
        _uploadNum ++;
        [[UploadManager shareInstance] save];
        if (_totalNum < _uploadNum)
        {
            KS3ListPartsRequest *req2 = [[KS3ListPartsRequest alloc] initWithMultipartUpload:_muilt];
            [req2 setCompleteRequest];
            
            KS3ListPartsResponse *response2 = [[KS3Client initialize] listParts:req2];
            
            KS3CompleteMultipartUploadRequest *req = [[KS3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:_muilt];
            
            for (KS3Part *part in response2.listResult.parts)
            {
                [req addPartWithPartNumber:part.partNumber withETag:part.etag];
            }
            [req setCompleteRequest];
            KS3CompleteMultipartUploadResponse *resp = [[KS3Client initialize] completeMultipartUpload:req];
            if (resp.httpStatusCode != 200)
            {
                NSLog(@"#####complete multipart upload failed!!! code: %d#####", resp.httpStatusCode);
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:error:)])
                {
                    [self.delegate uploadModel:self error:[NSError errorWithDomain:@"上传失败" code:resp.httpStatusCode userInfo:nil]];
                }
            }else
            {
                NSLog(@"分块上传成功!!");
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModelEnd:)])
                {
                    [self.delegate uploadModelEnd:self];
                }
            }
            //转码
            [MultiUploadModel convertVideo:kBucketName fileName:self.fileName fileUrl:self.fileUrl];
        }
        else
        {
            [self uploadWithPartNumber:_uploadNum];
        }
    }
}

- (void)request:(KS3Request *)request didFailWithError:(NSError *)error
{
    NSLog(@"upload error: %@", error);
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:error:)])
    {
        [self.delegate uploadModel:self error:error];
    }
}

- (void)request:(KS3Request *)request didReceiveResponse:(NSURLResponse *)response
{
    // **** TODO:
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:progress:)])
    {
//        [self.delegate uploadModel:self progress:0.f];
    }
}

- (void)request:(KS3Request *)request didReceiveData:(NSData *)data
{
    /**
     *  Never call this method, because it's upload
     *
     *  @return <#return value description#>
     */
}

-(void)request:(KS3Request *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    if ([request isKindOfClass:[KS3PutObjectRequest class]]) {
        
        long long alreadyTotalWriten = totalBytesWritten;
        double progress = alreadyTotalWriten * 1.0  / self.fileSize;
        NSLog(@"upload progress: %f", progress);
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:progress:)])
        {
            [self.delegate uploadModel:self progress:progress];
        }
    }else if([request isKindOfClass:[KS3UploadPartRequest class]])
    {
        if (_muilt.isCanceled )
        {
            [request cancel];
            [request cancel];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:progress:)])
            {
                [self.delegate uploadModel:self progress:0.f];
            }
            return;
        }
        
        long long alreadyTotalWriten = (_uploadNum - 1) * _partLength + totalBytesWritten;
        double progress = alreadyTotalWriten / (float)_fileSize;
        NSLog(@"upload progress: %f", progress);
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadModel:progress:)])
        {
            [self.delegate uploadModel:self progress:progress];
        }
    }
}
@end
