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
var Current = 0;

function closeBox () {
	document.getElementById('SSinfobox').style.visibility='hidden';
}

function init (start, max) {
	Cntr = document.getElementById('SScountr'); // now global
	Cntr.innerHTML = "<p class=\"SScntr\">"+start+"/"+max;
	Cntr.style.visibility='visible';
	Total = max;
}

function ScrollToElement (adj) {
	var eno = Current + adj;
	if (eno < 1 || eno > Total) return;

	var elem = document.getElementById('SShiltNo'+eno);
	if (elem == null) return;

	Current = eno;
	window.scrollTo(0,elem.offsetTop);
}

function skipToHilite (e) {
	var kcode = (window.event) ? e.keyCode : e.which;   // ascii values
	if ((kcode == 88) || (kcode == 110)) {
		ScrollToElement(1);
		Cntr.innerHTML = "<p class=\"SScntr\">"+Current+"/"+Total;
	} else if ((kcode == 80) || (kcode == 112)) {
		ScrollToElement(-1);
		Cntr.innerHTML = "<p class=\"SScntr\">"+Current+"/"+Total;
	}
}
