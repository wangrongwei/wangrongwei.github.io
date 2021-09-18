---
layout: post
title: "vmcore自动分析工具"
excerpt: 该文章主要是去年在阿里实习期间所写的一个vmcore自动分析工具。
categories: blog
comments: true
tags: 
teaser:
    vmcore-automatic-analysis-tool.jpg
---

> 文章转自阿里云开发者社区
>
> 作者：lollipop
>
> 本文原文地址：<https://developer.aliyun.com/article/719723?spm=a2c6h.13262185.0.0.21e82cd2ICg6IN>

## vmcore分析工具的需求变化

解决内核宕机、修复线上问题以及优化性能瓶颈是各操作系统团队工程师日常工作之一，其中大量工作依赖于crash工具对vmcore进行分析，但是应用规模以及场景的变化对其提出了新的需求。这种需求对开发者和集群运维而言，反映出不同的问题。对于开发者而言，crash工具可以满足查看vmcore中几乎所有数据的需求，例如全局变量、调度子系统以及cgroup等相关数据，但是将各类数据关联起来，需要工程师多次手动操作查看数据并与内核源码结合，其中涉及复杂的数据结构和领域知识，门槛太高，同时存在数据显示的友好程度较低等问题；对于集群运维效率而言，频繁产生的vmcore存在大量相似问题的vmcore，需求一种更加高效、精准的vmcore分析工具对频率较高的vmcore进行特征分析，以提高解决系统宕机问题的效率，现有的vmcollect系统采用panic栈进行相似度匹配，错误率较高，无法满足以上需求。

接下来，本文将对当前vmcore分析工具存在的问题进行展开，并向大家介绍一个vmcore自动分析工具，即**VAATools（Vmcore Automatic Analysis Tools）**。

## 当前vmcore分析工具存在的问题

当前，除crash工具以外，也存在其他大量基于Python、shell、perl等语言的vmcore分析工具，表1对目前已有的vmcore分析工具进行了一个简单对比。

**表 1 vmcore分析工具对比**

|              | crash | crash-Python | pykdump  | crash-extscript | analyzevmcore | drgn         |
| :----------- | :---- | :----------- | :------- | :-------------- | :------------ | :----------- |
| 语言         | c     | c/Python     | c/Python | c/perl          | shell         | C            |
| 库           | 无    | libkdumpfile | 无       | 无              | 无            | libkdumpfile |
| crash        | 否    | 否           | 是       | 是              | 是            | 否           |
| 交互方式     |       |              | 嵌套     | 套接字          | 直接          |              |
| 多vmcore支持 | 否    | 否           | 否       | 否              | 否            | 否           |
| 友好程度     | 低    | 低           | 较低     | 低              | 低            | 较低         |

表1从开发语言、依赖库以及交互方式等6个方面对当前已有的6种vmcore分析工具进行总结。在以上vmcore分析工具中，crash-extscript和analyzevmcore分别采用了perl或shell对crash进行扩展，crash-extscript采用套接字与crash进行交互，这种交互的方式非必须和唯一，可以进行优化，analyzevmcore没有较明显的特点和优点可以介绍。Pykdump提供了在crash中使用python编写命令的方法，这种方式给了工程师较大的使用和自由实现命令的空间，依赖Python可以轻松、快速的实现多种数据的对比和关联。drgn与Pykdump较相似，但不依赖于crash获取vmcore种数据，其操作方式更为灵活，语法较多。

以上6种工具提供了分析vmcore文件的基本方式，但在为vmcollect系统选择vmcore分析工具时，还需满足多个vmcore文件分析功能，同时具备更精准的vmcore分析能力，以满足集群中大量相似vmcore文件特征匹配的场景需求。

## Quick Start

针对以上问题，我们设计了一个VAATools工具，其功能包括：

1）分析获取多个或单个vmcore文件信息，支持报表信息显示task、cgroup等变量重要信息；

2）支持编写Python脚本对内核中重要数据进行获取和处理；

3）提供几个参考的使用Python编写的命令；

在VAATools中，提供了多个vmcore文件分析功能和可支持利用Python设计crash命令。接下来，对这些功能进行一个简单的介绍。

### 分析多个vmcore文件

输入vmcores所在文件夹，将各vmcore分析结果可输出到“.crash”文件下，命令如下：

```
VAATcrash -d /<path-to-vmcore-dir>/
```

输出结果包含bt、各cpu中runqueues、cfs_rq参数表格显示信息以及当前进程信息。同时，也将runq命令输出信息也保存到结果文件中，如文未链接。

VAATcrash的其他功能可借助'-h'选项查看。

### 使用Python编写的新命令

在VAATools中command目录下，提供了采用Python编写的cpu、锁信息、cgroup信息等命令。这些命令将平时需要多次操作crash命令并同时需要阅读Linux内核查看数据关联的过程进行封装为一个命令。这些命令与crash自带的命令在功能上无明显的差异，但由于Python的语言环境，设计一个Python命令可能更加容易和较快的处理一些数据和变量间关联性。

接下来，对command下的几个命令进行展示。

1）cpuinfo命令可显示vmcore中core分布以及tlb状态。如图3-1，图3-2所示。

![图 3-1 cpuinfo命令（cpuinfo -i）](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/7daa83d2d805acae26af8a4d2892a362.png)

**图 3-1 cpuinfo命令（cpuinfo -i）**

![图 3-2 cpuinfo命令（cpuinfo -t）](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/01088614a5bc7ba7b5d1c32afb99635c.png)
**图 3-2 cpuinfo命令（cpuinfo -t）**



2）可解析占用某个锁的进程信息。如图3-3所示查看发生panic时，占用“cgroup_mutex”的进程：

![cb02a1a9de0714b925d04acdcf1cd63c.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/cb02a1a9de0714b925d04acdcf1cd63c.png)

**图 3-3 lockinfo命令**

3）表格形式显示vmcore中多个同类型数据，可以明显观察出异常值。如图3-4所示。

![9f717fa45aa1340359bcce96c2690fcc.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/9f717fa45aa1340359bcce96c2690fcc.png)

**图 3-4 tasktableinfo命令**

4）层次结构类型数据显示，例如显示cgroup层次结构，如图3-5所示，显示出各级cpuset、cpu等，同时可以获取各层cpus、mem等参数值。

![0f119ace64923e8b120dd318bbe446fb.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/0f119ace64923e8b120dd318bbe446fb.png)
**图 3-5 cgroupinfo命令**

以上命令在实现过程中还可以直接通过相关的接口，如exec_crash_command，调用crash原命令，对原命令打印的数据进行处理。

## 深入了解VAATools

VAATools主要实现单个以及多个vmcore的分析功能，同时尽量采用Python进行开发，保证代码的维护性，实现较高的可视化数据显示方式。接下来，对VAATools背后的框架以及原理进行介绍。

### VAATools原理

为实现**vmcollect**系统上高效的vmcore分析工具，我们将crash中加入"Python"的元素，借助Python便于解决后续的数据处理、对比，图表显示、以及为后续部署模式匹配、机器学习算法部署搭建友好的框架。VAATools框架如图4-1所示。

![ef24bad251881372bc9ef22a2fcd20cc.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/685cdf4d94e856d32ce38a82a3706796.png)

**图 4-1 VAATools设计草图**

在VAATools中，顶层VAATcrash命令主要采用Python语言进行设计，并通过Python中的subprocess库启动一个crash进程并通过管道非阻塞的方式接收crash返回的数据。

中间层epython命令，主要基于crash提供的命令扩展功能，并借助C语言与Python之间的相互调用接口实现epython调用Python版自定义命令。另外，顶层VAATcrash通过传入的参数控制epython选择不同的vmcore分析方式，比如单个vmcore以及多个vmcore。

当前，可借鉴和使用的项目主要为开源的pykdump，其提供的各类接口满足epython与自定义命令间的功能需求。

### C与Python间相互嵌套

在VAATools中多处存在C语言中调用Python，Python中调用C的代码。在VAATools的C与Python两种语言嵌套方式的开发过程中，主要参考和借鉴了Pykdump中相关设计。VAATools依赖于Pykdump提供的库文件

### VAATools中存在的性能问题

利用Python设计VAATools，在开发上简单和快速，但是也带来了处理速率慢的问题，尤其在处理vmcore文件较多，或查看整理的变量较多时，整体处理完成的时间较长。

在VAATools设计初，已经从原先的Python与crash间进程交互方式改进为现在的Python直接调用crash内函数，同时转移多个数据获取方式到crash内部的方式。通过统计获取各种数据的等待时间，我们可以了解到当前VAATools的性能信息，图4-2为VAATools优化前后获取rq、cfs、task等数据的等待时间。

![c897add9d8c8d3e6e0b2fcddc8350555.png](https://ata2-img.cn-hangzhou.oss-pub.aliyun-inc.com/00d87e2e8b50d89542c82ea46d700c37.png)

**图 4-2 VAATools性能优化前后对比**

从上图的确可以看出优化后，VAATools改进不少，但是cfs的等待延时还是偏大，其原因在于获取cfs数据时，解析的成员变量较多。因此，如果要获取的某类数据过多，将等待很长一段时间才获取结果文件，大幅度降低debug效率。

目前，VAATools的性能还可以在VAATools的架构调整以后，有较大的提升空间。

## TODO

1）改善Python与crash间的交互；

目前，VAATools中，最外层VAATcrash命令与crash间还存在一层通过管道获取数据的方式，通过管道获取crash的数据时，需要设置等待延时，从而带来性能问题。后期可以将这一层完全改进为函数调用的方式，不再需要启动crash进程这一过程。

2）vmcore特征提取；

提取vmcore中宕机原因的特征，从而实现后续对大量的vmcore文件进行相似度分析，识别相同问题的vmcore的目标。

3）考虑是否可以将机器学习引入到vmcore；

将机器学习用于提取vmcore特征、训练vmcore特征匹配模型可能是一种vmcore特征匹配精度更高的方法。

## Links

------

[1] http://vmcore.alibaba-inc.com/

[1] https://people.redhat.com/anderson/

[2] [https://sourceforge.net/projects/pykdump/](https://sourceforge.net/projects/pykdump/?spm=a2c6h.12873639.0.0.69e56091MTLjpX)

[3] https://github.com/jeffmahoney/crash-python

[4] https://github.com/osandov/drgn

[5] https://github.com/g23guy/supportutils
