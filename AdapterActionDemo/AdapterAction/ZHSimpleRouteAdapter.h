//
//  ZHSimpleRouteAdapter.h
//  AdapterActionDemo
//
//  Created by zhouhui on 2018/9/18.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct _Route_Data {
    const char *url;
    const char *classFunc;
} Route_Data;

#define FUNC2(x,y) x##y
#define FUNC1(x,y) FUNC2(x,y)
#define FUNC(x) FUNC1(x,__COUNTER__)

#define ZHRouteInit(sectname) __attribute((used, section("__DATA,"#sectname" ")))
#define ZHRouteRegister(url, classFunction) \
static const Route_Data FUNC(__objc_zh_route) ZHRouteInit(__objc_zh_route) = (Route_Data){url, classFunction};

@interface ZHSimpleRouteAdapter : NSObject

+ (instancetype)shareInstance;

// 初级用法 要求函数必须以字典参数结尾
// 比如 login?name=zhou&password=abcdefg  方法名。loginWithParamters:
- (UIViewController *)zh_getViewControllerWithUrl:(NSString *)url;

// 高级用法，要求url中query的参数顺序与方法所需参数一致
// 比如 login?name=zhou&password=abcdefg  方法名。loginWithName:password:
// 支持的参数类型必须为string类型
- (UIViewController *)zh_getViewControllerOrderByParamtersWithUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
