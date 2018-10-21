# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

#!/usr/bin/perl -w
use strict;

# makesearchdb -- for updating site-search database
# rev 1.1 (Sept/10):
#	-now uses HTML::Parser
#	-added @Exclude directories
# 1.2 July/13 Mark Eriksen
#	- Updated for SiteSearch namespace
# 1.3 (Sept/2013 Mark Eriksen)
#	- Removed use of SiteSearch::CGIutil::baseDir().
# 1.3.1 (Nov/2014 Mark Eriksen)
#	- Set opendir() to log instead of die in recurseDir().

BEGIN { use lib '/home/helpers/perl/lib' }

use SiteSearch::CGIutil;
use HTML::Parser;

my $Dir = $SiteSearch::CGIutil::Dir;
my $DB = "$Dir/cgi-bin/sitesearch/stallman-org.db";

my $Log = "searchdb.log";
$SIG{__WARN__} = \&logwarn;
sub logwarn { SiteSearch::CGIutil->logger($Log,shift) }

my $Par = HTML::Parser->new(api_version => 3);
$Par->handler(text=> \&gleanText, 'text');

# List of directories specifically excluded
# these should be relative to the stallman.org web root
my @Exclude = ('/temp');

# This is all of the text in most of the photos/*.html pages, so
# they will have no data and thus also go unlisted
my @Discard = ('Pictures', 'Previous Picture', 'Index', 'Next Picture', 'Click on picture for Full-Sized version.', 
	'Back to main picture page.', 'Picture \d+ of \d+');

my %Files;
recurseDir($Dir);

open (DB, ">$DB") || die "Could not open $DB: $!";
while (my ($name, $data) = each %Files) {
	next if (!$data || $data !~ /w/);
	$name =~ s/^$Dir//;
	$data =~ s/[\s\n]+/ /g;		# even whitespace
	print DB "$name *%: $data\n";
}
close(DB);

SiteSearch::CGIutil->logger($Log, "$DB updated");

##### subroutines
my $Cur = "";

sub gleanText {
	my $line = pop;
	return if ($line eq "");
	foreach (@Discard) {
		return if ($line =~ /^\s*$_\s*$/);
	}
	$Files{$Cur} .= $line;
}


sub recurseDir {
	my $dir = shift;
	if (!opendir(DIR, $dir)) {
		logwarn("Could not open \"$dir\": $!");
		return;
	}
	my @files = readdir(DIR);
	closedir(DIR);
	my @subs = ();
	foreach my $f (@files) {
		$Cur = "$dir/$f";
		next if (($f =~ /^\.\.?$/) || (-l $Cur));
		if (-d "$dir/$f") { 
			push @subs, $Cur;
			foreach (@Exclude) {
				if ($Cur eq "$Dir$_") {
					pop @subs;
					last;
				}
			}
		} elsif ($f =~ /\.html?$/) {
			$Files{$Cur} = "";
			$Par->parse_file($Cur) || warn "Couldn't parse $Cur: $!";
		}
	}
	recurseDir($_) foreach (@subs);
}
