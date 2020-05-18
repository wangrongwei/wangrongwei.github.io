---
layout: post
title:  "一个简单的多任务切换模型"
date:   2020-03-15
categories: tech
share: false
toc: true

---

> 多任务切换的简单模型

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部

> 作者：雨庭

> 本文原文地址：<http://wangrongwei.github.io{{ page.url }}>

## 概述

在单核时代，单个进程独占一个CPU不能充分利用CPU计算能力，其中存在大量的IO等待、网络、磁盘等操作，闲置了CPU。因此，若当当前进程因等待IO的时候，CPU可以切换到另一个进程，完成另一进程的计算部分，当前一个进程IO数据返回，CPU再重新恢复该进程的上下文并继续执行后续进程代码。以上整个过程就是目前计算机中进程切换的最简单模型。本文主要对两个进程在CPU上”无缝“切换进行描述，本文后续采用切换模型或模型表示整个切换机制。

## 直奔切换模型

在一个运行操作系统的计算机上，CPU在任一时刻处于用户态或者内核态两者之一，并在这两者之间不断的切换。在切换模型中，仅仅只有当CPU处于内核态时，才能执行进程切换，并在回到用户态以后才真正开始执行新“上任”的进程。

在这里，我尝试用一张简单的图进行来说明：

![image-20200404012812351](/images/image-20200404012812351.png)

在上图中，没有提到具体的寄存器名，采用了一种比较通用的办法表示各种参与者，比如：

1）T：表示时刻，其中T1、T2分别表示进程执行系统调用进入内核态或返回用户态的两个时刻；

2）R1：表示寄存器，主要当CPU进入内核态时，记录当前的进程上下文（记录了一个进程的所有数据和资源）；

3）P1：触发事件，比如当task1的时间片用完，将会主动让出CPU；

接下来，用两个函数来实现P1发生后，如何切换R1：

```c
 /*
  * 切换进程
  * 保存eflags
  */
#define switch_to(prev,next,last) do {					\
	unsigned long esi,edi;						\
	__asm__ __volatile__("pushfl\n\t"	/* 保存eflags */		\
		     "pushl %%ebp\n\t"					\
		     "movl %%esp,%0\n\t"	/* 保存ESP */		\
		     "movl %5,%%esp\n\t"	/* 切换ESP */		\
		     "movl $1f,%1\n\t"		/* 保存EIP */		\
		     "pushl %6\n\t"		/* 切换EIP */		\
		     "jmp __switch_to\n"				\
		     "1:\t"			/* 下一次切换回到1 */		\
		     "popl %%ebp\n\t"					\
		     "popfl"						\
		     :"=m" (prev->tss.esp0),"=m" (prev->tss.eip),	\
		      "=a" (last),"=S" (esi),"=D" (edi)			\
		     :"m" (next->tss.esp0),"m" (next->tss.eip),		\
		      "2" (prev), "d" (next));				\
} while (0)
```

上面的switch_to函数中prev代表上一个进程、next代表下一个进程。在整个宏定义中，jmp __switch_to便是去执行另一个进程的程序，在跳转前需要做的：

1. 保存当前进程上下文到prev，其中的EIP保存就是**movl $1f, %1\n\t**，即是将**"1:\t"**的位置记录下来，下一次该进程切换回时，便从**"1:\t"**位置开始。
2. 开始跳转到**__switch_to**。

下面一段代码是**__switch_to**的代码：

```c
/*
  * 切换到task_[n]，首先需要检测n不是当前current，否则不做任何事；
  * 如果task_[n]用到math co-processor，需要清空TS-flag；
  */
struct task_struct fastcall * __switch_to(struct task_struct *prev, struct task_struct *next) 
{
	struct {long a,b;} __tmp;
	unsigned int eip,esp,ebp;
	esp = next->tss.esp0;
	ebp = next->tss.ebp;
	eip = next->tss.eip;
	__asm__ __volatile__("cli\n\t" \
		"mov %0, %%ecx\n\t" \
		"mov %1, %%esp\n\t" \
		"mov %2, %%ebp\n\t" \
		"mov %3, %%eax\n\t" \
		"mov $0x12345, %%eax\n\t" \
		"sti\n\t" \
		"jmp *%%ecx\t" \
		:: "r"(eip), "r"(esp), "r"(ebp), "r"(current->tss.cr3));
	return prev;
}
```

在**__switch_to**便从完成next进程的跳转过程，跳转代码即是**"jmp *%%ecx\t"**，可以简单想想一下，若该进程若不是第一次进入CPU，那这一行跳转代码将会跳转到该进程的**"1:\t"**位置。

内核的调度系统是一个特别复杂的过程，在这里仅仅展示了多个进程间切换的过程，其模型基本与linux-0.1.1中调度代码差不多，虽然简单，但基本表示了CPU是如何做到“无缝”切换进程的过程。



## FAQ

- 什么时候进行执行进程切换？

  执行系统调用或中断进入内核态以后。在进入内核态以后都可以设置进程是否需要切换的判断。

- 如何做到无缝衔接？

  这里的无缝仅仅停留在基本的切换上，如**switch_to**与**__switch_to**两个函数，可以概括为何时跳转、又如何跳转回。

- 用户态与内核态如何切换？

  系统调用或者发送中断。



## 补充

本文所涉及的代码来自我编写的UNIX386内核。

[1]: https://github.com/wangrongwei/UNIX386









