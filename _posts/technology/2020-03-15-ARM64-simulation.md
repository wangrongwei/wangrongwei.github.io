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
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make install
```

在当前文件的上一级目录下生成rootfs文件。接下来需要在rootfs中添加必要的文件。

- 制作文件系统

进入rootfs，执行以下命令

```bash
mkdir dev etc mnt
mkdir -p etc/init.d
```

进入etc/init.d中创建文件rcS，在文件中加入以下内容，并修改rcS为可执行。

```bash
mkdir -p /proc
mkdir -p /tmp
mkdir -p /sys
mkdir -p /mnt
/bin/mount -a
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
```

在etc/目录下新建一个fstab文件，加入内容如下：

```bash
proc /proc proc defaults 0 0 
tmpfs /tmp tmpfs defaults 0 0 
sysfs /sys sysfs defaults 0 0 
tmpfs /dev tmpfs defaults 0 0
debugfs /sys/kernel/debug debugfs defaults 0 0
```

在etc/ 目录下新建一个inittab文件，加入以下内容：

```bash
::sysinit:/etc/init.d/rcS 
::respawn:-/bin/sh 
::askfirst:-/bin/sh 
::ctrlaltdel:/bin/umount -a -r 
```

在dev目录下执行以下命令

```bash
mknod console c 5 1 
mknod null c 1 3
```

在rootfs目录执行以下命令

find . | cpio -o -H newc > rootfs.cpio 
gzip -c rootfs.cpio > rootfs.cpio.gz
至此，rootfs中的rootfs.cpio.gz就是制作好的文件系统

后续将以上操作写成shell脚本，可参考：

```bash
https://github.com/gengcixi/build-busybox
```

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

将以上生成的Image文件和rootfs.cpio.gz拷贝到单独的文件下，执行以下命令启动linux内核：

```bash
qemu-system-aarch64 -cpu cortex-a57 -machine type=virt -nographic -smp 1 -m 512 -kernel Image -append "rdinit=/linuxrc console=ttyAMA0" -initrd rootfs.cpio.gz -device virtio-scsi-device
```

## 补充

在编译和最后的执行内核过程中，若出现问题，可采用**file | which**两个命令对生成的可执行文件进行查看。

按Ctrl+A+X组合键退出qemu模拟器
按Ctrl+A+C组合键进入qemu-monitor，输入help可以查看操作命令

## FAQ

- 如何制作rootfs文件系统？
- 改变方案，用现有发行版的arm64取代？

QEMU_EFI.fd(下载地址：http://releases.linaro.org/components/kernel/uefi-linaro/16.02/release/qemu64/)

## 参考

- https://luomuxiaoxiao.com/?p=743
- https://blog.csdn.net/linsheng_111/article/details/82996347