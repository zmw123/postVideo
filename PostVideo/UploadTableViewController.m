//
//  UploadTableViewController.m
//  PostVideo
//
//  Created by zmw on 16/7/5.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "UploadTableViewController.h"
#import "UploadManager.h"
#import "TableViewCell.h"

@interface UploadTableViewController ()<TableViewCellDelegate>
@property (strong, nonatomic) NSMutableArray *data;
@end

@implementation UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.data = [NSMutableArray arrayWithArray:[[UploadManager shareInstance] getAllModels]];
    [[UploadManager shareInstance] setBlock:^(ActionType type ,MultiUploadModel *model, float progress, id object){
        if (type == ActionType_Progress)
        {
            NSInteger index = [self.data indexOfObject:model];
            NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
            TableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
            cell.slider.value = progress;
        }
        else if (type == ActionType_End)
        {
            [self.data removeObject:model];
            [self.tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UploadManager shareInstance] save];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    MultiUploadModel *model = [self.data objectAtIndex:indexPath.row];
    cell.label.text = model.fileName;
    cell.slider.value = 0.f;
    cell.delegate = self;
    return cell;
}

- (void)tableViewCell:(TableViewCell *)cell clickBtn:(BOOL)start
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MultiUploadModel *model = [self.data objectAtIndex:indexPath.row];
    if (start)
    {
        [model.muilt proceed];
    }
    else
    {
        [model.muilt pause];
    }
}
@end
