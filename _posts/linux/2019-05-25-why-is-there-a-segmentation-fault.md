---
layout: article
title:  "为什么发生segmentation fault"
date:   2019-05-25 23:36:11
categories: linux
toc: true
image:
    teaser: /teaser/linux.jpg
---

>为什么发生段错误

## 实验 ##

```c
#include <stdio.h>

int main(int argc,char argv[])
{
    int ret;
    __asm__ __volatile__("mov %%cr0,%0":"=a"(ret));
    return 0;
}

```

对以上代码使用：gcc example1.c -o example1。
执行结果：segmentation fault
