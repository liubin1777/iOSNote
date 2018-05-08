//
//  ViewController.m
//  TestRunLoop
//
//  Created by robin on 2018/5/8.
//  Copyright © 2018年 robin.com. All rights reserved.
//

/* 参考
 https://juejin.im/post/5ad17544f265da23793c9606
 https://juejin.im/entry/593fb73861ff4b006caba1a0
 */

#import "ViewController.h"
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach/port.h>
#import <mach/exception.h>
#import <mach/exception_types.h>
#import <mach/task.h>
#import <stdio.h>
#import <pthread/pthread.h>

@interface ViewController (){
    dispatch_source_t timer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __block CFRunLoopRef serialRunLoop = NULL;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_queue_t serialQueue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(serialQueue, ^{
        NSLog(@"the task run in the thread: %d", mach_thread_self());
//        [NSTimer scheduledTimerWithTimeInterval: 0.5 repeats: YES block: ^(NSTimer * _Nonnull timer) {
//            NSLog(@"ns timer in the thread: %d", mach_thread_self());
//        }];
//        serialRunLoop = [NSRunLoop currentRunLoop].getCFRunLoop;
//        [[NSRunLoop currentRunLoop] addPort: [NSPort new] forMode: NSDefaultRunLoopMode];
//        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 700]];
    });

    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mainQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(serialQueue, ^{
            NSLog(@"gcd timer in the thread: %d", mach_thread_self());
        });
//        CFRunLoopPerformBlock(serialRunLoop, NSDefaultRunLoopMode, ^{
//            NSLog(@"perform block in thread: %d", mach_thread_self());
//        });

//        CFRunLoopWakeUp(serialRunLoop);
    });
    dispatch_resume(timer);
    
}


+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"AFNetworking"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

@end
