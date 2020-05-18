
YAML = require('yamljs');


// Load yaml file using YAML.load

nativeObject = YAML.load('config.yml');

 

jsonstr = JSON.stringify(nativeObject);

jsonTemp = JSON.parse(jsonstr, null);

console.log(jsonTemp);

console.log(jsonstr);

/* 以下代码用于转换Markdown为html */
require(["jquery","StateMan","plugins/js","markdown"],function($,stateman,jx)
    /* 加载主要框架，不断回调加载 */
    jx.renderpage("x_header","templates/header.html","config/site.conf",function(obj){
        /* posts */
        jx.renderpage("x_main","templates/main.html","config/post.lst",function(obj){
            /* 监听状态 */
            var read_post = function(){
                jx.loadpage("post/"+this.param.title+".md",function(post){
                    $("#x_main").html(markdown.toHTML(post));

                });
            }
            var sm = new stateman();
            sm
            .state("home",{
                enter:function(){
                    jx.renderpage("x_main","templates/main.html","config/post.lst");
                }
            })
            .state("about",{
                enter:function(){
                    jx.renderpage("x_main","templates/about.html","");
                }
            })
            .state("post.title",{
                    url:":title",
                    enter:read_post,
                    update:read_post
            }).start({});
        });
        jx.renderpage("x_footer","templates/footer.html","");

    });

);


