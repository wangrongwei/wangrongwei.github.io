/**
* @licstart The following is the entire license notice for the JavaScript
* code in this page.
*
* Copyright (C) 2013 Mark Eriksen
*
* The JavaScript code in this page is free software: you can redistribute
* it and/or modify it under the terms of the GNU General Public License
* (GNU GPL) as published by the Free Software Foundation, either version 3
* of the License, or (at your option) any later version.  The code is
* distributed WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU GPL
* for more details.
*
* As additional permission under GNU GPL version 3 section 7, you may
* distribute non-source (e.g., minimized or compacted) forms of that code
* without the copy of the GNU GPL normally required by section 4, provided
* you include this license notice and a URL through which recipients can
* access the Corresponding Source.
*
* @licend The above is the entire license notice for the JavaScript code
* in this page. */
var Current = 1;

function npKeys(e) {
	var kcode = (window.event) ? e.keyCode : e.which;	// browser differences
	if ((kcode == 80) || (kcode == 112)) ScrollUp();
	else if ((kcode == 78) || (kcode == 110)) ScrollDown();
}

function ScrollDown() {
	var Y = Ypos();
	var elem = document.getElementById('SSpage'+Current);

	/* find closest element below Y position */
	if (Y >= elem.offsetTop) {
		while (Y >= elem.offsetTop) {
			Current++;
			elem = document.getElementById('SSpage'+Current);
			if (elem == null) {
				Current--;
				return;
			}
		}
		window.scrollTo(0,elem.offsetTop);
		return;
	} else {
		while (Y < elem.offsetTop) {
			Current--;
			elem = document.getElementById('SSpage'+Current);
			if (elem == null) break;
		}
	}

	Current++;
	elem = document.getElementById('SSpage'+Current);
	window.scrollTo(0,elem.offsetTop);
}

function ScrollUp() {
	var Y = Ypos();
	var elem = document.getElementById('SSpage'+Current);

	/* find closest element above Y position */
	if (Y <= elem.offsetTop) {
		while (Y <= elem.offsetTop) {
			Current--;
			if (Current == 0) {
				Current = 1;
				elem = document.getElementById('SSpage'+Current);
				break;
			}
			elem = document.getElementById('SSpage'+Current);
		}
		window.scrollTo(0,elem.offsetTop);
		return;
	} else {
		while (Y > elem.offsetTop) {
			Current++;
			elem = document.getElementById('SSpage'+Current);
			if (elem == null) break;
		}
		Current--;
		elem = document.getElementById('SSpage'+Current);
	}

	window.scrollTo(0,elem.offsetTop);
}

function Ypos() {	/* browser differences... */
	return (window.pageYOffset) ? 
		window.pageYOffset : (document.documentElement.scrollTop) ? 
			document.documentElement.scrollTop : document.body.scrollTop;
}

