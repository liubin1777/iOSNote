# 检测UI卡顿

开发中，我们可以使用Xcode自带的Instruments工具的Core Animation来对APP运行流畅度进行监控，使用FPS这个值来衡量。这个工具我们只能知道哪个界面会有卡顿，无法知道到底是什么操作哪个函数导致的卡顿。
![](http://upload-images.jianshu.io/upload_images/1373592-890e2169bab4230d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

界面出现卡顿，一般是下面几种原因：
> * 主线程做大量计算
> * 主线程大量的I/O操作
> * 大量的UI绘制
> * 主线程进行网络请求以及数据处理
> * 离屏渲染


## 检测卡顿的几种方式：
### 1. NSRunloop检测卡顿
监控界面卡顿，主要是监控主线程做了哪些耗时的操作，之前的文章中已经分析过，iOS中线程的事件处理依靠的是RunLoop，正常FPS值为60，如果单次RunLoop运行循环的事件超过16ms，就会使得FPS值低于60，如果耗时更多，就会有明显的卡顿。

正常RunLoop运行循环一次的流程是这样的:

```obj-c
SetupThisRunLoopRunTimeOutTimer();
do {
        __CFRunLoopDoObservers(kCFRunLoopBeforeTimers);
        __CFRunLoopDoObservers(kCFRunLoopBeforeSources);

        __CFRunLoopDoBlocks();
        __CFRunLoopDoSource0(); // 处理source0事件，UIEvent事件，比如触屏点击

        CheckIfExitMessagesInMainDispatchQueue(); // 检查是否有分配到主队列中的任务

        __CFRunLoopDoObservers(kCFRunLoopBeforeWaiting);
        var wakeUpPort = SleepAndWaitForWakingUpPorts(); // 开始休眠，等待ma ch_msg事件

        // mach_msg_trap
        // ZZz.....   sleep
        // Received mach_msg,  wake up

        __CFRunLoopDoObservers(kCFRunLoopAfterWaiting); // 被事件唤醒
        // Handle msgs
        if (wakeUpPort == timePort) { // 被唤醒的事件是timer
              __CFRunLoopDoTimers(); 
        } else if (wakePort == mainDispatchQueuePort) { // 主队列有调度任务
              __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__();
        } else { // source1事件，UI刷新，动画显示
              __CFRunLoopDoSource1();
        }
        __CFRunLoopDoBlocks();
} while (!stop && !timeout)
```

RunLoop的执行流程由下图表示

![](http://upload-images.jianshu.io/upload_images/783864-286c96ba8f26edcc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从这个运行循环中可以看出，RunLoop休眠的事件是无法衡量的，处理事件的部分主要是在kCFRunLoopBeforeSources之后到kCFRunLoopBeforeWaiting之前和kCFRunLoopAfterWaiting 之后和运行循环结束之前这两个部分


### 2. 标记位检测UI线程超时
创建一个子线程进行循环检测，每次检测时设置标记位为YES，然后派发任务到主线程中将标记位设置为NO。接着子线程沉睡超时阙值时长，判断标志位是否成功设置成NO。如果没有说明主线程发生了卡顿，无法处理派发任务：

```obj-c
dispatch_async(lxd_event_monitor_queue(), ^{
    while (SHAREDMONITOR.isMonitoring) {
        if (SHAREDMONITOR.currentActivity == kCFRunLoopBeforeWaiting) {
            __block BOOL timeOut = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                timeOut = NO;
                dispatch_semaphore_signal(SHAREDMONITOR.eventSemphore);
            });
            [NSThread sleepForTimeInterval: lxd_time_out_interval];
            if (timeOut) {
                [LXDBacktraceLogger lxd_logMain];
            }
            dispatch_wait(SHAREDMONITOR.eventSemphore, DISPATCH_TIME_FOREVER);
        }
    }
});
```

### 3. CADisplayLink监控

从计算机的角度来说，假设屏幕在连续的屏幕刷新周期之内无法刷新屏幕内容，即是发生了卡顿。如下图第二个屏幕刷新周期出现了掉帧现象：

![](http://upload-images.jianshu.io/upload_images/783864-dbb17563cc7afbb7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

对于上述的两个方案。监听RunLoop无疑会污染主线程。死循环在线程间通信会造成大量的不必要损耗，即便GCD的性能已经很好了。因此，借鉴于MrPeak的文章，第三种方案采用CADisplayLink的方式来处理。思路是每个屏幕刷新周期派发标记位设置任务到主线程中，如果多次超出16.7ms的刷新阙值，即可看作是发生了卡顿。

![](http://upload-images.jianshu.io/upload_images/783864-84982c52c00496dc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```obj-c
#define LXD_RESPONSE_THRESHOLD 10

dispatch_async(lxd_fluecy_monitor_queue(), ^{
    CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector(screenRenderCall)];
    [self.displayLink invalidate];
    self.displayLink = displayLink;
    
    [self.displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, CGFLOAT_MAX, NO);
});

- (void)screenRenderCall {
    __block BOOL flag = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        flag = NO;
        dispatch_semaphore_signal(self.semphore);
    });
    dispatch_wait(self.semphore, 16.7 * NSEC_PER_MSEC);
    if (flag) {
        if (++self.timeOut < LXD_RESPONSE_THRESHOLD) { return; }
        [LXDBacktraceLogger lxd_logMain];
    }
    self.timeOut = 0;
}
```

# 参考资料
* [RunLoop下的卡顿监控](http://www.jianshu.com/p/582b7ad7fe4d)
* [iOS监控-卡顿检测](http://www.jianshu.com/p/ea36e0f2e7ae)