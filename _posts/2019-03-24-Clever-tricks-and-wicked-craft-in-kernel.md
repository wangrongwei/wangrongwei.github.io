---

layout: post
title:  "奇技淫巧@Linux Kernel"
categories: blog
comments: true
tags: programming
teaser:
    Snipaste_2020-05-23_02-00-21.jpg
---

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
>
> 作者：lollipop
>
> 本文原文地址：<http://wangrongwei.com{{ page.url }}>

## linux kernel

### aarch64

- 二进制转机器码

```c
//arch\arm64\include\asm\sysreg.h
#define __emit_inst(x)			".inst " __stringify((x)) "\n\t"
```

**.inst**为aarch64架构下的伪指令，可将二进制转换为机器码插入到程序中执行。

- alternative_if

```s
/*
 * These macros are no-ops when UAO is present.
 */
	.macro	uaccess_disable_not_uao, tmp1, tmp2
	uaccess_ttbr0_disable \tmp1, \tmp2
alternative_if ARM64_ALT_PAN_NOT_UAO
	SET_PSTATE_PAN(1)
alternative_else_nop_endif
	.endm

	.macro	uaccess_enable_not_uao, tmp1, tmp2, tmp3
	uaccess_ttbr0_enable \tmp1, \tmp2, \tmp3
alternative_if ARM64_ALT_PAN_NOT_UAO
	SET_PSTATE_PAN(0)
alternative_else_nop_endif
	.endm
```



```s
.macro alternative_if cap
	.set .Lasm_alt_mode, 1
	.pushsection .altinstructions, "a"
	altinstruction_entry 663f, 661f, \cap, 664f-663f, 662f-661f
	.popsection
	.pushsection .altinstr_replacement, "ax"
	.align 2	/* So GAS knows label 661 is suitably aligned */
661:
.endm
```

ALTERNATIVE宏会在链接阶段创建两个特殊的section .altinstructions和.altinstr_replacement,而且arch/x86/kernel/vmlinux.lds.S脚本将两个section顺序放在一起，所以可使用偏移来计算指令地址。
在内核启动的时候会调用apply_alternatives()开始修改指令，遍历.altinstructions节中的内容，判断当前cpu是否支持该特性来决定是否应该使用优化指令来覆盖原始指令，还有两个处理:

- 如果优化指令长度 > 原始指令长度，且不会覆盖，会尝试优化原始指令后面填充的nop指令
- 如果优化指令有相对跳转，对其跳转地址进行重新计算

这种方式对于发行版非常有利，能够发布一个通用的内核，在实际运行的时候自修改优化，例如在单核或SMP系统上它就能自己选择合适的指令。


### asm goto

如果启动功能，需要在开启线面的两个开关，目前Linux在x86上是强制开启的，ARM上还是根据需求来开启。

### x86

待补充

### gcc

```c
#define _RET_IP_		(unsigned long)__builtin_return_address(0)
#define _THIS_IP_  ({ __label__ __here; __here: (unsigned long)&&__here; })
```

当前地址和返回地址，主要用于栈追溯

### 其他

登录ssh，不必每次输入命令，可操作如下：

```shell
ssh-keygen -t rsa
ssh-copy-id <name>@<ip>
```

## 关联链接

- http://www.wangrongwei.com//tech/linux-kernel-problems/
