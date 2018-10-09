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
#import "ZHSimpleRouteAdapter.h"

@interface ZHCustomCell : UITableViewCell

@property (nonatomic, strong) UIButton *alertBtn1;
@property (nonatomic, strong) UIButton *alertBtn2;
@property (nonatomic, strong) UIButton *jumpBtn;

@end


@implementation ZHCustomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.alertBtn1 = [self btnWithTitle:@"测试1" frame:CGRectMake(15, 10, 50, 30)
                                     action:@selector(alertTest1:)];
        self.alertBtn2 = [self btnWithTitle:@"测试2" frame:CGRectMake(70, 10, 50, 30)
                                     action:@selector(alertTest2:)];
        self.jumpBtn = [self btnWithTitle:@"跳转" frame:CGRectMake(100, 40, 50, 30)
                                   action:@selector(jumpToNext)];
        
    }
    return self;
}

- (UIButton *)btnWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)selector {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:btn];
    return btn;
}

- (void)alertTest1:(UIButton *)btn {
    ZH_ActionAdapterSend(@"kViewControllerAlert1Action", btn.titleLabel.text);
}

- (void)alertTest2:(UIButton *)btn {
    [ZHActionAdapter zh_sendMessageKey:@"kViewControllerAlert2Action"
                                  user:btn
                              userInfo:@{@"text" : @"我就是试试"}];
}

- (void)jumpToNext {
    [ZHActionAdapter zh_sendMessageKey:@"kViewControllerJumpAction"
                              userInfo:@{@"id" : @"1234567"}];
}

@end


@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = ({
        UITableView *table = [[UITableView alloc] initWithFrame:self.view.bounds];
        [table registerClass:[ZHCustomCell class] forCellReuseIdentifier:@"ZHCustomCell"];
        table.delegate = self;
        table.dataSource = self;
        table;
    });
    [self.view addSubview:self.tableView];
    [self receiveActions];
}

- (void)receiveActions {
    ZH_ActionAdapterReceive(@"kViewControllerAlert1Action", @selector(alert1Action:));
    [ZHActionAdapter zh_receiveMessageKey:@"kViewControllerAlert2Action"
                                   target:self
                                 selector:@selector(alert2ActionFromBtn:paramter:)];
    
    [ZHActionAdapter zh_receiveMessageKey:@"kViewControllerJumpAction" target:self usingBlock:^(id user, NSDictionary *info) {
        NSLog(@"跳转调用-user %@--info %@", user, info);
        UIViewController *vc = [[ZHSimpleRouteAdapter shareInstance] zh_getViewControllerOrderByParamtersWithUrl:@"login://mymy/login?name=123&password=asdaas"];
        [self presentViewController:vc animated:YES completion:nil];
    }];
}

- (void)alert1Action:(NSString *)alert {
    NSLog(@"测试1调用--%@",alert);
}

- (void)alert2ActionFromBtn:(UIButton *)btn paramter:(NSDictionary *)paramter {
    NSLog(@"测试2调用--user：%@ , paramter:%@",btn, paramter);
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZHCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZHCustomCell" forIndexPath:indexPath];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
