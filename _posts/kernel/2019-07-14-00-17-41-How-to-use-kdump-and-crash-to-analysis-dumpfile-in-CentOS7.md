---
layout: article
title:  "记录在CentOS7上采用crash分析dumpfile"
date:   2019-07-14
categories: jekyll
---

## 环境搭建

### 步骤1 安装kexec-tool

```bash
yum install kexec-tools

```

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


