#Block 的存储域
Block 有三种类型，分别是：

`__NSConcreteStackBlock ————————栈中`
`__NSConcreteGlobalBlock ————————数据区域中`
`__NSConcreteMallocBlock ————————堆中`


#__unsafe_unretained作用
那么为什么你还要使用__unsafe_unretained?不幸的是，__weak只支持iOS 5.0和OS X Mountain Lion作为部署版本。如果你想部署回iOS 4.0和OS X Snow Leopark，你就不得不用__unsafe_unretained标识符，或者用一些其他东西，就像Mike Ash的


#load和initialize
1. load和initialize的共同特点

load和initialize有很多共同特点，下面简单列一下：

在不考虑开发者主动使用的情况下，系统最多会调用一次

如果父类和子类都被调用，父类的调用一定在子类之前

都是为了应用运行提前创建合适的运行环境

在使用时都不要过重地依赖于这两个方法，除非真正必要

2. load方法相关要点

废话不多说，直接上要点列表：

调用时机比较早，运行环境有不确定因素。具体说来，在iOS上通常就是App启动时进行加载，但当load调用的时候，并不能保证所有类都加载完成且可用，必要时还要自己负责做auto release处理。

补充上面一点，对于有依赖关系的两个库中，被依赖的类的load会优先调用。但在一个库之内，调用顺序是不确定的。

对于一个类而言，没有load方法实现就不会调用，不会考虑对NSObject的继承。

一个类的load方法不用写明[super load]，父类就会收到调用，并且在子类之前。

Category的load也会收到调用，但顺序上在主类的load调用之后。

不会直接触发initialize的调用。

3. initialize方法相关要点

同样，直接整理要点：

initialize的自然调用是在第一次主动使用当前类的时候（lazy，这一点和Java类的“clinit”的很像）。

在initialize方法收到调用时，运行环境基本健全。

initialize的运行过程中是能保证线程安全的。

和load不同，即使子类不实现initialize方法，会把父类的实现继承过来调用一遍。注意的是在此之前，父类的方法已经被执行过一次了，同样不需要super调用。


# 什么是反射机制
Java的反射机制的实现要借助于4个类：class，Constructor，Field，Method;

其中class代表的时类对 象，Constructor－类的构造器对象，Field－类的属性对象，Method－类的方法对象。通过这四个对象我们可以粗略的看到一个类的各个组 成部分。

Java反射的作用：在Java运行时环境中，对于任意一个类，可以知道这个类有哪些属性和方法。对于任意一个对象，可以调用它的任意一个方法。这种动态获取类的信息以及动态调用对象的方法的功能来自于Java 语言的反射（Reflection）机制。

Java 反射机制主要提供了以下功能在运行时判断任意一个对象所属的类。

在运行时构造任意一个类的对象。

在运行时判断任意一个类所具有的成员变量和方法。

在运行时调用任意一个对象的方法

反射的常用类和函数:Java反射机制的实现要借助于4个类：Class，Constructor，Field，Method；



# 什么是程序计数器
程序计数器是用于存放下一条指令所在单元的地址的地方。当执行一条指令时，首先需要根据PC中存放的指令地址，将指令由内存取到指令寄存器中，此过程称为“取指令”。与此同时，PC中的地址或自动加1或由转移指针给出下一条指令的地址。此后经过分析指令，执行指令。完成第一条指令的执行

# iOS常用的动画
UIView动画，核心动画，帧动画，自定义转场动画

Spring动画
ios7.0以后新增了Spring动画(IOS系统动画大部分采用Spring Animation， 适用所有可被添加动画效果的属性)

UIView是用来显示内容的，可以处理用户事件

CALayer是用来绘制内容的，对内容进行动画处理依赖与UIView来进行显示，不能处理用户事件。

UIView主要是对显示内容的管理而 CALayer 主要侧重显示内容的绘制。

# iOS系统的signal可以被归为两类

**第一类内核signal**，这类signal由操作系统内核发出，比如当我们访问VM上不属于自己的内存地址时，会触发EXC_BAD_ACCESS异常，内核检测到该异常之后会发出第二类signal：BSD signal，传递给应用程序。

**第二类BSD signal**，这类signal需要被应用程序自己处理。通常当我们的App进程运行时遇到异常，比如NSArray越界访问。产生异常的线程会向当前进程发出signal，如果这个signal没有别处理，我们的app就会crash了。

平常我们调试的时候很容易遇到第二类signal导致整个程序被中断的情况，gdb同时会将每个线程的调用栈呈现出来。


# iOS内核
iOS 是基于 Apple Darwin 内核，由 kernel、XNU 和 Runtime 组成，而 XNU 是 Darwin 的内核，它是“X is not UNIX”的缩写，是一个混合内核，由 Mach 微内核和 BSD 组成。Mach 内核是轻量级的平台，只能完成操作系统最基本的职责，比如：进程和线程、虚拟内存管理、任务调度、进程通信和消息传递机制。其他的工作，例如文件操作和设备访问，都由 BSD 层实现。


# 合理的线程分配
由于 GCD 实在太方便了，如果不加控制，大部分需要抛到子线程操作都会被直接加到 global 队列，这样会导致两个问题，1.开的子线程越来越多，线程的开销逐渐明显，因为开启线程需要占用一定的内存空间（默认的情况下，主线程占1M,子线程占用512KB）。2.多线程情况下，网络回调的时序问题，导致数据处理错乱，而且不容易发现。为此，我们项目定了一些基本原则。

UI 操作和 DataSource 的操作一定在主线程。
DB 操作、日志记录、网络回调都在各自的固定线程。
不同业务，可以通过创建队列保证数据一致性。例如，想法列表的数据加载、书籍章节下载、书架加载等。
合理的线程分配，最终目的就是保证主线程尽量少的处理非UI操作，同时控制整个App的子线程数量在合理的范围内。

# NSTimer属性tolerance
在NSTimer的头文件中，苹果新增了一个属性，叫做tolerance,我们可以理解为容差。苹果的意思是如果设定了tolerance值，那么:

设定时间 <= NSTimer的启动时间 <= 设定时间 + tolerance


# 动画
为了不阻塞主线程，Core Animation 的核心是 OpenGL ES 的一个抽象物，所以大部分的渲染是直接提交给GPU来处理。 而Core Graphics/Quartz 2D的大部分绘制操作都是在主线程和CPU上同步完成的，比如自定义UIView的drawRect里用CGContext来画图。

# load加载顺序
加载顺序是父类先+load，然后子类+load，然后分类+load

# 分类category能重新方法吗
一般重载了就不会调用主类里的方法，因为分类的的load是在主类后加载，实际调用时，调用的是后添加的方法，即后添加的方法在方法列表methodLists的这个数组的顶部

答案已经很明确了：后+load的类的方法，后添加到方法列表，而这时的添加方式又是插入顶部添加，即[methodLists insertObject:category_method atIndex:0]; 所以objc_msgSend遍历方法列表查找SEL 对应的IMP时，会先找到分类重写的那个，调用执行。然后添加到缓存列表中，这样主类方法实现永远也不会调到。

但是分类UIViewController中，会先调用分类的viewDidLoad方法，然后再调用主类的viewDidLoad方法

多个category实现同一个方法
答案是：对于多个分类同时重写同一个方法，Xcode在运行时是根据buildPhases->Compile Sources里面的顺序从上至下编译的，那么很明显就像子类和分类一样，后编译的后load，即后添加到方法列表，所以后编译的分类，方法会放到方法列表顶部，调用的时候先执行。

总结一句话：类的加载顺序，决定方法的添加顺序，调用的时候，后添加的方法会先被找到，所以调用的始终是后加载的类的方法实现。


