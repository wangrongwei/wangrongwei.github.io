
//browserify -r uniq index.js > bundle.js

$(document).ready(function(){ 
	if (window.DOMParser){ 
		// Firefox, Chrome, Opera, etc.
		var yaml = require("js-yaml");
		var fs = require("fs");

		let content = fs.readFileSync("config.yml",{encoding:"utf8"});


		let result = yaml.load(content);
		console.log(JSON.stringify(result, null, 2));
		console.log(result.fn(1,3));
		console.log(result.reg.test("test"));
		console.log(result.undef);
	}
	else {
		// Internet Explorer
		var fso=new ActiveXObject(Scripting.FileSystemObject);
		var f=fso.opentextfile("../../config.txt",1,true);
		var first = f.Readline();
	}

	document.getElementById("sitename").innerHTML = first;
	f.close();

});

$(window).load(function (){ 
	
});

