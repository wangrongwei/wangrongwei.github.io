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

### 安装qemu

可选择一下版本：

```bash
wget https://download.qemu.org/qemu-4.2.0.tar.xz
```

接下来，进入qemu目录，执行：

```bash
./configure --enable-virtfs --enable-debug && make -j4 && make install
```

未指明--target-list表示配置所有架构。


### 制作文件系统

- 下载

首先，选择busybox制作文件系统，需要先安装busybox，可下载如下版本：

```bash
wget https://busybox.net/downloads/busybox-1.24.2.tar.bz2
```

- 配置

接下来，需要对busybox进行配置，执行make menuconfig命令进行配置，以下两个选项需要设置：

Busybox Setting -> Build Options -> static binary(enable)
Networking Utilities -> inetd(disable)
Busybox Setting -> BusyBox installation prefix(../rootfs)

- 编译

```bash
make -j4 && make install
```

- 制作文件系统

### 制作Linux内核

可选择以下内核版本：

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.99.tar.gz
```

接下来，进入Linux目录，执行以下命令：

```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image -j8
```

编译成功的内核为arch/arm64/boot/Image

## 虚拟机管理

```bash
qemu-system-aarch64 -cpu cortex-a57 -machine type=virt -nographic -smp 1 -m 512 -kernel Image -append "rdinit=/linuxrc console=ttyAMA0" -initrd rootfs.cpio.gz -device virtio-scsi-device
```
