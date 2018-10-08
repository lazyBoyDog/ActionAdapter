//
//  ZHSimpleRouteAdapter.m
//  AdapterActionDemo
//
//  Created by zhouhui on 2018/9/18.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import "ZHSimpleRouteAdapter.h"

@implementation ZHSimpleRouteAdapter {
    CFMutableDictionaryRef _routeDic;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static ZHSimpleRouteAdapter *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[ZHSimpleRouteAdapter alloc] init];
        
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _routeDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,
                                              &kCFTypeDictionaryValueCallBacks);
        [self initializeGlobalRouteDicWithSectionName:"__objc_zh_route"];
    }
    return self;
}

- (UIViewController *)zh_getViewControllerWithUrl:(NSString *)url {
    if (url.length <= 0) {
        return nil;
    }
    NSString *path;
    NSScanner *scanner = [NSScanner scannerWithString:url];
    [scanner scanUpToString:@"?" intoString:&path];
    NSMutableDictionary *queryDic = nil;
    // 成功 说明存在 query
    if (path.length > 0) {
        queryDic = [NSMutableDictionary dictionary];
        while ([scanner isAtEnd] == NO) {
            scanner.scanLocation += 1;
            NSString *key,*value;
            [scanner scanUpToString:@"=" intoString:&key];
            if (scanner.scanLocation +1 < scanner.string.length) {
                scanner.scanLocation += 1;
                [scanner scanUpToString:@"&" intoString:&value];
                [queryDic setValue:value forKey:key];
            }
        }
    } else {
        path = url;
    }
    NSString *valueStr = CFDictionaryGetValue(_routeDic, (void *)path);
    NSScanner *valueScanner = [NSScanner scannerWithString:valueStr];
    NSString *classStr,*function;
    [valueScanner scanUpToString:@"." intoString:&classStr];
    if (classStr.length == valueStr.length ) {
        NSLog(@"字符串格式错误");
        return nil;
    }
    function = [valueStr substringFromIndex:(valueScanner.scanLocation +1)];
    if (function.length <= 0) {
        return nil;
    }
    Class className = NSClassFromString(classStr);
    SEL selector = NSSelectorFromString(function);
    if (queryDic) {
        return ((UIViewController * (*)(Class, SEL,...))[className methodForSelector:selector])(className, selector, queryDic);
    } else {
        return ((UIViewController * (*)(Class, SEL,...))[className methodForSelector:selector])(className, selector);
    }
}

- (UIViewController *)zh_getViewControllerOrderByParamtersWithUrl:(NSString *)url {
    if (url.length <= 0) {
        return nil;
    }
    NSString *path;
    UIViewController *vc = nil;
    NSScanner *scanner = [NSScanner scannerWithString:url];
    BOOL result = [scanner scanUpToString:@"?" intoString:&path];
    // 成功 说明存在 query
    if (result == NO) {
        path = url;
    } else {
        NSString *valueStr = CFDictionaryGetValue(_routeDic, (void *)path);
        NSScanner *valueScanner = [NSScanner scannerWithString:valueStr];
        NSString *class,*function;
        if (![valueScanner scanUpToString:@"." intoString:&class]) {
            NSLog(@"保存的字符串格式错误");
            return nil;
        }
        function = [valueStr substringFromIndex:(valueScanner.scanLocation +1)];
        if (function.length < 0) {
            NSLog(@"未定义响应的函数");
            return nil;
        }
        Class target = NSClassFromString(class);
        SEL selector = NSSelectorFromString(function);
        
        NSMethodSignature *methodSign = [target methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSign];
        invocation.target = target;
        invocation.selector = selector;
        
        NSInteger index = 2;
        while ([scanner isAtEnd] == NO) {
            scanner.scanLocation += 1;
            NSString *key,*value;
            [scanner scanUpToString:@"=" intoString:&key];
            if (scanner.scanLocation +1 < scanner.string.length) {
                scanner.scanLocation += 1;
                [scanner scanUpToString:@"&" intoString:&value];
                const char *argType = [methodSign getArgumentTypeAtIndex:index];
                [invocation setArgument:&value atIndex:index];
                if (strcmp(argType, "@") != 0) {
                    NSAssert(NO, @"函数参数类型只能是字符串");
                } else {
                    [invocation setArgument:&value atIndex:index];
                }
                index ++;
            }
        }
        [invocation invoke];
        if (methodSign.methodReturnLength > 0) {
            [invocation getReturnValue:&vc];
        }
    }
    return vc;
}

#pragma mark - 读取内存段中的数据

// 初始化全局路由字典
- (void)initializeGlobalRouteDicWithSectionName:(char *)sectionName {
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
        const struct mach_header* image_header = _dyld_get_image_header(i);
        Dl_info info;
        if (dladdr(image_header, &info) == 0) {
            continue;
        }
        const void *mhp = info.dli_fbase;
        [self readConfiguration:sectionName mhp:mhp];
    }
}

- (void)readConfiguration:(char *)name mhp:(const struct mach_header *)mhp {
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *sectionData = (uintptr_t*)getsectiondata(mhp, SEG_DATA, name, &size);
#else
    uintptr_t *sectionData = (uintptr_t*)getsectiondata((void *)mhp, SEG_DATA, name, &size);
#endif
    unsigned long routeCount = size/sizeof(char *);
    if (routeCount == 0) {
        return;
    }
    NSString *keyStr = nil;
    for(int idx = 0; idx < routeCount; ++idx){
        char *urlMap = (char*)sectionData[idx];
        NSString *urlMapStr = [NSString stringWithUTF8String:urlMap];
        if ((idx & 1) == 0) {
            keyStr = urlMapStr;
            continue;
        }
        if (keyStr.length > 0 && urlMapStr.length > 0) {
            CFDictionarySetValue(self->_routeDic, (__bridge const void *)(keyStr),
                                 (__bridge const void *)(urlMapStr));
            keyStr = nil;
        }
    }
    return;
}

@end

