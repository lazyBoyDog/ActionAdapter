//
//  NextViewController.m
//  AdapterActionDemo
//
//  Created by suruonan on 2018/9/18.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import "NextViewController.h"
#import "ZHSimpleRouteAdapter.h"
#import "ZHActionAdapter.h"

#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <mach-o/ldsyms.h>

@interface NextViewController ()

@end

//ZHRouteRegister("login://mymy/login", "NextViewController.loginWithParamters:")
ZHRouteRegister("login://mymy/login", "NextViewController.loginWithName:password:")

@implementation NextViewController

+ (UIViewController *)loginWithName:(NSString *)name password:(NSString *)password {
    NextViewController *vc = [[NextViewController alloc] init];
    NSLog(@"--%@", vc);
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *vc = [[ZHSimpleRouteAdapter shareInstance] zh_getViewControllerOrderByParamtersWithUrl:@"login://mymy/login?name=123&password=asdaas"];
    NSLog(@"获取到的VC 是 = %@", vc);
}

+ (UIViewController *)loginWithParamters:(NSDictionary *)paramter {
    NextViewController *vc = [[NextViewController alloc] init];
    NSLog(@"--%@", vc);
    return vc;
}


- (void)didTapRedBtnAction:(UIButton *)btn {
    UIButton *action = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 50, 30)];
    [action setBackgroundColor:[UIColor redColor]];
    [action addTarget:self
               action:@selector(didTapRedBtnAction:)
     forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:action];
}

- (void)didGotoPoiAddress:(NSInteger)ID poiID:(long)poiID {
    NSLog(@"--%ld--%ld--%@", ID, poiID, [NSThread currentThread]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"come dealloc");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
