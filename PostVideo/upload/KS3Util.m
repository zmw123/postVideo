//
//  KS3Util.m
//  KS3iOSSDKDemo
//
//  Created by JackWong on 15/4/24.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import "KS3Util.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import <KS3YunSDK/KS3Request.h>


//NSString * const strAccessKey = @"ZHfrDw0iuxQpojtnvhVQ";
//NSString * const strSecretKey = @"V3fxcnw1ek7wcj6TUpwlEnMnH73eEkLUK/hx+5EE";
@implementation KS3Util
+ (NSString *)getAuthorization:(KS3Request *)request
{
    return [KS3Util KSYAuthorizationWithHTTPVerb:@"ZHfrDw0iuxQpojtnvhVQ" secretKey:@"V3fxcnw1ek7wcj6TUpwlEnMnH73eEkLUK/hx+5EE" httpVerb:request.httpMethod contentMd5:request.contentMd5 contentType:request.contentType date:request.strDate canonicalizedKssHeader:request.kSYHeader canonicalizedResource:request.kSYResource];
}

+ (NSString *)KSYAuthorizationWithHTTPVerb:(NSString *)accessKey
                                 secretKey:(NSString *)secretKey
                                  httpVerb:(NSString *)httpVerb
                                contentMd5:(NSString *)strContentMd5
                               contentType:(NSString *)strContentType
                                      date:(NSString   *)date
                    canonicalizedKssHeader:(NSString *)strHeaders
                     canonicalizedResource:(NSString *)strResource
{
    NSString *strAuthorization = @"KSS ";
    strAuthorization = [strAuthorization stringByAppendingString:accessKey];
    strAuthorization = [strAuthorization stringByAppendingString:@":"];
    NSString *strSignature = [self KSYSignatureWithHTTPVerb:secretKey
                                                   httpVerb:httpVerb
                                                 contentMd5:strContentMd5
                                                contentType:strContentType
                                                       date:date
                                     canonicalizedKssHeader:strHeaders
                                      canonicalizedResource:strResource];
    strAuthorization = [strAuthorization stringByAppendingString:strSignature];
    return strAuthorization;
}

+ (NSString *)KSYSignatureWithHTTPVerb:(NSString *)secretKey
                              httpVerb:(NSString *)httpVerb
                            contentMd5:(NSString *)strContentMd5
                           contentType:(NSString *)strContentType
                                  date:(NSString   *)strDate
                canonicalizedKssHeader:(NSString *)strHeaders
                 canonicalizedResource:(NSString *)strResource
{
    
    NSString *strHttpVerb = [httpVerb stringByAppendingString:@"\n"];
    
    // **** Content md5
    strContentMd5 = [strContentMd5 stringByAppendingString:@"\n"];
    
    // **** Content type
    strContentType = [strContentType stringByAppendingString:@"\n"];
    
    // **** Date
  
    strDate = [strDate stringByAppendingString:@"\n"];
    
    // **** Header & Resource
    //    strHeaders = [strHeaders stringByAppendingString:@"\n"];
    
    // **** Signature
    NSString *strToSig = [strHttpVerb stringByAppendingString:strContentMd5];
    strToSig = [strToSig stringByAppendingString:strContentType];
    strToSig = [strToSig stringByAppendingString:strDate];
    strToSig = [strToSig stringByAppendingString:strHeaders];
    strToSig = [strToSig stringByAppendingString:strResource];
    strToSig = [self hexEncode:secretKey text:strToSig];
    return strToSig;
}

+ (NSString *)hexEncode:(NSString *)key text:(NSString *)text
{
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [text cStringUsingEncoding:NSUTF8StringEncoding];
    uint8_t cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *strHash = @"";
    if ([HMAC respondsToSelector:@selector(base64EncodedDataWithOptions:)]) {
        strHash = [HMAC base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    }else {
        strHash = [HMAC base64Encoding];
    }
    return strHash;
}
@end
