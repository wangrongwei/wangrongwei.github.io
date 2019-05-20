---
layout: article
title:  "Git与GitHub环境搭建"
date:   2019-05-20 15:58:43
categories: linux
toc: true
image:
    teaser: teaser/github.png
---

# Git与GitHub环境搭建 #

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

测试：

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
