# iOS Swizzle方法替换你不知道的秘密

比如我们替换UIViewController的viewDidAppear方法为swizzle_viewDidAppear

正确标准的替换方法实现如下：

```objc

@interface ParentViewController : UIViewController
@end

@implementation ParentViewController
- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"%@ viewDidAppear",self);
    [super viewDidAppear:animated];
}
@end


@interface SubViewController : ParentViewController
@end

@implementation SubViewController
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // 原方法名和替换方法名
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(swizzle_viewDidAppear:);
        
        // 原方法结构体和替换方法结构体
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // 如果当前类没有原方法的实现IMP，先调用class_addMethod来给原方法添加默认的方法实现IMP
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {// 添加方法实现IMP成功后，修改替换方法结构体内的方法实现IMP和方法类型编码TypeEncoding
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else { // 添加失败，调用交互两个方法的实现
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)swizzle_viewDidAppear:(BOOL)animated {
    NSLog(@"%@ swizzle_viewDidAppear",self);
    [self swizzle_viewDidAppear:animated];
}
@end

```

代码说明：

`dispatch_once` 保证方法替换只被执行一次

为什么要先调用类添加方法`class_addMethod`，然后判断添加失败后，再调用方法交换实现方法`method_exchangeImplementations`？

如果我们直接调用`method_exchangeImplementations`会怎么样？ 我们先试试

```objc
2018-05-07 19:04:04.885382+0800 TestiOS[23219:477041] <ParentViewController: 0x7ffe7e424560> swizzle_viewDidAppear
2018-05-07 19:04:04.885609+0800 TestiOS[23219:477041] -[ParentViewController swizzle_viewDidAppear:]: unrecognized selector sent to instance 0x7ffe7e424560
2018-05-07 19:04:04.890484+0800 TestiOS[23219:477041] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[ParentViewController swizzle_viewDidAppear:]: unrecognized selector sent to instance 0x7ffe7e424560'
```

`ParentViewController` 先调用了swizzle的方法实现IMP，然后再调用

# 参考：

* [iOS Runtime Method精讲](http://tech.yunyingxbs.com/article/detail/id/229.html)
* [Runtime底层各个结构体](https://www.jianshu.com/p/f48ce7225cf8)
* [Runtime基础使用场景-拦截替换方法(class_addMethod ,class_replaceMethod和method_exchangeImplementations](https://www.jianshu.com/p/a6b675f4d073)