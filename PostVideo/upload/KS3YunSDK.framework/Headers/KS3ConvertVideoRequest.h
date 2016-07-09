//
//  KS3ConvertVideoRequest.h
//  KS3YunSDK
//
//  Created by zmw on 16/7/6.
//  Copyright © 2016年 kingsoft. All rights reserved.
//

#import <KS3YunSDK/KS3YunSDK.h>

@interface KS3ConvertVideoRequest : KS3Request
@property (nonatomic, strong) NSString *key;
@property (nonatomic, assign) float rotateDegress;
- (instancetype)initWithName:(NSString *)bucketName withKeyName:(NSString *)strKey;
@end
