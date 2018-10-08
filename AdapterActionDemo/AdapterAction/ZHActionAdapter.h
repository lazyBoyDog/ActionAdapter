//
//  Notification.h
//  TableViewDemo
//
//  Created by zhouhui on 2018/9/17.
//  Copyright © 2018年 zhouhui. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZHActionSenderPtotocol <NSObject>

+ (void)zh_sendMessageKey:(NSString *)key user:(id)user;

+ (void)zh_sendMessageKey:(NSString *)key userInfo:(NSDictionary *)aUserInfo;

+ (void)zh_sendMessageKey:(NSString *)key user:(id)user userInfo:(NSDictionary *)aUserInfo;

@end

@protocol ZHActionReceiverProtocol <NSObject>

/**
 key 方法的标记，推荐使用k+user+Action. 比如 kFatherControllerSayAction
 */
+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target selector:(SEL)selector;

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target queue:(NSOperationQueue *)queue selector:(SEL)selector;

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target usingBlock:(void (^)(id user,NSDictionary *info))block;

+ (void)zh_receiveMessageKey:(NSString *)key target:(id)target queue:(NSOperationQueue *)queue usingBlock:(void (^)(id user,NSDictionary *info))block;

@end

/**
 wiki:
 */

#define ZH_ActionAdapterSend(key, ...) ZHActionAdapter *shareInstance = [ZHActionAdapter shareInstance]; \
void (^block)(id, SEL) = ^(id target, SEL sel) { \
((void (*)(id, SEL,...))[target methodForSelector:sel]) \
(target, sel, ##__VA_ARGS__); \
}; \
((void (*)(id, SEL,...))[shareInstance methodForSelector:@selector(sendMessageKeyComplemente:paramters:)])  \
(shareInstance, @selector(sendMessageKeyComplemente:paramters:), block, key,##__VA_ARGS__);


#define ZH_ActionAdapterReceive(key, sel) \
[ZHActionAdapter zh_receiveMessageKey:key target:self selector:sel];

@interface ZHActionAdapter : NSObject <ZHActionSenderPtotocol, ZHActionReceiverProtocol>

+ (instancetype)shareInstance;

// 不要直接调用，暴露出来是为了去除 ZH_ActionAdapterSend 宏的编译警告
- (void)sendMessageKeyComplemente:(void (^)(id target, SEL selector))completeBlock paramters:(NSString *)key, ...;

@end
