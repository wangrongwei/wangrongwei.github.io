# lisp

## 一 简介

lisp中一行执行语句：

```lisp
(func x y)
```

- func：调用函数名
- x：函数func参数
- y：函数func参数

注释符号：分号（;）

## 二 lisp中三大经典

### 2.1 atom

可以理解为其他语言中的字符串，例如：

```lisp
(one two three)
```

该lisp语句为一行lisp语句，也可以称为list，其中包括三个atom：one two three。



### 2.2 list

list，在lisp中是一种单纯的数据结构。对于一个简单的语句，采用其他语言解释某一句，首先需要在这之前写一个该语句的解释器。但是在lisp中，每一个语句本身是一个列表，例如：

```lisp
(setf i (+ j 10)) ;i=j+10
```



### 2.3 string



## 三 lisp 函数

1. quote

2. nth

3. loop

4. format

5. car

   从列表中取出第一个原子

6. cdr

   取列表中第一个原子后的其他所有原子。

7. cddr

   取列表中第二个原子后的其他所有原子，后继的cdddr和cddddr可以上推出其含义。

8. cdddr

9. cddddr











