---
layout: article
title:  "记录本网站搭建过程"
date:   2019-05-01
categories: Day
---

# 基于skinny-bones-jekyll主题的jekyll博客搭建 #

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

### 主题修改 ###

在原博客代码的基础上，我对**__layout.scss**文件进行了如下修改：

```html

/* Top menu navigation */

.top-menu {
	display: none;
	position: relative;
	@include media($medium) {
		@include span-columns(12);
	}
	@include media($large) {
		@include span-columns(8);
		ul {
			position: absolute;
			right: 0;
		}
	}
	.home,
	.sub-menu-item {
		display: none;
	}
	li {
		a {
			font-weight: 700;
			@include font-size(16,no);
			line-height: .5 * $masthead-height; // half the height to center vertically
			color: $black;
			text-transform: uppercase;
		}
	}
}


```

以上修改将**Top menu**可容纳的长度增加到8，使最后的**about me**目录展示在第一行避免被紧接的**cover.jpg**遮挡。

## 基本使用 ##

```bash
- bundle exec jekyll build

- bundle exec jekyll serve
```

## 首页图片 ##

本博客的首页图片取自于[universetoday](https://www.universetoday.com/)，该网站致力于分享人类对宇宙的最新发现和最新探索。

## 相关引用 ##

- <https://www.jekyll.com.cn/docs/>

- <https://rubyinstaller.org/downloads/>

- <https://gems.ruby-china.com/>

- <http://jekyllthemes.org/>













