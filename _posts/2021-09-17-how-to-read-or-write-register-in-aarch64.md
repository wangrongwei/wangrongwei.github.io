---
layout: post
title: 如何读写aarch64的系统寄存器
excerpt: 用户空间读写寄存器不是梦！
categories: blog
comments: true
tags: arm64 aarch64 MSR 系统寄存器 system-register-tools
teaser:
    Snipaste_2021-09-18-system-register-tools.jpg
---

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
>
> 作者：lollipop
>
> 本文原文地址：<http://wangrongwei.com{{ page.url }}>

去年，我在alibaba写了一个关于读写arm64系统寄存器的一个工具，大概过去好几个月了，最近又更新了一下其中的驱动模块。
在这里简单介绍一下如何使用这个工具。

# Quick Start

快速安装：

```bash
$ git clone https://github.com/alibaba/system-register-tools
$ cd system-register-tools && make all && make install
```



另外，system-register-tools所依赖的内核模块也在该仓库下：

```bash
$ cd msr-arm && make
$ insmod msr.ko
```

完成以上两个步骤，即可使用rdasr和wrasr命令。



如何读寄存器：

```bash
$ rdasr -p0 -r MPIDR_EL1
$ rdasr -p1 -r MPIDR_EL1
```

上面两个命令分别读取core0、core1的MPIDR_EL1。



如何写寄存器：

```bash
$ wrasr -p0 -r PMCNTENCLR_EL0 0x80000000
$ wrasr -p1 -r PMCNTENCLR_EL0 0x80000000
```

到这里，rdasr和wrasr的使用大致就是如此。



# Note

由于在实现msr-arm模块的过程中，借助修改代码段的方式来实现不同寄存器的读写。这种修改代码段存在一定的风险。建议线上系统谨慎使用。



# 相关工具

x86：[https://github.com/intel/msr-tools](https://github.com/intel/msr-tools)

systemtap：[https://github.com/wangrongwei/stap/blob/master/read-msr-aarch64.stp](https://github.com/wangrongwei/stap/blob/master/read-msr-aarch64.stp)

