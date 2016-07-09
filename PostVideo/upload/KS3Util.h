//
//  KS3Util.h
//  KS3iOSSDKDemo
//
//  Created by JackWong on 15/4/24.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KS3Request;

@interface KS3Util : NSObject
/*
 此类是客户端用aksk计算签名。
 1.若使用token方式，不建议客户端去计算，不安全，应由客户端请求服务端去根据aksk计算签名返回。
 2.若使用aksk方式，可计算签名
 
 */

+ (NSString *)getAuthorization:(KS3Request *)request;

+ (NSString *)KSYAuthorizationWithHTTPVerb:(NSString *)accessKey
                                 secretKey:(NSString *)secretKey
                                  httpVerb:(NSString *)httpVerb
                                contentMd5:(NSString *)strContentMd5
                               contentType:(NSString *)strContentType
                                      date:(NSString   *)date
                    canonicalizedKssHeader:(NSString *)strHeaders
                     canonicalizedResource:(NSString *)strResource;

@end
