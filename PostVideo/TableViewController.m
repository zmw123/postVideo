//
//  TableViewController.m
//  PostVideo
//
//  Created by zmw on 16/6/30.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "TableViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "KSYPlayerVC.h"
#import "PlayerViewController.h"
#import <KS3YunSDK/KS3YunSDK.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UploadManager.h"
#import "UploadTableViewController.h"
#import <KS3YunSDK/KS3ConvertVideoRequest.h>
#import "KS3Util.h"

#define kBucketName @"testatm"

@interface TableViewController()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) NSMutableArray *objects;
@end

@implementation TableViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(showPic)];
    self.navigationItem.leftBarButtonItem = item;
    item = [[UIBarButtonItem alloc] initWithTitle:@"上传" style:UIBarButtonItemStyleDone target:self action:@selector(showMovie)];
    self.navigationItem.rightBarButtonItem = item;
    [self getAllObjects];
    
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
}

- (void)refresh
{
    [self getAllObjects];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)showPic
{
    UIImagePickerController *picVC = [[UIImagePickerController alloc] init];
    picVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picVC.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*) kUTTypeMovie, (NSString*) kUTTypeVideo, nil];
    picVC.delegate = self;
    [self presentViewController:picVC animated:YES completion:^{
        
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL *url = info[UIImagePickerControllerMediaURL];
    NSLog(@"Url:%@", url);
    
    NSURL *urlOne = info[UIImagePickerControllerReferenceURL];
    NSInteger degress = [TableViewController degressFromVideoFileWithURL:url];
    degress = [TableViewController degressFromVideoFileWithURL:urlOne];
    NSLog(@"%@", @(degress));
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[UploadManager shareInstance] addUpload:urlOne fileName:url.lastPathComponent bucketName:kBucketName];
//    });
    
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf showMovie];
    }];
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

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"%s", __func__);
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)getAllObjects
{
    KS3ListObjectsRequest *listObjectRequest = [[KS3ListObjectsRequest alloc] initWithName:kBucketName];
    [listObjectRequest setCompleteRequest];
    
    KS3ListObjectsResponse *response = [[KS3Client initialize] listObjects:listObjectRequest];
    self.objects = response.listBucketsResult.objectSummaries;
    
    [self.tableView reloadData];
}

- (void)showMovie
{
    [self performSegueWithIdentifier:@"ShowUpload" sender:self];
}

- (void)playWithUrl:(NSURL *)url
{
    NSURL *_url = [NSURL URLWithString:@"http://eflakee.kss.ksyun.com/Catch%20Me%20If%20You%20Can.m4v"];
    _url = [NSURL URLWithString:@"http://ks3-cn-beijing.ksyun.com/testatm/8.611M.mov"];
    PlayerViewController *vc = [[PlayerViewController alloc] initWithUrl:_url];
    vc.url = _url;
    [self.navigationController pushViewController:vc animated:YES];
//    [self.navigationController presentViewController:vc animated:YES completion:^{
//        
//    }];
}

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifer = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifer];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifer];
    }
    KS3ObjectSummary *object = self.objects[indexPath.row];
    cell.textLabel.text = object.Key;
    cell.textLabel.layer.borderColor = [UIColor redColor].CGColor;
    cell.textLabel.layer.borderWidth = 2.f;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KS3ObjectSummary *object = self.objects[indexPath.row];
    NSString *path = [NSString stringWithFormat:@"http://%@/%@/%@", [[KS3Client initialize] getBucketDomain], kBucketName, object.Key];
    NSURL *url = [NSURL URLWithString:path];
    
    //转码测试
    [MultiUploadModel convertVideo:kBucketName fileName:object.Key fileUrl:nil];
    
    //播放
    PlayerViewController *vc = [[PlayerViewController alloc] initWithUrl:url];
    vc.url = url;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}
@end
