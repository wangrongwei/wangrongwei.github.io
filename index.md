---
layout: archive
permalink: /
title: "Latest Posts"
image: 
    feature: cover.jpg
    credit: Rapidly Spinning Black Hole is Spitting Out Blobs of Plasma
    creditlink: https://www.universetoday.com/wp-content/uploads/2019/04/BH-Plasma-Blobs-580x326.png
---

<div class="tiles">
{% for post in site.posts %}
	{% include post-grid.html %}
{% endfor %}
</div><!-- /.tiles -->

---
layout: archive
permalink: /
title: "Latest Posts"
---

<div class="tiles">
{% for post in site.categories.arch %}
	{% include post-list.html %}
{% endfor %}
</div><!-- /.tiles -->
