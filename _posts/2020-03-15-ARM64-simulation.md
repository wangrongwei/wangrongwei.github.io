---
layout: post
title: "ARM64仿真"
categories: blog
comments: true
tags: 
teaser:
    linux-kernel.jpg
---

> 内核开发前的虚拟机搭建

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部
>
> 作者：lollipop
>
> 本文原文地址：<http://wangrongwei.com{{ page.url }}>

## 环境搭建

在内核开发中，我们经常在虚拟机环境中开发内核模块或直接修改内核代码，以及backport社区的补丁。

本文介绍内核开发者的虚拟机开发环境。



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

### 制作镜像

使用qemu-img制作镜像

```shell
qemu-img create -f qcow2 centos7-aarch64.img 10G
```



### 启动虚拟机

将以上生成的Image文件和rootfs.cpio.gz拷贝到单独的文件下，执行以下命令启动linux内核：

```bash
qemu-system-aarch64 \
    -cpu cortex-a57 \
    -machine type=virt \
    -nographic -smp 1 \
    -m 512 -kernel Image \
    -append "rdinit=/linuxrc console=ttyAMA0" \
    -initrd rootfs.cpio.gz \
    -device virtio-scsi-device
```

### 网络配置

#### Linux

qemu两种上网方式：

　　1）user mode network :

　　这种方式实现虚拟机上网很简单，类似vmware里的nat，qemu启动时加入-user-net参数，虚拟机里使用dhcp方式，即可与互联网通信，但是这种方式虚拟机与主机的通信不方便。

　　2）tap/tun network :

　　这种方式要比user mode复杂一些，但是设置好后 虚拟机<-->互联网 虚拟机<-->主机 通信都很容易。这种方式设置上类似vmware的host-only,qemu使用tun/tap设备在主机上增加一块虚拟网络设备(tun0),然后就可以象真实网卡一样配置它。

如何在虚拟机内核连接外网？

QEMU虚拟机网络的缺省模式是NAT方式，即虚拟机可以通过host访问外网，但host和外网无法访问虚拟机。如果要想让host访问虚拟机，则可以使用TAP方式。 

首先，需要安装tunctl，可采用**lsmod | grep tun**确认系统是否已经安装tun模块，若内核模块已经安装，可继续安装tunctl。

- 编写QEMU的TAP初始化脚本 

QEMU的TAP初始化脚本缺省是 /etc/qemu-ifup，它的内容很简单：

```bash
#!/bin/sh
/sbin/ifconfig $1 192.168.0.118
```

其中192.168.0.118与host的ip地址需在不同网段，另外，/etc/qemu-ifup文件需要增加可执行的权限。

- 虚拟机的网络设置

虚拟机的启动命令行增加网络参数：

```bash
-net nic -net tap
待测试的：
-net nic -net tap,ifname=tap
```

即可启动TAP网络模式。注意：因为创建TAP网卡需要root权限，所以必须用root用户启动QEMU。虚拟机启动后，用ifconfig命令设置网络，要求它的IP与host的tap网口的IP（即在上个步骤里qemu-ifup文件中设置的IP）处于同一网段。例如：

```bash
ifconfig eth0 192.168.0.119 netmask 255.255.255.0
```



#### Windows

在Windows上使用qemu虚拟机，通过此配置，可以使qemu中的虚拟机能连接互联网，并且也可以和Windows主机通信。此方式类似于Vmware和VitrualBox中的桥接网卡。配置方法如下：

1. **在Windows主机上安装TAP网卡驱动:** 可下载openvpn客户端软件，只安装其中的TAP驱动；在网络连接中，会看到一个新的网卡，属性类似于TAP-Win32 Adapter...，将其名称修改为tap0。
2. **将tap0虚拟网卡和Windows上连接互联网的真实网卡桥接:** 选中这两块网卡，右键，桥接。此时，Windows主机将不能连接互联网。重新连接WIFI使Windows主机连接互联网。
3. **qemu配置:** 在虚拟机启动命令行添加以下参数：--net nic -net tap,ifname=tap0；启动虚拟机，并配置虚拟机中的网卡，则虚拟机也可以和Windows主机一样，连接互联网和Windows主机。



##  启动CentOS或openEuler





## 补充

在编译和最后的执行内核过程中，若出现问题，可采用**file | which**两个命令对生成的可执行文件进行查看。

按Ctrl+A+X组合键退出qemu模拟器
按Ctrl+A+C组合键进入qemu-monitor，输入help可以查看操作命令

以上满足基本的aarch64开发环境需求，需另外补充：

首次安装虚拟机，采用脚本：

```bash
qemu-system-aarch64 \
    -m 2048 -cpu cortex-a57 \
    -smp 2 -M virt \
    -bios edk2-aarch64-code.fd \
    -nographic -drive if=none,file=ubuntu-18.04.4-server-arm64.iso,id=cdrom,media=cdrom \
    -device virtio-scsi-device \
    -device scsi-cd,drive=cdrom \
    -drive if=none,file=CentOS7-arm64.qcow2,id=hd0 \
    -device virtio-blk-device,drive=hd0
```

edk2-aarch64-code.fd文件来自qemu安装目录。

后续再使用时，可采用脚本：

```bash
qemu-system-aarch64 \
    -m 2048 -cpu cortex-a57 \
    -smp 2 -M virt \
    -bios edk2-aarch64-code.fd \
    -nographic -device virtio-scsi-device \
    -drive driver=qcow2,media=disk,cache=writeback,if=none,file=CentOS7-arm64.qcow2,id=hd0 \
    -device virtio-blk-device,drive=hd0
```

两个脚本分开，以防止在后续使用过程中重复安装操作。

## FAQ

- 如何制作rootfs文件系统？

- 改变方案，用现有发行版的arm64取代？

- Failed to set MokListRT: Invalid Parameter（-bios后的fd文件不对）

- 如何在qemu虚拟机内连接网络？

- 在虚拟机中键盘不匹配，无法使用vim

- 虚拟机无法ping通host，host可以ping通虚拟机？

检测路由：route -v，缺少到目的IP的路由时，采用以下命令进行添加：

```bash
route add -net 192.168.62.0 netmask 255.255.255.0 gw 192.168.1.1
```



其他启动脚本：

```bash
qemu-system-aarch64 \
        -machine virt-3.1 \
        -smp 8 \
        -m 1G,slots=2,maxmem=3G \
        -enable-kvm \
        -cpu host \
        -nographic \
        -drive if=none,file=ubuntu-16.04-server-cloudimg-arm64-uefi1.img,id=hd0 \
        -monitor unix:qemu-monitor-socket,server,nowait \
        -device virtio-blk-device,drive=hd0 \
        -qmp unix:./qmp-sock,server,nowait \
        -qmp tcp:localhost:6666,server,nowait \
        -device pcie-pci-bridge,bus=pcie.0,id=pcie-bridge-0,msi=on,x-pcie-lnksta-dllla=on,addr=2,romfile= \
        -device pci-bridge,bus=pcie-bridge-0,id=pci.0,shpc=on,msi=on,chassis_nr=1,addr=2 \
        -pflash flash0.img \
        -pflash flash1.img \
        -netdev user,id=user0 -device virtio-net-device,netdev=user0 \
```

## 参考

- https://luomuxiaoxiao.com/?p=743
- https://blog.csdn.net/linsheng_111/article/details/82996347
- https://blog.csdn.net/wujianyongw4/article/details/90289208
