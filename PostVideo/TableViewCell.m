//
//  TableViewCell.m
//  PostVideo
//
//  Created by zmw on 16/7/5.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)clickBtn:(id)sender
{
    UIButton *btn = sender;
    BOOL start = NO;
    if ([btn.titleLabel.text isEqualToString:@"暂停"])
    {
        btn.titleLabel.text = @"开始";
        start = NO;
    }
    else
    {
        btn.titleLabel.text = @"暂停";
        start = YES;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCell:clickBtn:)])
    {
        [self.delegate tableViewCell:self clickBtn:start];
    }
}

@end
