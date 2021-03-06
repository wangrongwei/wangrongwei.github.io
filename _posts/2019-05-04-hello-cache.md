---
layout: post
title: "漫谈cache"
categories: blog
comments: true
tags: programming
teaser:
    Snipaste_2020-05-24_14-15-39.jpg
---

>介绍cache类型、内部结构以及与CPU、I/O设备连接拓扑，并简要分析在代码中cache的踪迹。
>
>文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
>作者：lollipop
>本文原文地址：<http://wangrongwei.com{{ page.url }}>

## cache简介 ##

高速缓存（**cache**）是**CPU**内部用来加快数据访问的缓存技术。高速缓存属于**SRAM**，主存储器属于**DRAM**，一般而言主存储器一般称内存，后续我们使用内存称呼主存储器。
对于计算机程序而言，**cache**的存在是透明的，采用通俗的语言描述就是在程序中可能找不到与**cache**相关的代码，几乎在访问内存的数据时都用到了**cache**，当然前提条件是**CPU**硬件上有**cache**，其中与**cache**相关的流程已经硬件设计完成了，因此在软件上是透明的。

## cache外部模型 ##

### 计算机存储模型 ###

在对cache模型进行描述前，不得不首先提到**计算机的存储层次模型**，在计算机存储层次结构中，一般将内存分成好几个层次，计算机存储的核心思想是**缓存**，不仅仅**cache**是内存的缓存，此外可以将内存视为磁盘的缓存，磁盘可以视为远程网络资源的缓存，其存储层次模型如下：

1. 寄存器
2. L1 icache和L1 dcache（数据cache和指令cache）
3. L2 cache
4. L3 cache
5. 主存储器
6. 磁盘
7. 远程网络资源

在以上计算机存储层次模型中，数据读写的速率从寄存器到远程资源逐渐下降，可以从下图看出**CPU**对**cache**以及内存的访问时钟周期，对于**CPU**内部的寄存器，**一般用于存储程序中局部变量**，其访问时间大概为一个时钟周期，可想而知对于一个时钟为**4GHz**的**CPU**其一个时钟周期有多快。下图可能有些不足，没有说明磁盘的访问时间，这里补充说明一下：一般而言，**CPU**访问磁盘的时间大约在毫秒级左右。

![各级存储时间开销对比](https://cenalulu.github.io/images/linux/cache_line/latency.png)

> 此图来源于<https://cenalulu.github.io/images/linux/cache_line/latency.png>

有些关于存储的参考书，直接将“网络”的思想引入到计算机的存储层次模型中，他们将各存储看成是网络中的节点，他们之间的物理关系变形成了网络拓扑。大到计算机与计算机之间形成网络拓扑，小到计算机内部各设备连接形成网络拓扑，再小到CPU内部存储之间形成网络拓扑等等，从这个角度看待计算机**cache**可能会得到新的体会。

目前，大多数处理器包括三级**cache**（L1-3），例如**Intel core-i7**有四个核，其中四个核共享一个**L3 cache**，**L1 cache**和**L2 cache**是每个核私有的，下面对**Intel core-i7**包含的**cache**进行了整理，如下：

- 一个**L3 cache**
- 四个**L2cache**
- 四个**L1 icache**
- 四个**L1 dcache**

为了验证以上结论，使用**cpu-z**对一台**Intel core i7**进行测试，其结果如下：

![cpu-z测试结果](https://img-blog.csdn.net/20181007011802773?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1dBTkdfX1JPTkdXRUk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

从图中可以看出，**core i7**第七代有**6MBytes**的**L3 cache**一个、**256KBytes**的**L2 cache**四个等等。将其画成框图如下，其中只画出了其中一个核的关系图，紫色部分为一个核。

![xx](/images/arch/mem-l1-l2-l3.png)

本文在对**cache**相关技术进行研究时，采用一级**cache**进行说明，上图只是更好的说明**cache**完备的模型。

### cache内部结构 ###

上一节关于**cache**与其他元件的连接关系，以及**cache**访问速率等。接下来，进入到**cache**本身内部相关的技术，例如**cache**内部访问时路、组和标记相关的概念，**cache**本质是一个缓冲存储器，也会存在读写操作，那么**cache**的读写操作有什么玄机吗？先展示一张cache内部图，一个cache结构分成**路、组和数据**，根据路和组的映射关系，可以将其分为直接映射、全相联映射、 组相联映射三种。　   
<img src="https://img-blog.csdn.net/20181015131352508?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1dBTkdfX1JPTkdXRUk=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70" height="300" width="500">

#### 地址映射 ####　　

　　所谓映射是指如何确定**cache**中的内容是主存中的哪一部分的拷贝，即必须应用某种函数把主存地址映射到**cache**中定位，也称地址映射。当信息按这种方式装入**cache**中后，执行程序时，应将主存地址变换为**cache**地址，这个变换过程叫作地址变换。下面对三种映射进行简介，可结合上图进行理解。

- **直接映射**

　　**一个路只有一组，有多路**，每个主存地址映射到**cache**中的一个指定地址的方式，称为直接映象方式。在直接映象方式下，主存中存储单元的数据只可调入**cache**中的一个位置，如果主存中另一个存储单元的数据也要调入该位置则将发生冲突。地址映像的方法一般是将主存空间按**cache**的尺寸分区，每区内相同的块号映像到**cache**中相同的块位置。一般地，**cache**被分为2N块，主存被分为同样大小的2M块，主存与**cache**中块的对应关系可用如下映像函数表示：j = i mod 2N。式中，j是**cache**中的块号，i是主存中的块号。
　　直接映射是一种最简单的地址映像方式，它的地址变换速度快，而且不涉及其他两种映像方式中的替换策略问题。但是这种方式的块冲突概率较高，当称序往返访问两个相互冲突的块中的数据时，**cache**的命中率将急剧下降，因为这时即使**cache**中有其他空闲块，也因为固定的地址映像关系而无法应用。

- **组相联映射**
　　**一路对应多个组，有多路**。组相联映射方式是直接映射和全相联映射的一种折衷方案。这种方法将存储空间分为若干组，各组之间是直接映射，而组内各块之间则是全相联映射。它是上述两种映像方式的一般形式，如果组的大小为1，即**cache**空间分为2N组，就变为直接映射；如果组的大小为**cache**整个的尺寸，就变为了全相联映射。组相联方式在判断块命中及替换算法上都要比全相联方式简单，块冲突的概率比直接映像的低，其命中率也介于直接映射和全相联映射方式之间。 

- **全相联映射**
　　**所有的组都在一路下，只有一路**，主存中的每一个字块可映射到**cache**任何一个字块位置上，这种方式称为全相联映射。这种方式只有当**cache**中的块全部装满后才会出现块冲突，所以块冲突的概率低，可达到很高的**cache**命中率；但实现很复杂。当访问一个块中的数据时，块地址要与**cache**块表中的所有地址标记进行比较已确定是否命中。在数据块调入时存在着一个比较复杂的替换问题，即决定将数据块调入**cache**中什么位置，将**cache**中那一块数据调出主存。为了达到较高的速度，全部比较和替换都要用硬件实现。

#### 替换策略和一致性问题的处理方法 ####

　　**cache**和存储器一样具有两种基本操作，即读操作和写操作。当CPU发出读操作命令时，根据它产生的主存地址分为两种情形：

- 一种是需要的数据已在**cache**中，那么只需直接访问**cache**，从对应单元中读取信息到数据总线；

- 另一种是需要的数据尚未装入**cache**，CPU需从主存中读取信息的同时，**cache**替换部件把该地址所在的那块存储内容从主存拷贝到**cache**中；若**cache**中相应位置已被字块占满，就必须去掉旧的字块。

常见的替换策略有两种：

1. **先进先出策略（FIFO）**
　　FIFO（First In First Out）策略总是把最先调入的**cache**字块替换出去，它不需要随时记录各个字块的使用情况，较容易实现；缺点是经常使用的块，如一个包含循环程序的块也可能由于它是最早的块而被替换掉。

2. **最近最少使用策略（LRU）**
　　 LRU（Least Recently Used）策略是把当前近期**cache**中使用次数最少的那块信息块替换出去，这种替换算法需要随时记录Cache中字块的使用情况。LRU的平均命中率比 FIFO高，在组相联映像方式中，当分组容量加大时，LRU的命中率也会提高。　　

　　当CPU发出写操作命令时，也要根据它产生的主存地址分为两种情形：一种是不命中时，只向主存写入信息，不必同时把这个地址单元所在的整块内容调入**cache**中；另一种是命中时，这时会遇到如何保持**cache**与主存的一致性问题，通常有三种处理方式：

1. **直写式（write through）**
    即CPU在向**cache**写入数据的同时，也把数据写入主存以保证**cache**和主存中相应单元数据的一致性，其特点是简单可靠，但由于CPU每次更新时都要对主存写入，速度必然受影响。

2. **缓写式（post write）**
    即CPU在更新**cache**时不直接更新主存中的数据，而是把更新的数据送入一个缓存器暂存，在适当的时候再把缓存器中的内容写入主存。在这种方式下，CPU不必等待主存写入而造成的时延，在一定程度上提高了速度，但由于缓存器只有有限的容量，只能锁存一次写入的数据，如果是连续写入，CPU仍需要等待。

3. **回写式（write back）**
    即CPU只向**cache**写入，并用标记加以注明，直到**cache**中被写过的块要被进入的信息块取代时，才一次写入主存。这种方式考虑到写入的往往是中间结果，每次写入主存速度慢而且不必要。其特点是速度快，避免了不必要的冗余写操作，但结构上较复杂。

　　此外，还有一种设置不可**cache**区（Non－cacheable Block）的方式，即在主存中开辟一块区域，该区域中的数据不受**cache**控制器的管理，不能调入**cache**，CPU只能直接读写该区域的内容。由于该区域不与**cache**发生关系，也就不存在数据不一致性问题。目前微机系统的BIOS设置程序大多允许用户设置不可**cache**区的首地址和大小。

### 情景分析 ####

上一节重点介绍**cache**在电路上与**CPU**、**主存**以及**总线**、**I/O设备**之间的物理关系，**本小节将重点放在从代码级上思考cache对程序的影响**。
首先考虑一个程序存在时间和空间上的局部特性，具有良好局部特性的程序能大大提高执行效率，例如体现在执行完成的时间上。其局部特性与**cache**有重要的关系。在探讨普通应用程序与**cache**的关联之前，我们必须了解什么是程序的"局部性原理"
程序运行有以下3个特点：

1. **时间局部性**：如果一个数据/指令正在被访问，那么在近期它很可能还会被再次访问
2. **空间局部性**：在最近的将来将用到的信息很可能与正在使用的信息在空间地址上是临近的
3. **顺序局部性**：在典型程序中，除转移类指令外，大部分指令是顺序进行的

考虑这么一段程序：

```c
#include <stdio.h>

int main(int argc,char *argv[])
{
    /* 对array[][]二维数组进行按“行”赋值操作 */
    int array[10][10]={0};
    int i=0,j=0;
    for(i=0;i<10;i++){
        for(j=0;j<10;j++){
            array[i][j] = 1;
        }
    }
    retuen 0;
}
```

对于**C**语言来说，从内存角度，对一个数组存储的时，一般按照“**行**”对**array**中的数据进行存储，简而言之，**属于同一行的元素之间在内存中的地址是相邻的，上一行的最后一个元素与下一行的第一个元素是邻接的，**因此，在对**array**进行访问时，按照“行”对于上面这段程序具有良好的空间局部特性。

在**CPU**要对内存进行数据访问时，需要查看访问的数据是否在**cache**中：

- 如果在，称为命中;

- 如果不在，称为缺失。

以下图作为研究对象。

![CPU与cache网络拓扑](/images/arch/CPU-IO-cache.png)

当CPU需要读或写一个主存储器上的数据时，CPU需要发出一个地址，从硬件的角度看，硬件会先使用该地址检查是否在cache中有缓存，命中或者缺失。那么这个地址有两种可能：一是虚拟地址，没有经过MMU转换成物理地址；二是物理地址，已经由MMU转换完。对于这两种硬件上不同的设计，存在两种高速缓存：虚拟高速缓存和物理高速缓存，下面就对两种缓存展开。
