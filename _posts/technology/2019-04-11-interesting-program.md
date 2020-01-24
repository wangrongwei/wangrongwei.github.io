---
layout: article
title:  "一些无聊的代码"
date:   2019-04-11 00:54:43
categories: tech
toc: true
image:
    teaser: /teaser/system.jpg
---

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部

> 作者：雨庭(rongwei)

> 本文原文地址：<http://wangrongwei.github.io{{ page.url }}>

# 深入理解操作系统代码 #

> 在阅读过程中，对某些有意思的代码进行实现

## 程序拷贝到标准输出 ##

一个mmapcopy.c，使用mmap将一个任一大小的磁盘文件拷贝到stdout。输入文件名作为命令行参数来传递。

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>

void mmapcopy(int fd,int size);

int main(int argc,char *argv[])
{
    /* 得到文件大小 */
    int fd;
    int fd1;
    struct stat _stat;

    if(argc != 2){
        printf("usage: mmapcopy filename\n");
        return -1;
    }
    fd = open(argv[1],O_RDONLY,0);
    if(fd == -1){
        printf("%s is not exist\n",argv[1]);
        return -1;
    }
    fstat(fd,&_stat);
    /* 开始往标准输出写 */
    mmapcopy(fd,_stat.st_size);

    return 0;
}

void mmapcopy(int fd,int size)
{
    char *bufp;
    bufp =(char *)mmap(NULL,size,PROT_READ,MAP_PRIVATE,fd,0);
    write(STDOUT_FILENO,bufp,size);
    munmap(bufp,size);
    return;
}


```

实现以上功能，除使用**mmap**函数外，还存在其他较简单的方式。
