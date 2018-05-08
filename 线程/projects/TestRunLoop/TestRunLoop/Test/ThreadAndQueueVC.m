//
//  ThreadAndQueueVC.m
//  TestRunLoop
//
//  Created by robin on 2018/5/8.
//  Copyright © 2018年 robin.com. All rights reserved.
//

/* 参考
 https://juejin.im/post/5a9aa633518825556a71d9f3
 http://sindrilin.com/note/2018/03/03/weird_thread.html
 https://wangwangok.github.io/2017/07/29/gcd_basic/
 */

#import "ThreadAndQueueVC.h"

@interface ThreadAndQueueVC ()

@end

@implementation ThreadAndQueueVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    dispatch_block_t task_block = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_INHERIT_QOS_CLASS, QOS_CLASS_USER_INITIATED, -8, ^{
//        NSLog(@"Start");
//        [NSThread sleepForTimeInterval:3];
//        NSLog(@"End");
//    });
//    dispatch_queue_t block_queue = dispatch_queue_create("com.example.gcd", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, 0));
//    dispatch_async(block_queue, task_block);
//    NSLog(@"Before Wait");
//    dispatch_block_wait(task_block, DISPATCH_TIME_FOREVER);
//    NSLog(@"After Wait");
    
    // 主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // 给主队列设置一个标记
    dispatch_queue_set_specific(mainQueue, "key", "main", NULL);

    // 定义一个block任务
    dispatch_block_t log = ^{
        // 判断是否是主线程
        NSLog(@"main thread: %d", [NSThread isMainThread]);
        // 判断是否是主队列
        void *value = dispatch_get_specific("key");
        NSLog(@"main queue: %d", value != NULL);
    };

    // 全局队列
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//    // 异步加入全局队列里
//    dispatch_async(globalQueue, ^{
//        // 异步加入主队列里
//        dispatch_async(dispatch_get_main_queue(), log);
//    });
    
    // 同步加入全局队列里
    dispatch_sync(globalQueue, ^{
        // 判断是否是主线程
        NSLog(@"main thread: %d", [NSThread isMainThread]);
        // 判断是否是主队列
        void *value = dispatch_get_specific("key");
        NSLog(@"main queue: %d", value != NULL);
    });

//    NSLog(@"before dispatch_main");
    // 这个方法会阻塞主线程，然后在其它子线程中执行主队列中的任务，这个方法永远不会返回
//    dispatch_main();
//    NSLog(@"after dispatch_main");
}

@end
