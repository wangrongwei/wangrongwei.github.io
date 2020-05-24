---
layout: post
title: 如何使用该主题？
categories: blog
comments: true
tags: 
teaser:
    default.jpg
---

{{ page.title }}
===========



## ruby包下载 ##

jekyll依赖于ruby安装包，需前往[l](https://rubyinstaller.org/downloads/)下载较新的安装包。

## 修改源 ##

在进行后续步骤前，需要对ruby源进行更新，否则后续下载相关包将花费不少的时间，源更改操作如下：

```bash
- gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
- gem sources -l
```

通过以上操作，使用**gem sources -l**查看仅存在新添加的淘宝源。

## jekyll and bundler 安装 ##

```bash
- gem install jekyll bundler
```

## 选择主题 ##

目前，网上有开源的博客主题，可前面[jekyllthemes](http://jekyllthemes.org/)选择喜欢的主题下载。该博客选择的主题是**skinny-bones-jekyll**，其作者的主页如下：

[A Jekyll starter site](http://mademistakes.com/)

除以上主题外，作者也提供了其他供选择的主题。



## 配置概述

- _config.yml

主要配置文件，用户可修改站点名、邮件、Github等信息。

以下为disqus评论系统配置信息：

```
disqus_username: 你的Username
disqus: Evan
```

用户在使用该主题前，必须对其进行修改或空置，该项勿随机配置。若需要保留该配置，需前往disqus官网进行注册（需VPN）。

- blog.md

博客，对博客文章进行展示，在本主题中包括博客、学术、工程三类，对其进行分开展示。

- notice.md

博客说明。

- index.md

首页，主要对include目录下的index.html进行引用，可以进行优化。

- CNAME

个性域名，需要使用者自己购买域名配置在此处配置。

- Evan

该主题名，用户可第一时间修改。

## 配置说明

待补充。

## 其他

若使用者对jekyll的语法不够熟悉，且计划对代码和布局进行修改，推荐先阅读jekyll提供的[step-by-step](https://jekyllrb.com/docs/step-by-step/01-setup/)。

enjoy!



## 相关引用 ##

- <https://www.jekyll.com.cn/docs/>

- <https://rubyinstaller.org/downloads/>

- <https://gems.ruby-china.com/>

- <http://jekyllthemes.org/>