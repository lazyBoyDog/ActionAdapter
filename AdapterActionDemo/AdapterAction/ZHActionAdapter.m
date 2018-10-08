//
//  Notification.m
//  TableViewDemo
//
//  Created by zhouhui on 2018/9/17.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import "ZHActionAdapter.h"
#import <objc/runtime.h>
#import <pthread.h>

// 用来监听对象释放的时机
@interface DeallocAttachment : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL deallocSelector;
@property (nonatomic, copy) NSString *key;

@end

@implementation DeallocAttachment

- (void)dealloc {
    ((void (*)(id, SEL,...))[self.target methodForSelector:self.deallocSelector])
    (self.target, self.deallocSelector,self.key);
}

@end

typedef void(^ZHActionBlock)(id user,NSDictionary *info);

@interface ZHSeletorObject : NSObject

@property (nonatomic, assign) SEL selector;

@property (nonatomic, copy) ZHActionBlock block;

@property (nonatomic, weak) NSOperationQueue *queue;

@end

@implementation ZHSeletorObject

@end

@interface ZHActionObject : NSObject
// 方法响应对象
@property (nonatomic, weak) id target;
// 方法发送对象
@property (nonatomic, weak) id user;
// 方法参数
@property (nonatomic, copy) NSDictionary *userInfo;

- (void)sendActionKey:(NSString *)key selector:(SEL)selector;

- (void)sendActionKey:(NSString *)key queue:(NSOperationQueue *)queue selector:(SEL)selector;

- (void)sendBlockKey:(NSString *)key block:(ZHActionBlock)block;

- (void)sendBlockKey:(NSString *)key queue:(NSOperationQueue *)queue block:(ZHActionBlock)block;

- (void)selectorWithKey:(NSString *)key finish:(void (^)(NSOperationQueue *, SEL))finishBlock;

- (void)actionInvokeWithKey:(NSString *)key;

@end

@implementation ZHActionObject {
    CFMutableDictionaryRef _dic;
    pthread_mutex_t _lock;
}

- (instancetype)init {
    if (self = [super init]) {
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)sendActionKey:(NSString *)key selector:(SEL)selector {
    pthread_mutex_lock(&_lock);
    NSMethodSignature *sign = [self.target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
    invocation.target = self.target;
    invocation.selector = selector;
    CFDictionarySetValue(_dic, (__bridge const void *)(key), (__bridge const void *)invocation);
    pthread_mutex_unlock(&_lock);
}

- (void)sendActionKey:(NSString *)key queue:(NSOperationQueue *)queue selector:(SEL)selector {
    pthread_mutex_lock(&_lock);
    ZHSeletorObject *selectorObject = [[ZHSeletorObject alloc] init];
    selectorObject.queue = queue;
    selectorObject.selector = selector;
    CFDictionarySetValue(_dic, (__bridge const void *)(key), (__bridge const void *)selectorObject);
    pthread_mutex_unlock(&_lock);
}

- (void)sendBlockKey:(NSString *)key queue:(NSOperationQueue *)queue block:(ZHActionBlock)block {
    pthread_mutex_lock(&_lock);
    ZHSeletorObject *selectorObject = [[ZHSeletorObject alloc] init];
    selectorObject.queue = queue;
    selectorObject.block = block;
    CFDictionarySetValue(_dic, (__bridge const void *)(key), (__bridge const void *)selectorObject);
    pthread_mutex_unlock(&_lock);
}

- (void)sendBlockKey:(NSString *)key block:(void (^)(id, NSDictionary *))block {
    pthread_mutex_lock(&_lock);
    CFDictionarySetValue(_dic, (__bridge const void *)(key), (__bridge const void *)[block copy]);
    pthread_mutex_unlock(&_lock);
}

- (void)actionInvokeWithKey:(NSString *)key {
    pthread_mutex_lock(&_lock);
    if (self.target == nil) {
        [self blockWithKey:key finish:^(NSOperationQueue *queue, ZHActionBlock block) {
            if (!block) {
                return;
            }
            if (queue) {
                [queue addOperationWithBlock:^{
                    block(self.user, self.userInfo);
                }];
                return;
            }
            block(self.user, self.userInfo);
        }];
        return;
    }
    
    id value = CFDictionaryGetValue(_dic, (__bridge const void *)key);
    if (value == nil) {
        return;
    }
    NSInvocation *invocation;
    NSOperationQueue *queue;
    if ([value isKindOfClass:[ZHSeletorObject class]]) {
        ZHSeletorObject *selectObject = (ZHSeletorObject *)value;
        queue = selectObject.queue;
        NSMethodSignature *sign = [self.target methodSignatureForSelector:selectObject.selector];
        invocation = [NSInvocation invocationWithMethodSignature:sign];
        invocation.target = self.target;
        invocation.selector = selectObject.selector;
    } else {
        invocation = (NSInvocation *)value;
    }
    NSInteger index = 2;
    if (self.user) {
        id user = self.user;
        [invocation setArgument:&(user) atIndex:index];
        index ++;
    }
    if (self.userInfo) {
        [invocation setArgument:(__bridge void * _Nonnull)(self.userInfo) atIndex:index];
    }
    if (queue) {
        [queue addOperation:[[NSInvocationOperation alloc] initWithInvocation:invocation]];
        return;
    }
    [invocation invoke];
    pthread_mutex_unlock(&_lock);
}

- (void)blockWithKey:(NSString *)key finish:(void (^)(NSOperationQueue *, ZHActionBlock))finishBlock {
    id value = CFDictionaryGetValue(_dic, (__bridge const void *)key);
    if (value == nil) {
        return;
    }
    if ([value isKindOfClass:[ZHSeletorObject class]]) {
        ZHSeletorObject *selectObject = (ZHSeletorObject *)value;
        finishBlock(selectObject.queue, selectObject.block);
        return;
    }
    ZHActionBlock block = value;
    finishBlock(nil, block);
}

- (void)selectorWithKey:(NSString *)key finish:(void (^)(NSOperationQueue *, SEL))finishBlock {
    id value = CFDictionaryGetValue(_dic, (__bridge const void *)key);
    if (value == nil) {
        return;
    }
    if ([value isKindOfClass:[ZHSeletorObject class]]) {
        ZHSeletorObject *selectObject = (ZHSeletorObject *)value;
        finishBlock(selectObject.queue, selectObject.selector);
        return;
    }
    NSInvocation *invocation = (NSInvocation *)value;
    finishBlock(nil, invocation.selector);
}

@end


@implementation ZHActionAdapter {
    CFMutableDictionaryRef _dic;
    pthread_mutex_t _lock;
}

+ (instancetype)shareInstance {
    static ZHActionAdapter *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [ZHActionAdapter new];
        _instance->_dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
    return _instance;
}

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target selector:(SEL)selector {
    [self receiveMessageKey:key target:target associateKey:selector finishBlock:^(ZHActionObject *object) {
        object.target = target;
        [object sendActionKey:key selector:selector];
    }];
}

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target usingBlock:(void (^)(id, NSDictionary *))block {
    [self receiveMessageKey:key target:self
               associateKey:(__bridge const void * _Nonnull)(block)
                finishBlock:^(ZHActionObject *object) {
                    [object sendBlockKey:key block:block];
                }];
}

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target queue:(NSOperationQueue *)queue selector:(SEL)selector {
    [self receiveMessageKey:key target:target associateKey:selector finishBlock:^(ZHActionObject *object) {
        object.target = target;
        [object sendActionKey:key queue:queue selector:selector];
    }];
}

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target queue:(NSOperationQueue *)queue usingBlock:(void (^)(id, NSDictionary *))block {
    [self receiveMessageKey:key target:target associateKey:(__bridge const void * _Nonnull)(block) finishBlock:^(ZHActionObject *object) {
        [object sendBlockKey:key queue:queue block:block];
    }];
}

+ (void)receiveMessageKey:(NSString *)key target:(id)target associateKey:(const void *)assokey
              finishBlock:(void(^)(ZHActionObject *))finishBlock {
    ZHActionAdapter *shareInstance = [ZHActionAdapter shareInstance];
    pthread_mutex_lock(&shareInstance->_lock);
    ZHActionObject *object = CFDictionaryGetValue(shareInstance->_dic, (__bridge const void *)(NSStringFromClass([target class])));
    if (object == nil) {
        object = [[ZHActionObject alloc] init];
        CFDictionarySetValue(shareInstance->_dic, (__bridge const void *)(key), (__bridge const void *)(object));
        DeallocAttachment *attachment = [[DeallocAttachment alloc] init];
        attachment.target = shareInstance;
        attachment.deallocSelector = @selector(removeObjectWithKey:);
        attachment.key = key;
        objc_setAssociatedObject(target, assokey, attachment, OBJC_ASSOCIATION_RETAIN);
    }
    finishBlock(object);
    pthread_mutex_unlock(&shareInstance->_lock);
}

#pragma mark - ActionSenderPtotocol

+ (void)zh_sendMessageKey:(NSString *)key user:(id)user {
    [self zh_sendMessageKey:key user:user userInfo:nil];
}

+ (void)zh_sendMessageKey:(NSString *)key userInfo:(NSDictionary *)aUserInfo {
    [self zh_sendMessageKey:key userInfo:aUserInfo];
}

+ (void)zh_sendMessageKey:(NSString *)key user:(id)user userInfo:(NSDictionary *)aUserInfo {
    ZHActionAdapter *shareInstance = [ZHActionAdapter shareInstance];
    pthread_mutex_lock(&shareInstance->_lock);
    ZHActionObject *object = CFDictionaryGetValue(shareInstance->_dic, (__bridge const void *)(key));
    if (object == nil) {
        NSAssert(NO, @"the object can not be nil");
        return;
    }
    object.user = user;
    object.userInfo = aUserInfo;
    [object actionInvokeWithKey:key];
    pthread_mutex_unlock(&shareInstance->_lock);
}

- (void)sendMessageKeyComplemente:(void (^)(id target, SEL selector))completeBlock paramters:(NSString *)key, ... {
    ZHActionAdapter *shareInstance = [ZHActionAdapter shareInstance];
    pthread_mutex_lock(&shareInstance->_lock);
    ZHActionObject *object = CFDictionaryGetValue(shareInstance->_dic, (__bridge const void *)(key));
    if (object == nil) {
        NSAssert(NO, @"the object can not be nil");
        return;
    }
    [object selectorWithKey:key finish:^(NSOperationQueue *queue, SEL sel) {
        if (queue) {
            [queue addOperationWithBlock:^{
                completeBlock(object.target, sel);
            }];
            return;
        }
        completeBlock(object.target, sel);
    }];
    pthread_mutex_unlock(&shareInstance->_lock);
}

#pragma mark -

- (void)removeObjectWithKey:(NSString *)key {
    pthread_mutex_lock(&_lock);
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(key));
    pthread_mutex_unlock(&_lock);
}

@end
