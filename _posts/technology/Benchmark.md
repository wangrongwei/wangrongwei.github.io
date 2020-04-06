
# Benchmark基础
Benchmark是一种评价方式。一般译成基准或标杆，Benchmark测试着眼于测试结果的可比性，按照统一的测试规范对被测试系统进行测试。测试结果间具有可比性，并可再现测试结果。</br>
Benchmark主要测试响应时间、传输速率和吞吐量等

### 性能指标
- 硬件上

硬件传输数据带宽，即带宽基准测试（Benchwidth benchmark）

数据传输延时，即延时基准测试。

- 软件上


## SPEC
SPEC是Benchmark测试规范和测试程序集中的一种，SPEC测试集包括CPU、图形/应用处理、高性能计算机/消息传输接口（MPI）、Java客户机/服务器、邮件服务器、网络文件系统、Web服务器等。

操作系统不会在操作系统服务和I/O上花大量的时间，因此测试程序基本已经移除与操作系统相关的功能。

### 单处理器
测试系统的运算速度指标，即单位工作量需要多少时间完成。

### 多处理器
测试系统的吞吐量，即系统在给定时间内完成多少工作量。

### 测试结果指标
- SPECintXXXX

单CPU计算机系统执行以整数运算为主应用软件的性能 指标。

- SPECfpXXXX

单CPU计算机系统执行以浮点运算为主的应用软件的性能指标

- SPECint-rateXXXX

多处理器执行。。。。。

- SPECfp-rateXXXX

多处理器执行以浮点运算为主应用软件的性能指标。

### 基本测试和峰值测试
CPU2017的基准程序是以源代码的形式提供，用户可以自己准备编译器，但是编译器的性能和测试选项的选择会对测试结果产生影响。因此SPEC把测试分为基本测试和峰值测试：
- 基本测试

选择基本的编译选项

- 峰值测试

对基准程序分别进行优化编译，使其性能达到最佳性能。

从架构角度度量指标：
- [1] 浮点型操作密度
- [2] 整数型操作密度
- [3] 指令中断
- [4] cache命中率
- [5] TLB命中

## CPU2017
SPEC开发的专门用于评价CPU性能的一套标准程序，主要用于桌面型和服务器型CPU的性能评价，其目的是比较不同类型CPU的整数运算和浮点型运算性能。


### Floating Point Rate Result
浮点率测试

### 分数如何计算
这里首先有一些概念，SUT（System Under Test）：被测系统，还有一个参考系统

- 计算SPECspeed Metrics</br>
time on reference machine / time on the SUT

- 计算SPECrate Metrics</br>
number of copies *(time on a reference machine / time on the SUT)

对测试出的得分取几何平均数


### 如何跑单个基准

### run-example 1
```
$ cat bindN.cfg
copies      = 4           
iterations  = 1         
output_root = /tmp/submit
runlist     = 541.leela_r
size        = test       
intrate:
   bind0    = assign_job cpu_id=11
   bind1    = assign_job cpu_id=13
   bind2    = assign_job cpu_id=17
   bind3    = assign_job cpu_id=19
   submit   = $BIND ${command}
$ runcpu --fake --config=bindN | grep '^assign' | cut -b 1-70
assign_job cpu_id=11 ../run_base_test_none.0000/leela_r_base.none test
assign_job cpu_id=13 ../run_base_test_none.0000/leela_r_base.none test
assign_job cpu_id=17 ../run_base_test_none.0000/leela_r_base.none test
assign_job cpu_id=19 ../run_base_test_none.0000/leela_r_base.none test

```

### run-example 2

```
runcpu --output_root=/Ouachita/Van --config=mine 520.omnetpp_r
These directories will be created	For these purposes
log files and reports	/Ouachita/Van/result/
520.omnetpp_r build directories	/Ouachita/Van/benchspec/CPU/520.omnetpp_r/build/
520.omnetpp_r benchmark binaries (executables)	/Ouachita/Van/benchspec/CPU/520.omnetpp_r/exe/
520.omnetpp_r run directories	/Ouachita/Van/benchspec/CPU/520.omnetpp_r/run/

```


## --debug
The 'level' referred to in the table below is selected either in the config file verbose option or in the runcpu command as in 'runcpu --verbose n'.

Levels higher than 99 are special; they are always output to your log file. You can also see them on the screen if you set verbosity to the specified level minus 100. For example, the default log level is 5. This means that on your screen you will get messages at levels 0 through 5, and 100 through 105. In your log file, you'll find the same messages, plus the messages at levels 106 through 199.

0到99的信息，只显示0----设置的level

在log文件中，100到199的信息都会记录下来。
