---
layout: article
title:  "ARM64仿真"
date:   2020-03-15
categories: tech
share: false
toc: true
---

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部

> 作者：雨庭(rongwei)

> 本文原文地址：<http://wangrongwei.github.io{{ page.url }}>

## 环境搭建

- 安装qemu

jinr

```
./configure --enable-virtfs --enable-debug && make -j4 && make install
```

未指明--target-list表示配置所有架构。


- 制作文件系统


- 制作Linux内核

```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image -j8
```

编译成功的内核为arch/arm64/boot/Image

