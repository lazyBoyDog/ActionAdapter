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

ZHRouteRegister("login://mymy/login", "NextViewController.loginWithName:password:")

@implementation NextViewController

+ (UIViewController *)loginWithName:(NSString *)name password:(NSString *)password {
    NextViewController *vc = [[NextViewController alloc] init];
    vc.view.backgroundColor = [UIColor lightGrayColor];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
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
