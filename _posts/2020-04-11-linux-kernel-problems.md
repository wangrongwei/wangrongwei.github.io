---
layout: post
title: "内核问题很“内核”"
date: 2020-03-15
categories: tech
share: false
toc: true
---

> 内核开发中几个基本概念梳理

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部

> 作者：雨庭

> 本文原文地址：<http://wangrongwei.com{{ page.url }}>

## 基本概念

- 内核栈是什么？用户栈是什么？
- 进程上下文是什么？中断上下文是什么？
- 为什么中断上下文中不能发生睡眠？
- 为什么自旋锁不能睡眠？
- 逻辑地址、虚拟地址、物理地址是什么？
- 用户态是什么？内核态是什么？
- 用户抢占是什么？内核抢占是什么？
- 超线程是什么？同时多线程（SMT）是什么？



## 关联链接

- http://www.wangrongwei.com//tech/the-simple-module-of-task-switch/
