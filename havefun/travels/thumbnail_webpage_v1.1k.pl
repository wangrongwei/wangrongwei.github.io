#!/usr/bin/perl -w

#thumbnail_webpage.pl
#version 1.1k
#Copyright 2003,2004 John C. Vernaleo
#Contains portions Copyright 2004 Kayhan Gultekin
#Unfortunately, I am not comfortable putting unobscured email addresses
#on the web, but these shouldn't be too hard to figure out.
#
#		(my_first_name)@netpurgatory.com
#				or
#		(my_last_name)@astro.umd.edu
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#    See readme_thumbnails.txt for more information and a copy of the GPL
#
#    Hacked by Kayhan Gultekin (kayhan$astro,umd,edu)

my $directory=$ARGV[0];
unless(defined($directory)){
    print "Type directory name with pictures: ";
    chomp($directory=<STDIN>);
}
chdir $directory or die "Cannot change to $directory: $!";

my @jpg=glob "*.jpg";
my @jpg2=glob "*.JPG";
my @gif=glob "*.gif";
my @gif2=glob "*.GIF";
my @png=glob "*.png";
my @png2=glob "*.PNG";
my @pics;

push(@pics,@jpg);
push(@pics,@jpg2);
push(@pics,@gif);
push(@pics,@gif2);
push(@pics,@png);
push(@pics,@png2);

unless (-e "thumbs"){
    mkdir "thumbs" or die "Can't make directory: $!";
}
unless (-e "pages"){
    mkdir "pages" or die "Can't make directory: $!";
}
unless (-e "medium"){
    mkdir "medium" or die "Can't make directory: $!";
}
unless (-e "fullsize"){
    mkdir "fullsize" or die "Can't make directory: $!";
}

foreach $file (@pics)
{
    my $command="convert -size 120x120 $file -resize 120x120 +profile ".'"*"'." thumbs/thum_".$file;
    system $command;
# Following two lines added by kg
    my $command2="convert -size 800x800 $file -resize 800x800 +profile ".'"*"'." medium/med_".$file;
    system $command2;
}

# kg added the following loop
foreach $file (@pics)
{
    my $command = "mv -i $file fullsize";
    system $command
}

open WEBPAGE, ">pages/pictures.html" or die "Cannot create file: $!";
select WEBPAGE;
&page_top;
&body;
close WEBPAGE;


sub page_top{
    print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'."\n";
    print '"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'."\n";
    print '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">'."\n";
    print "<head>\n";
    print '<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />'."\n";

}

sub body{
    my $i;
    my $file;
    print "<title>Pictures</title>\n";
    print "</head>\n<body>\n";
    print "<p>\n";
    for($i=0;$i<=$#pics;$i++)
    {
	$file=$pics[$i];
	select WEBPAGE;
	print '<a href="'.($i+1).'.html">';
	print '<img src="../thumbs/thum_'.$file.'" alt="'.$file.'" />';
	print "</a>\n";
	#make individual picture page
	open PAGE, ">pages/".($i+1).".html" or die "Cannot create file: $!";
	select PAGE;
	&page_top;
	print "<title>Picture ".($i+1)." of ".($#pics+1)."</title>\n";
	print "</head>\n<body>\n<p>\n";
# kg hacked the following line
	print '<a href="../fullsize/'.$file.'"><img src="../medium/med_'.$file.'" alt="'.$file.'"height="75%" width="75%"/></a>'."\n<br />\n";
	if(($i==0)||($i==$#pics)){
	    if($i==0){
		print '<a href="'.($i+2).'.html">Next Picture</a>'."\n";
	    }
	    if($i==$#pics){
		print '<a href="'.($#pics).'.html">Previous Picture</a>'."\n";
	    }
	}
	else{
	    print '<a href="'.($i).'.html">Previous Picture</a>'."\n";
	    print '<a href="'.($i+2).'.html">Next Picture</a>'."\n";
	}
	print "</p>\n</body>\n</html>";
	close PAGE;
    }
    select WEBPAGE;
    print "</p>\n</body>\n</html>";

}



