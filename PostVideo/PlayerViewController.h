//
//  PlayerViewController.h
//  PostVideo
//
//  Created by zmw on 16/7/1.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerViewController : UIViewController
@property (strong, nonatomic) NSURL *url;

- (id)initWithUrl:(NSURL *)url;
@end
