//
//  TableViewCell.h
//  PostVideo
//
//  Created by zmw on 16/7/5.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TableViewCellDelegate;

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) id<TableViewCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@end

@protocol TableViewCellDelegate <NSObject>

@optional
- (void)tableViewCell:(TableViewCell *)cell clickBtn:(BOOL)start;

@end