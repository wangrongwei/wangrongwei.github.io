#!/usr/bin/perl -Tw
use strict;
#use warnings FATAL => qw(all);

# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

##############################################################
# showpage.cgi
# (stallman.org)
################# Mark Eriksen 12/09
# Displays pages with search hits highlighted;
# 	called from page created by site-search.cgi
# 1.1 (Jan/10)
#	-refined the use of fixPaths() to cover scripts and images
#	-spoof DOCTYPE to allow fixed position div in IE7+
# 1.2 (Sept/10)
#	-now uses HTML::Parser
#	-eval check on terms
#	-use UTF-8 to deal with wide chars
#	-added case sensitivity
#	-added logging & informative error handling
# 1.3 (Oct/10)
#	-adapted to use common methods in CGIutil
#	-added timer
# 1.3.1 (Nov/11) [security upgrade by William Demchick]
#       -checks for problematic file names (security fix)
#       -doesn't give away too much in error messages (security fix)
# 1.4 (July/13) Mark Eriksen
#	- slight reorganization to use SiteSearch namespace
#	- corrected error with SShilt indexing in relation to hlite.js
# 1.5 (June/18) Eriksen/Vernaleo
#   - Add comment to info box about javascript and functionality.

BEGIN {	use lib 'sitesearch/lib'; }

use CGI qw(:standard);
use SiteSearch::CGIutil qw(extractTerms logger setType);
use Time::HiRes qw(gettimeofday tv_interval);
use HTML::Parser;

my @Now = gettimeofday();
my $Par = HTML::Parser->new(api_version => 3);

$ENV{DOCUMENT_ROOT} =~ /^(.*?)$/;
my $Dir = $1;	# untaint;
die "Bad DOCUMENT_ROOT" if (!-d $Dir);
my $Log = "showpage.log";
$SIG{__WARN__} = \&logwarn;
sub logwarn { logger($Log,shift) }


### parameters
if (!defined param('path') || !defined param('type') || !defined param('case') || !defined param('term')) {
	logger($Log,"ERROR: Improper parameters.");
	death('<p>Please use the form: <a href="/site-search/index.html">Site Search</a></p>');
}

if (param('path') =~ /(\.\.)|(\.(php|cgi|pl|dhtml|py)$)/) {
    logger($Log, "ERROR: Possible cracking attempt.");
    death('Potential unauthorized entry detected.  If you got this page accidentially, please <a href="http://stallman.org/">click here</a> to continue.');
}

my $File = $Dir.param('path');
$File =~ /$Dir(.*?)([^\/]+)$/;
my $PPath = $1;
my $Short = $2;

(my $Type, my $SpCh) = setType(param('type'));

my $Case = param('case');
$Case = 0 if (!$Case);

my $TCopy = my $tmp = param('term');

my @Terms;
foreach (extractTerms(\$tmp,$SpCh)) {
# this eval is just to protect against spoofing
	eval { (my $test = "whatever") =~ /$_/ };
	push @Terms, $_ unless($@);
}

### Stage 1: text only/search
my $PText = "";	# the text
my @EM = ();	# array of search finds
my $HeadLen = 0;	# length of (non-highlightable) text in <head>
$Par->handler(declaration=> "");
$Par->handler(start=> "");
$Par->handler(comment=> "");
$Par->handler(end=> sub { 
		if (shift eq "head") {
			$Par->handler(end=> "");
			$HeadLen = length($PText);
		}
	}, 'tagname');
$Par->handler(text=> sub { $PText .= shift; }, 'text');

unless ($Par->parse_file($File)) {
	logger($Log,"ERROR: Couldn't parse $File");
	death("<p>Hi-lighting failed.</p>");
}

foreach my $term (@Terms) {
	if ($Case) {
		while ($PText =~ /($term)/g) { setEMPos($1) }
	} else {
		while ($PText =~ /($term)/gi) { setEMPos($1) }
	}
}

@EM = sort{$$a[0] <=> $$b[0]}@EM;


### Stage 2: process HTML, add <em>
$PText = "";
my $MK = 0;	# position in text stream
my $EMtag = '<em class="sshlite" id="SShiltNo';
my $Count = ($#EM+1)/2;
my $Cur = 0;
$Par->handler(declaration=> sub {	# make IE7 recognize fixed divs
		$PText .= '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" '.
			'"http://www.w3.org/TR/html4/loose.dtd">'."\n";
	}, 'text');
$Par->handler(start=> \&startTags, 'tagname, attr, text');
$Par->handler(end=> \&endTags, 'tagname, text');
$Par->handler(comment=> sub { $PText .= (pop) }, 'text');
$Par->handler(text=> \&markupText, 'text');

my $FH;
die unless (open($FH, "<$File"));
#binmode($FH,':utf8');	# eliminates "Parsing of undecoded UTF-8" error but screws up display
$Par->parse_file($FH);
close($FH);

# output: deal with wide characters
print header(-charset=>"UTF-8");
binmode STDOUT,':utf8';
print $PText;
my $dur = tv_interval(\@Now);
logger($Log,$dur."s: $PPath$Short for \"$TCopy\"");

exit 0;


### Subroutines, alphabetically ###

sub death {
	print header();
	print '<html><head><title>Search Error - Stallman.org</title></head><body>'.
		"\n<h1>Search Error</h1>\n".(shift).'</body></html>';
	exit 0;
}

sub endTags {
		(my $tag, my $txt) = @_;
		if ($tag eq "body") { 
			$PText .= "\n<script type=\"text/javascript\">init(0,$Count);</script>\n";
		} elsif ($tag eq "head") {
			$PText .= "\n".'<link rel="stylesheet" type="text/css" href="/site-search/css/hlite.css"/>'."\n".
				'<script type="text/javascript" src="/site-search/js/hlite.js"></script>'."\n</head>\n\n";
		}
		$PText .= "$txt\n";
}


sub fixPaths {
	(my $tag, my $attr, my $find) = @_;
	$PText .= "<$tag";
	while (my ($n, $v) = each %$attr) {
		next if ($n eq '/');	# HTML::Parser does this with end closed tags (eg, <br/>)
		$PText .= " $n=\"";
		if ($n eq $find) {
			if ($v =~ /^\s*mailto:/ || $v =~ /^\s*\w+:\/\// || $v =~ /^\s*\/\//) {
			} elsif ($v =~ s/^$Short#/$PPath$Short#/) {		# local anchors redirect to real page
			} elsif ($v =~ s/^#/$PPath$Short#/) {
			} else { $v =~ s/^([^\/]+)/$PPath$1/ }	# other stallman.org pages
		}
		$PText .= "$v\"";
	}
	$PText .= ">\n";
}


sub markupText {
	my $txt = shift;
	my $len = length($txt);
	my $cur = $MK+$len;
	# get positions for this segment in reverse order
	# so they can be inserted without complication
	my @add = ();
	unshift @add, shift @EM while ($#EM != -1 && $cur > $EM[0]->[0]);
	foreach my $a (@add) {
		if ($$a[1] == 1) {
			$Cur++;
			substr($txt, $$a[0]-$MK, 0) = $EMtag.$Cur.'">';
		} else { substr($txt, $$a[0]-$MK, 0) = '</em>' }
	}
	$MK += $len;
	$PText .= $txt;
}


sub setEMPos {
		my $cur = pos($PText);
		return if ($cur < $HeadLen);
		my @s = ($cur-length(shift),1);
		my @e = ($cur,2);
		push @EM,\@s;
		push @EM,\@e;
}


sub startTags {
	(my $tag, my $attr, my $text) = @_;
	if ($tag eq "a") { fixPaths($tag, $attr, "href") }
	elsif ($tag eq "head") {
		my $body = <<'ENDOC';
<head>
<script type="text/javascript">
<!--//--><![CDATA[//><!--
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
//--><!]]>
</script>
ENDOC
		$PText .= "$body\n";
	}
	elsif ($tag eq "link") { fixPaths($tag, $attr, "href") }
	elsif ($tag eq "img") { fixPaths($tag, $attr, "src") }
	elsif ($tag eq "script") { fixPaths($tag, $attr, "src") }
	elsif ($tag eq "body") {
		my $body = '<body onkeypress="skipToHilite(event,'.$Count.');';
		my $tmp = "";
		while (my ($n,$v) = each(%$attr)) {
			if ($n eq "onkeypress") {
				$body .= "$v\"";
			} else {
				$tmp .= " $n=\"$v\"";
			}
		}
		$body .= "\" $tmp>\n";
		$body .= << "ENDOC";
	<div id="SScountr"></div>
	<div id="SSinfobox">
	<p class="hlinfo">This is a slightly altered version of the page. All the search hits have been 
	<em class="sshlite">highlighted in yellow</em>.  
	<p class="hlinfo">You can move between finds using the 'n'ext and 
	'p'revious keys (no CTRL). There should be a small 
	counter top left showing your current position. <i>These hotkeys work only if JavaScript is enabled.</i></p>
	<p class="hlinfo">This is unrelated to your browser's own "find" function -- you can use that at the same time.
	To use the real page instead click <a href="$PPath$Short">here</a>. 
	<p class="hlinfo">Note that broad regexps (eg.
	"foo.*?bar") may not match as much here as they do in the "Search Results".  The same is true for terms that include
	whitespace (you can prevent this by using a regular expression and <b>\\s+</b> instead of spaces).</p>
	</div>
ENDOC
		$PText .= "$body\n";
	} else { $PText .= $text }
}
