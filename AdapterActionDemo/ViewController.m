//
//  ViewController.m
//  AdapterActionDemo
//
//  Created by zhouhui on 2018/9/17.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import "ViewController.h"
#import "ZHActionAdapter.h"
#import "NextViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *action = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 50, 30)];
    [action setBackgroundColor:[UIColor redColor]];
    [action addTarget:self
               action:@selector(didTapRedBtnAction:)
     forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:action];
    
    UIButton *action1 = [[UIButton alloc] initWithFrame:CGRectMake(250, 150, 50, 30)];
    [action1 setBackgroundColor:[UIColor greenColor]];
    [action1 addTarget:self
               action:@selector(didTapGreenBtnAction:)
     forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:action1];
    
    [ZHActionAdapter zh_receiveMessageKey:@"kViewControllerJumpAction" target:self usingBlock:^(id user, NSDictionary *info) {
        NextViewController *next = [[NextViewController alloc] init];
        [self presentViewController:next animated:YES completion:nil];
    }];
}

- (void)didTapGreenBtnAction:(UIButton *)btn {
    CFAbsoluteTime starTime =CFAbsoluteTimeGetCurrent();
    NextViewController *next = [[NextViewController alloc] init];
    [self presentViewController:next animated:YES completion:nil];
    CFAbsoluteTime linTime = (CFAbsoluteTimeGetCurrent() - starTime);
    NSLog(@"Linked in %f ms", linTime *1000.0);
}


- (void)didTapRedBtnAction:(UIButton *)btn {
    
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       [ZHActionAdapter zh_sendMessageKey:@"kViewControllerJumpAction" user:btn];
//    });
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Linked in %f ms", linkTime *1000.0);
}

- (void)mainQueueClick {
    NSLog(@"-CURRENT-QUEUE:%@",[NSOperationQueue currentQueue]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
