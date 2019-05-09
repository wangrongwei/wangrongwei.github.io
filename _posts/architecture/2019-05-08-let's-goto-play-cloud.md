---
layout: article
title:  "漫谈虚拟化"
date:   2019-05-04
categories: arch
toc: true
image:
    teaser:
---

>对云平台中各框架进行简介

## OpenStack ##

一种云操作系统

## Hypervisor ##

一种运行在基础物理服务器和操作系统之间的中间软件层，可允许多个操作系统和应用贡献硬件，也可称为VMM（virtual machine monitor，虚拟机监视器）。通过Hypervisor可访问物理服务器上包括磁盘和内存在内的所有物理设备，以及对各虚拟机施加防护。当服务器启动并执行Hypervisor时，它会加载所有虚拟机客户端的操作系统同时为每台虚拟机分配适量的内存、CPU、网络和磁盘。Hypervisor类型包括：

- I型
  直接运行在系统硬件上，创建硬件全仿真实例，称为“裸机型”，例如：ACRN。

- II型
  虚拟机运行在传统操作系统上，同样创建的是硬件全仿真实例，被称为“托管”型，例如VMware：在Windows上运行Linux操作系统，主机虚拟化中VM的应用程序调用硬件资源时，需经过：VM内核->Hypervisor->主机内核，因此，II型是三种虚拟化中性能最差的。

- III型
  虚拟机运行在传统操作系统上，创建一个独立的虚拟化实例（容器），指向底层托管操作系统，被称为“操作系统虚拟化”。“操作系统虚拟化”是在操作系统中模拟出运行应用程序的容器，所有虚拟机共享内核空间，性能最好、耗费资源最少。但是底层和上层必须使用同一种操作系统，如底层操作系统使用Windows，则VPS和VE必须运行Windows。

>VPS：虚拟专用服务器（VPS，Virtual Private Server）
>VE：虚拟环境（VE, Virtual Environment）

## libvirt ##

首先，在虚拟云实现过程中，涉及到：虚拟化技术实现-虚拟机管理-集群资源管理（云管理），不同虚拟化技术提供了主要管理工具，包括启用、停用、配置和连接控制台等。这样在构建云管理时存在两个问题：

- 假设采用混合虚拟技术，上层需对不同的虚拟技术调用不同的管理工具，此时，接口不统一十分麻烦；

- 上层虚拟化技术的升级或者改动，需大幅度修改管理功能相关代码，导致开销较大；

针对以上问题，一般采用分层的思想，在虚拟机和云管理中独立出一个抽象管理层，即**libvirt**，提供各种API，供上层管理不同的虚拟机。

### libvirt主要功能 ###

libvirt主要功能如下[^1]：

- 虚拟机管理
  包含不同的领域生命周期操作，比如：启动、停止、暂停、保存、恢复和迁移。

- 远程机器支持

两个根本区别，libvirt将物理主机称为节点，将guestOS称为域

![libvirt](https://www.ibm.com/developerworks/cn/linux/l-libvirt/index.html "libvirt")

同时libvirt可实现两种控制方式，上图为第一种，guest和libvirt在同一节点下，第二种为guest和libvirt在不同的节点i下，需要实现libvirt远程控制，示意图如下：

![远程libvirt](https://www.ibm.com/developerworks/cn/linux/l-libvirt/figure2.gif)

关于Hypervisor与libvirt的关系，从下图可以看出：

![libvirt与Hypervisor关系](https://www.ibm.com/developerworks/cn/linux/l-libvirt/figure3.gif)

## qemu ##

QEMU为纯软件实现，具有整套虚拟机实现，包括在无KVM的情况下，其可独立允许，但由于纯软件但问题，其性能较低。

## kvm ##

KVM（kernel virtual machine）为Linux内核模块，依赖于硬件虚拟化（VT-X或AMDxxx）在内核层实现CPU虚拟化和内存虚拟化。

### qemu-kvm ###

由于qemu中内存、CPU以及I/O虚拟化皆为软件实现，其性能较差，因此对其代码进行修改，使用KVM中内存以及CPU虚拟化替代qemu中原内存以及CPU虚拟化方式，以此提高qemu性能。首先KVM（Kernel Virtual Machine）是Linux的一个内核驱动模块，它能够**让Linux主机成为一个Hypervisor（虚拟机监控器）**。在支持**VMX（Virtual Machine Extension）**功能的x86处理器中，Linux在原有的用户模式和内核模式中新增加了客户模式，并且客户模式也拥有自己的内核模式和用户模式，虚拟机就是运行在客户模式中。KVM模块的职责就是打开并初始化VMX功能，提供相应的接口以支持虚拟机的运行。

QEMU（quick emulator)本身并不包含或依赖KVM模块，而是一套由**Fabrice Bellard**编写的模拟计算机的自由软件。QEMU虚拟机是一个纯软件的实现，可以在没有KVM模块的情况下独立运行，但是性能比较低。QEMU有整套的虚拟机实现，包括处理器虚拟化、内存虚拟化以及I/O设备的虚拟化。**QEMU-KVM是一个用户空间的进程，需要通过特定的接口才能调用到KVM模块提供的功能。从QEMU角度来看，虚拟机运行期间，QEMU通过KVM模块提供的系统调用接口进行内核设置，由KVM模块负责将虚拟机置于处理器的特殊模式运行。QEMU使用了KVM模块的虚拟化功能，为自己的虚拟机提供硬件虚拟化加速以提高虚拟机的性能。**（需要改进）

KVM只模拟CPU和内存，因此一个客户机操作系统可以在宿主机上跑起来，但是你看不到它，无法和它沟通。于是，有人修改了QEMU代码，把他模拟CPU、内存的代码换成KVM，而网卡、显示器等留着，因此QEMU+KVM就成了一个完整的虚拟化平台。

KVM只是内核模块，用户并没法直接跟内核模块交互，需要借助用户空间的管理工具，而这个工具就是QEMU。KVM和QEMU相辅相成，QEMU通过KVM达到了硬件虚拟化的速度，而KVM则通过QEMU来模拟设备。对于KVM来说，其匹配的用户空间工具并不仅仅只有QEMU，还有其他的，比如RedHat开发的libvirt、virsh、virt-manager等，QEMU并不是KVM的唯一选择。综上所述，关于KVM与QEMU的关系可以理解为：**QEMU是个计算机模拟器，而KVM为计算机的模拟提供加速功能**。

## OPENVZ ##

## 参考 ##

[1] <https://www.cnblogs.com/zsychanpin/p/6859717.html>

[2] <https://www.cnblogs.com/boyzgw/p/6807986.html>