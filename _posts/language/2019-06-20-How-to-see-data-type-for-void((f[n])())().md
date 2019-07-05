---
layout: article
title:  "函数指针void((f[n])())()的故事"
date:   2019-06-20 19:52:48
categories: language
toc: true
image:
    teaser: /teaser/2019-06-20-20-16-13.png
---

## 1 函数指针

**函数指针**和**指针函数**对于大多数使用C语言的程序员来说都是容易搞混的两个概念，相似的术语还有结构体指针和指针结构体、指针数组和数组指针等等，其他的类型都可以和指针结合起来。
为了更好的理解函数指针的使用方法和本质，本文打算从汇编的数据访问方式说起，从一个简单的、普通的函数指针到一个多层次的函数指针作为实验例子。

### 1.1 如何看待这些XX指针概念

下面从函数指针和指针函数的概念作为例子：

| 项目       |    指针函数 	| 函数指针  			|
| :-------- 	| --------:  			| :--:     					|
| 声明       | void *func()    |  void(*func) () 	 |
| 本质       |   指针函数的本质是一个函数，返回的是指针   		|  函数指针本质是一个指针   				|

对于指针函数来说，**func**就是函数的地址了，调用的时候就是使用这个**func()**调用；对于函数指针来说，其本质是一个指针，那么对于一个指针，就比较灵活了，它可以随时改变指向的函数。
在**void (*func)()**中，**func**不能说是一个函数了，应该说是一个指针（函数指针），因为\*func是一个函数，那么**func**就应该是一个指针。

## 2 一个简单的函数指针实现

```c
#include <stdio.h>

/*
 * 一个函数指针简单的示例
 */
void printhello(void)
{
	printf("Hello,world\n");
}

int main(int argc,char* argv[])
{
	//声明一个函数指针
	void(*hello)(void);
	//将函数的地址赋给hello
	hello = printhello;
	
	//调用函数
	(*hello)();

	return 0;
}

```

该程序就是打印一串**"hello world"**，声明一个函数指针，其实就像是声明一个指针一样，唯一的不同是不能写成：

```c
void (*)(void) hello;
```

目前的实验结果是不能写成这样的。

## 3 复杂的函数指针

前几天在微博**程序员话题**上看见一道题：

> void (*(*f[])())()
> defines f as an array of unspecified size, of pointers to functions that return pointers to functions that return void.
> 

最开始看到这道题以为还有一丝问题：“*f[]”没有指明类型，但是在VS环境下测试了一下，不是没有指明类型，而是类型不完整。
正确的写法应该是**void (*(*f[n])())()**，就是应该指明**f**这个二维数组的大小。

### 3.1 测试代码

```c
#include <stdio.h>

void boot2(void)
{
	printf("boot2\n");

	return;
}

void* boot(void)
{
	printf("boot\n");

	void(*boot2_pointer)(void);

	boot2_pointer = boot2;

	return boot2_pointer;
}


void system2(void)
{
	printf("system2\n");

	return;
}

void* system(void)
{
	printf("system\n");

	void(*system2_pointer)(void);

	system2_pointer = system2;

	return system2_pointer;
}

//二维数组的程序是函数的地址，但是不能直接使用"boot"的方式填充，可能的原因是""形式的字符串后边还有一个'\0'
//导致这个访问boot\0去了。
char* fname_list[2] = { (char*)boot, (char*)system};

int main(int argc,char* argv[])
{
	//void(*(*)())() f;
	
	//void (*  (*f[])()  )  ()
	//声明函数指针
	void (*(*f[2])())();
	f[0] = (void(*(*)())())fname_list[0];
	f[1] = (void(*(*)())())fname_list[1];

	(*(f[0])())();
	(*(f[1])())();

	return 0;
}

```

如何理解**void (*(*f[n])())()**，可以按照下面的形式分段：

```c
void (*  (*f[n])()  )  ()
```

 -  **1 --- (*f[n])**

***f[n]**是一个常规的二维数组的形式，其中的每一个**f[0]---f[n-1]**都是一个char指针，似乎这里没有指明是char指针，这个没关系，到最后都需要将这个指针强制转换成**(void(*(*)())())**，所以它是一个什么指针无所谓了。

 -  **2 --- (*f[])()**

这是第二步组合方式，其实**(*f[])()**就是一个函数指针数组，其中**f[0]---f[n-1]**代表了不同的函数指针。

 -  **3 --- * (*f[])()**

第三步才与*组合，表明其中**f[0]---f[n-1]**每一个函数指针的返回类型必须是一个指针。

- **4 --- (*  (*f[n])()  )  ()**

第四步在第三步的基础上进一步说明这个返回的指针必须是一个函数指针。

- **5 --- void (*  (*f[n])()  )  ()**

最后这个**void**最普通，表明了第四步的那个函数指针指向的函数的返回类型为**void**。

## 4 疑问

在上面的代码段中，有一段被注释掉：

```c
void(*(*)())() f;
```

最开始我认为**void(*(*)())()**是一种类型，类似**int、float**，因此可以像上面这样使用，但是这种用法是不对的，声明一个函数指针必须使用**void (*(*f[2])())()**的形式，对于上面声明方式的更接近于将**f**强制转换成**void(*(*)())()**，有些怪哉！！
