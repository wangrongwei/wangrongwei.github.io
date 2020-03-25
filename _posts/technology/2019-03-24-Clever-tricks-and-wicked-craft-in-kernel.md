layout: article
title:  "奇技淫巧@linux kernel"
date:   2020-03-24
categories: tech
share: false
toc: true

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
>
> 作者：雨庭(rongwei)
>
> 本文原文地址：<http://wangrongwei.github.io{{ page.url }}>

## linux kernel

### aarch64

- 二进制转机器码

```c
//arch\arm64\include\asm\sysreg.h
#define __emit_inst(x)			".inst " __stringify((x)) "\n\t"
```

**.inst**为aarch64架构下的伪指令，可将二进制转换为机器码插入到程序中执行。

### asm goto

如果启动功能，需要在开启线面的两个开关，目前Linux在x86上是强制开启的，ARM上还是根据需求来开启。











### x86

待补充