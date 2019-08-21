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

## 如何通过python调用crash

在crash工具的命令行模式，可以输入bt, sys或其他内核参数查看dumpfile文件内容，因此如何一次性打开crash，并依次输入各命令并返回数据进行分析对分析内核dump原因非常有必要。
这里介绍一种方法如何通过python建立上面的进程通信方式，其中主要使用的python中的subprocess模块。

```python
import os
import time
import subprocess


p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True)

# 设置python与crash通信为非阻塞模式
fl = fcntl.fcntl(p.stdout, fcntl.F_GETFL)
fcntl.fcntl(p.stdout, fcntl.F_SETFL, fl | os.O_NONBLOCK)

# 有必要延时一会，等待crash进程执行到等待命令时刻
time.sleep(20)
while True:
        line = p.stdout.read()
        if line is None:
                break
        print(line.decode('gbk'))

```


## System.map文件


system.map内容格式为：线性地址 类型 符号



符号类型.

小写字母表示局部; 大写字母表示全局(外部). 
A 
The symbol's value is absolute, and will not be changed by further linking.

B 
The symbol is in the uninitialized data section (known as BSS).

C 
The symbol is common. Common symbols are uninitialized data. When linking, multiple common symbols may appear with the same name. If the symbol is defined anywhere, the common symbols are treated as undefined references. For more details on common symbols, see the discussion of -warn-common in Linker options.

D 
The symbol is in the initialized data section.

G 
The symbol is in an initialized data section for small objects. Some object file formats permit more efficient access to small data objects, such as a global int variable as opposed to a large global array.

I 
The symbol is an indirect reference to another symbol. This is a GNU extension to the a.out object file format which is rarely used.

N 
The symbol is a debugging symbol.

R 
The symbol is in a read only data section.

S 
The symbol is in an uninitialized data section for small objects.

T 
The symbol is in the text (code) section.

U 
The symbol is undefined.

V 
The symbol is a weak object. When a weak defined symbol is linked with a normal defined symbol, the normal defined symbol is used with no error. When a weak undefined symbol is linked and the symbol is not defined, the value of the weak symbol becomes zero with no error.

W 
The symbol is a weak symbol that has not been specifically tagged as a weak object symbol. When a weak defined symbol is linked with a normal defined symbol, the normal defined symbol is used with no error. When a weak undefined symbol is linked and the symbol is not defined, the value of the weak symbol becomes zero with no error.

- 
The symbol is a stabs symbol in an a.out object file. In this case, the next values printed are the stabs other field, the stabs desc field, and the stab type. Stabs symbols are used to hold debugging information. For more information, see Stabs.

? 
The symbol type is unknown, or object file format specific.

符号类型：大写为全局符号，小写为局部符号
A：该符号的值是不能改变的，等于const
B：该符号来自于未初始化代码段bss段
C: 该符号是通用的，通用的符号指未初始化的数据。当链接时，多个通用符号可能对应一个名称，如果该符号在某一个位置定义，这个通用符号被当做未定义的引用。不明白，内核中也没有该类型的符号
D: 该符号位于初始化的数据段
G: 位于初始化数据段，专门对应小的数据对象，比如global int x,对应的大数据对象为 数组类型等
I： 到其他符号的间接引用，是对于a.out文件的GNU扩展，使用非常少
N：调试符号
R：只读代码段的符号
S：BSS段（未初始化数据段）的小对象符号
T：代码段符号，全局函数，t为局部函数
U：未定义的符号
V：该符号是一个weak object，当其连接到为定义的对象上上，该符号的值变为0
W： 类似于V
—： 该符号是a.out文件中的一个stabs symbol，获取调试信息
？： 未知类型的符号

## 参考

- [1] https://blog.csdn.net/chun_1959/article/details/45786769


