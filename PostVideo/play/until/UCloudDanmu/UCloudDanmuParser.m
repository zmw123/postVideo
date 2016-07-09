//
//  UCloudDanmuParser.m
//  UCloudDanumuDemo
//
//  Created by yisanmao on 15/12/2.
//  Copyright © 2015年 chen. All rights reserved.
//

#import "UCloudDanmuParser.h"
#import "UCloudDanmu.h"

#import "NSTimer+EOCBlocksSupport.h"

@interface UCloudDanmuParser()<NSXMLParserDelegate>
@property (strong, nonatomic) NSMutableArray *datas;
@property (assign, nonatomic) ParserBlock block;
@property (strong, nonatomic) UCloudDanmu *danmu;
@property (strong, nonatomic) NSTimer *danMuTimer;

@property (strong, nonatomic) UIView *showView;
@end

@implementation UCloudDanmuParser
- (void)startWithFileUrl:(NSURL *)url orFileData:(NSData *)data showInView:(UIView *)showView completion:(ParserBlock)completion
{
    _block = completion;
    _showView = showView;
    NSXMLParser *parser = nil;
    
    if (url != nil)
    {
        parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    }
    else if (data != nil)
    {
        parser = [[NSXMLParser alloc] initWithData:data];
    }
    else
    {
        if (completion)
        {
            completion(NO, [[NSError alloc] initWithDomain:@"数据源不正确" code:8 userInfo:nil]);
        }
    }
    
    parser.delegate = self;
    [parser parse];
}

#pragma mark - api
-(void)danMuStart
{
    if ([_danMuTimer isValid])
    {
        return;
    }
    if (_danMuTimer == nil)
    {
        __weak UCloudDanmuParser *weakSelf = self;
        self.danMuTimer = [NSTimer eoc_scheduledTimerWithTimeInterval:1 block:^{
            [weakSelf refreshDanMu];
        } repeats:YES];
    }
}

- (void)refreshDanMu
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(getCurrentTime)])
    {
        NSTimeInterval currentTime = [self.delegate getCurrentTime];
        NSLog(@"currentTime:%f", currentTime);
        [self.danMuManager rollDanmu:currentTime];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"弹幕——————无法获取当前应该显示的时间");
#endif
    }
}

- (void)danMuStop
{
    [self.danMuManager stop];
    [self.danMuTimer invalidate];
}

- (void)danMuPause
{
    [self p_destoryTimer];
    [self.danMuManager pause];
}

- (void)danMuResume
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(getCurrentTime)])
    {
        NSTimeInterval currentTime = [self.delegate getCurrentTime];
        [self.danMuManager resume:currentTime];
        [self danMuStart];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"弹幕——————无法获取当前应该显示的时间");
#endif
    }
}

- (void)danMuRestart
{
    [self.danMuManager restart];
    [self p_destoryTimer];
    [_showView exchangeSubviewAtIndex:9 withSubviewAtIndex:8];
//    _danmuBottomContraint = [self addConstraintForView:self.danMuManager.danmuView inView:_showView constraint:nil];
    //这个放到外部
    [self danMuStart];
}

- (void)p_destoryTimer
{
    if (_danMuTimer != nil)
    {
        [_danMuTimer invalidate];
        _danMuTimer = nil;
    }
}

#pragma mark - parser xml
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _datas = [NSMutableArray array];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
    if ([elementName isEqualToString:@"d"])
    {
        _danmu = [[UCloudDanmu alloc] init];
        NSString *values = [attributeDict objectForKey:@"p"];
        NSArray *datas = [values componentsSeparatedByString:@","];
        _danmu.time = [datas[0] doubleValue];
        _danmu.type = [datas[1] integerValue];
        _danmu.fontSize = [datas[2] integerValue];
        _danmu.color = [UCloudDanmuParser colorWithHex:[datas[3] integerValue]|0xFF000000 alpha:1];
    }
}

+ (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity
{
    float red = ((float)((hexColor & 0xFF0000) >> 16))/255.0;
    float green = ((float)((hexColor & 0xFF00) >> 8))/255.0;
    float blue = ((float)(hexColor & 0xFF))/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:opacity];
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    _danmu.detail = string;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (_danmu)
    {
        [_datas addObject:_danmu];
        _danmu = nil;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    NSArray *data = nil;
    if (self.datas.count > 0)
    {
        data = [self.datas sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
            UCloudDanmu *one = obj1;
            UCloudDanmu *two = obj2;
            if (one.time > two.time)
            {
                return NSOrderedDescending;
            }
            else if (one.time == two.time)
            {
                return NSOrderedSame;
            }
            return NSOrderedAscending;
        }];
    }
    
    //解析XML完成
    self.danMuManager = [[UCloudDanmuManager alloc] initWithFrame:CGRectMake(0, 0, _showView.bounds.size.width, _showView.bounds.size.height) data:data inView:_showView durationTime:1];
    
    if (_block)
    {
        _block(YES, nil);
    }
    
}

- (void)resetDanmuWithFrame:(CGRect)frame
{
    [self.danMuManager pause];
    [self.danMuManager resetDanmuWithFrame:frame];
    [self.danMuManager restart];
}
@end
