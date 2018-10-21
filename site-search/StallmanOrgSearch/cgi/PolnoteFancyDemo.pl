# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

#!/usr/bin/perl -w
use strict;

BEGIN { use lib '/home/helpers/perl/lib' }

use warnings FATAL => qw(all);
use CGI qw(:header);
use Polnote::Page;
use Polnote::Fancy;

my $dir = '/home/helpers/public_html/archives';
my $page = Polnote::Page->new($dir."/current.html");

print header();
print $_ while(<DATA>);
if (!$page) {
	print "<h2>Could not open current.html</h2>";
	print "\n</body>\n</html>";
	exit(0);
}

binmode(STDOUT,":utf8");

while (my $n = $page->nextnote()) {
	print PNfancy($n, 'http://stallman.org/archives/current.html#');
}

print "\n</body>\n</html>";

__DATA__
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
        <title>Polnote::Fancy Test</title>
        <link rel="stylesheet" type="text/css" href="http://stallman.org/site-search/css/polnote.css" />
</head>

<body>
<h1>Polnote::Fancy Test</h2>
