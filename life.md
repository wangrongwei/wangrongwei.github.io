---
layout: default
permalink: /life/
---

{{ site.description }}


<div class="home">

  <h1 class="page-heading">文章</h1>

  <ul class="post-list">
    {% for post in site.posts %}
      <li>
        <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        </h2>
      </li>
    {% endfor %}
  </ul>

  <p class="rss-subscribe">订阅 <a href="{{ "/feed.xml" | prepend: site.baseurl }}">via RSS</a></p>

</div>




