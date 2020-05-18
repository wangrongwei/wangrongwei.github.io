---
layout: article
title:  "Git技巧"
date:   2019-05-20 15:58:43
categories: tech
share: false
toc: true
image:
    teaser: teaser/github.png
---

> 文章欢迎转载，但转载时请保留本段文字，并置于文章的顶部

> 作者：雨庭(rongwei)

> 本文原文地址：<http://wangrongwei.com/{{ page.url }}>

## Git ##

### Git使用 ###

首先安装Git：

```bash
yum install git
```

在git下常用的命令包括：

- git add .

- git commit -m "comment"

- git push

- git branch

- git branch branch_name

- git checkout branch_name
  切换当前分支为branch_name

## GitHub配置 ##

```bash
git config --global user.name "wangrongwei"
git config --global user.email "wangrongwei2014@gmail.com"
```

生成公钥：

```bash
ssh-keygen -t ras -C "wangrongwei2014@gmail.com"
```

以上的指令完成以后将会在~/.ssh/路径下生成id_rsa.pub等文件。接下来，需要将id_rsa.pub中的内容复制到Github的SSH and GPG keys。

测试是否绑定成功：

```bash
ssh -T git@github.com
```

## 常规使用 ##

### 其他仓库分支整理命令 ###

大致包括：

- git merge 其他分支名

- git push --delete origin 远程分支

- 修改远程分支
  第一步：删除绑定的远程分支（git push --delete origin）；
  第二步：修改本地分支的名字（git branch -m oldname newname）；
  第三步：重新提交）（git push）；  

### 回退 ###

当在某次merge中出现冲突，数量较多，无法手动解决时，可以采用回退到合适的版本重新merge。回退命令示例如下：

```bash
/* 回退到前一个 */
git reset --hard HEAD^
/* 回退到前两个 */
git reset --hard HEAD^^
/* 回退到前7个版本处 */
git reset --hard HEAD~7
```

### 初始化本地仓库和远程仓库 ###

#### 本地操作 ####

- git init
- git add . && git commit -m "init"
- git push
  第一次push将会提示出错，如：
  [error](https://img-blog.csdn.net/20171125144701517?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV0FOR19fUk9OR1dFSQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
  根据提示，需要在github上创建远程仓库。
- 添加远程仓库
  git remote add origin git@github.com:xxx/xxx.git
  git push --set-upstream origin master

### 如何更新fork仓库 ###

当fork其他开发者的仓库后，当其远程更新后，在本地，我们不能使用git pull进行更新，因此需要我们进行其他操作：

- git add remote
  添加原作者地址到本地
- git fetch --all
  fetch原作者的修改到本地，但是该命令执行完成后，本地仓库还未修改，可以通过git log查看没有最新的提交
- git rebase
  真正的更新在这一步，将原作者当前更新提交与本地融合
- git push
  将修改更新到自己的远程仓库

### 补丁相关

- 导出commit为补丁文件：git format-patch -s commit-id

- 将最新的N个commit分别生成补丁文件：git format-patch -s -N
- 获取与某feature的完整commit

## 补一张图

![image-20200404111740474](/images/image-20200404111740474.png)





