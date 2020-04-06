
# 系统环境

在ubuntu18（在虚拟机上）上安装KVM，首先需要在虚拟机设置上打开VT-d支持


# KVM环境搭建
在/proc/cpuinfo上搜索vmx，在此前提下才能进行接下来步骤

## 安装包
- sudo apt install qemu-kvm
- sudo apt install qemu
- sudo apt install virt-manager
- sudo apt install virt-vlewer
- sudo apt install libvirt-bin
- sudo apt install bridge-utils

## 安装perf

```
sudo apt install linux-tools-common

```
