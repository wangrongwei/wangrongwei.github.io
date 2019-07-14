---
layout: article
title:  "记录在CentOS7上采用crash分析dumpfile"
date:   2019-07-14
categories: jekyll
---

> 本文介绍叙述在CentOS上分析dumpfile零开始过程

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
> 作者：雨庭(rongwei)
> 本文原文地址：<http://wangrongwei.github.io{{ page.url }}>

[toc]

## 环境搭建

### 步骤1 安装kexec-tool与vmlinux

```bash
yum install kexec-tools

```

默认环境下系统内无vmlinux文件，需前往[debuginfo-centos]<http://debuginfo.centos.org/7/x86_64/>下载与系统版本对应的kernel-debuginfo文件，需下载的文件主要包括：

- kernel-debuginfo-3.10.0-957.el7.x86_64.rpm
- kernel-debuginfo-common-x86_64-3.10.0-957.el7.x86_64.rpm

>尽量在linux环境下采用wget等方式下载，作者在windows下载并上传到CentOS出现问题

安装成功后，可在**/usr/lib/debug/lib/modules/3.10.0-957.el7.x86_64/**发现vmlinux文件。

### 步骤2 设置crashkernel预留内存

```bash
cat /etc/default/grup
修改crashkernel=256M
```
同时需要修改grup配置文件，并重启。

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

### 步骤3 修改kdump默认配置

```bash
vim /etc/kdump.conf
加入一行
default reboot
```

#### 步骤4 开启kdump服务

```bash
systemctl start kdump.service //启动kdump
systemctl enable kdump.service //设置开机启动
```

### 步骤5 测试kdump

```bash
service kdump status

systemctl is-active kdump.service active

```

手动触发crash

```bash
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger
```

重启后可查看在/var/crash目录下的coredump文件。

### 步骤6 执行crash

```bash
crash /usr/lib/debug/lib/modules/3.10.0-957.el7.x86_64/vmlinux /var/crash/127.0.0.1-2019-07-13-11\:49\:43/vmcore
```
