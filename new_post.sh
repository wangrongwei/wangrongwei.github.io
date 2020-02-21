#! /bin/sh

class=$1
title=$2

suffix=".md"

if [[ ! $class ]]
then
    echo "Please input a class for post"
    exit 
fi

if [[ ! $title ]]
then
    echo "Please input a title for post"
    exit 
fi


filename=$(date "+%Y-%m-%d-")
filename=$filename$title$suffix

echo $filename

dir="_posts/"$class"/"

#判断文件夹是否存在
if [ ! -d $dir ]; 
then
    echo "Please input a right class"
    echo "$class ""is't exist"
    exit
fi

filepath=$dir$filename
echo $filepath

touch $filepath

echo "New blog created as: $filename"


