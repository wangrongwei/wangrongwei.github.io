---
layout: article
title:  "记录linux系统调用整理过程"
date:   2019-03-21 01:54:43
categories: linux
toc: true
image:
    teaser: /teaser/linux.jpg
---

# linux系统调用接口 #

> 对linux系统调用进行整理，后续并给出简单的参考代码

## 一 进程控制 ##

[1] fork ： 创建一个新进程 kernel/fork.c
[2] clone ： 按指定条件创建子进程 kernel/fork.c
[3] execve ： 运行可执行文件 exec.c
[4] exit ： 终止进程 kernel/exit.c
[5] _exit ： 立即终止当前进程 
[6] getpid ： 获取进程标识号 kernel/sys.c
[7] getppind ： 获取父进程标识号
[8] pause ： 挂起进程，等待信号 kernel/signal.c
[9] vfork ： 创建一个子进程 kernel/fork.c
[10] wait ： 等待子进程终止
[11] wait3 ： 参见wait

## 二 文件系统控制 ##

[1] open ： 打开文件 fs/open.c
[2] creat ： 创建新文件 fs/open.c
[3] close ： 关闭文件描述符
[4] read ： 读文件 fs/read_write.c
[5] write ： 写文件 fs/read_write.c
[6] lseek ： 移动文件指针 fs/read_write.c

## 三 系统控制 ##

[1] ioctl ： I/O总控制函数 fs/ioctl.c
[2] _sysctl ： 读写系统参数 kernel/sysctl_binary.c
[3] time ： 取系统时间
[4] times ： 取进程时间 
[5] uname ： 获取当前UNIX系统名称、版本和主机等信息
[6] vm86 ： 进入模拟8086模式

## 四 内存管理 ##

[1] brk ： 改变数据段空间分配 mm/mmap.c
[2] sbrk ： 参加brk
[3] mlock ： 内存页面加锁 mm/mlock.c
[4] munlock ： 内存页面解锁 mm/mlock.c
[5] mlockall ： 调用进程所有内存页面加锁
[6] munlockall ： 调用进程所有内存页面解锁
[7] mmap ： 映射虚拟内存页 arch/x86/kernel/sys_x86_64.c
[8] munmap
[9] mremap
[10] msync ： 将映射内存中的数据写回磁盘
[11] mprotect ： 设置内存映像保护
[12] getpagesize ： 获取页面大小
[13] sync ： 将内存缓存区数据写回硬盘
[14] cacheflush ： 将指定缓冲区中内容写回磁盘

## 五 网络管理 ##

[1] gethostname ： 获取主机名称 kernel/sys.c

## 六 socket控制 ##

[1]

## 七 用户管理 ##

[1]

## 八 进程间通信 ##

### 1 信号 ###

[1] signal ： 信号
[2] kill ： 向进程或进程组发信号 kernel/signal.c

### 2 消息 ###

[2.1] msgsnd : 发消息 ipc/msg.c

### 3 管道 ###

[3.1] pipe ： 创建管道 fs/pipe.c

### 4 信号量 ###

### 5 共享内存 ###

[5.1] shmctl ： 控制共享内存 ipc/shm.c
[5.2] shmget ： 获取共享内存 ipc/shm.c


