# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

#!/usr/bin/perl -Tw
use strict;

##############################################################
# site-search.cgi
################### 
# For the "all pages" search
# Mark Eriksen 2009/2010		(stallman.org)
# 1.1 Oct 2010
#	-adapted to use common methods
#	-added timer
#	-now used for both normal and regexp searches
# 1.2 (July/13) Mark Eriksen
#	- slight reorganization to use SiteSearch namespace
#	- more detailed comments
# 1.3 (April/14) M. Eriksen
#	- Adapted to use newer version of CGIutil::extractTerms.

BEGIN {	use lib 'sitesearch/lib'; }

use CGI qw(:standard);
use SiteSearch::CGIutil qw(clean checkRegexp extractTerms loadComp logger printComp setType);
use SiteSearch::RMSearch qw(checkDB getCounts);
use URI::Escape;
use Time::HiRes qw(gettimeofday tv_interval);

# Set up logging; dispatch perl warnings to the log.
my $Log = "site-search.log";
$SIG{__WARN__} = \&logwarn;
sub logwarn { logger($Log,shift) }

# Set Now array from local time
my @Now = gettimeofday();

# Output HTTP header and beginning of page.
print header();
printComp(loadComp("header.comp"),
	["TITLE","Search Results"],
	["CSS","results.css"],
	["JS",'<script type="text/javascript" src="/site-search/js/PrevNext.js"></script>'],
	["OPT",' onkeypress="npKeys(event)"']
);


# Get the search string from CGI parameters and validate it
my $SearchString = "";
$SearchString = param('term') if defined(param('term'));
clean(\$SearchString);
if ($SearchString eq "") {
	printComp(loadComp("error.comp"),
		["CAPTION","Empty Search term"],
		["ERROR","You did not enter anything to search for."]
	);
	logger($Log, "Null search");
	exit(0);
}


# Set $Raw to contain a version of $SearchString suitable for use in an URL
my $Raw = uri_escape($SearchString);
# Log $SearchString
logger($Log, "Begin search \"$SearchString\"");


# Extract an array of search phrases/terms from $SearchString.  For regexp searches,
# further validate each term.
(my $Stype, my $SpCh) = setType(param('stype'));
my @Terms = extractTerms(\$SearchString, $SpCh);
if ($Stype eq 'regexp') {
	foreach (@Terms) {
		if (my $err = checkRegexp(\$_)) {
			printComp(loadComp('error.comp'),
				['CAPTION','Try again...'],
				['ERROR',"<i>$err"]
			);
			logger($Log, "Bad regexp: $_");
			exit(0);
		}
	}
}

my $Case = 0;	# 0 = no case 1 = case sensitive
if (defined(param('case'))) { $Case = param('case') }


# Search via SiteSearch::RMSearch::checkDB.  %Pages is a hash keyed by filepath with
# RMSearch objects as values.
my %Pages = checkDB(\@Terms, $Case);

# Begin main div output.
print "<div id=\"main\">\n";

# Output search type.
if ($Stype eq 'regexp') { print '<h3 class="stype">REGULAR EXPRESSION ' }
else { print '<h3 class="stype">NORMAL ' }
if ($Case) { print"SEARCH (case sensitive)</h3>" }
else { print"SEARCH (case insensitive)</h3>" }

# For each search term, get the nummber of matches via RMSearch::getCounts() and output.
my $Counts = getCounts(\@Terms,\%Pages);
while (my ($k, $v) = each(%$Counts)) {
	$k =~ s/\\([\\\/\+\?\|\.\*\^\(\)\[\]\{\}\$])/$1/g if ($Stype eq 'norm'); # reverse escapes
	print "<h3>$k: $v</h3>";
}

# It there were no matches at all, we're done.
if (!keys(%Pages)) {
	print "<h3>... Nothing found.</h3></div></body></html>";
	my $dur = tv_interval(\@Now);
	logger($Log,$dur.'s (Nothing found)');
	exit(0);
}

print '<p class="expl">You can skip between page listings using the \'n\'ext and \'p\'revious keys (no ctrl).</p>';

# Create a list of filepaths ranked by their number of matches and output the list.
my @Ranked = sort ranklist keys(%Pages);
my $elem = 1;
foreach my $path (@Ranked) {
	print "<div class=\"section\" id=\"SSpage$elem\">\n";
	# Include a link to a a showpage.cgi invocation for the html source file.
	print "<h2><a href=\"showpage.cgi?path=$path&term=$Raw&type=$Stype&case=$Case\">$path</a></h2>";
	my $c = 1;
	# Show matches for each term for this page.
	foreach (@Terms) {
		print "<h4><em class=\"f$c\">$_</em>: ".$Pages{$path}->{$_}."</h4>";
		$c++;
		$c = 1 if ($c>4);
	}
	print "<ul>\n";
	# Use RMSearch::showitcontext() to output only the relevent lines from each file's text.
	$Pages{$path}->showithcontext();
	print "</ul></div>\n";
	$elem++;
}

# Output the html closing tags.
print "</div>\n</body></html>";

# Log the duration of the search and end.
my $dur = tv_interval(\@Now);
logger($Log, $dur.'s (Complete)');
exit(0);


## subroutines ##

sub highscore {
	my $high = 0;
	foreach (@Terms) { 
		next if (!exists $_[0]->{$_});
		$high = $_[0]->{$_} if ($_[0]->{$_} > $high);
	}
	return $high;
}


sub lowscore {
	my $low = 10000000;
	foreach (@Terms) {
		return 0 if (!exists ($_[0]->{$_}));
		$low = $_[0]->{$_} if ($_[0]->{$_} < $low) 
	}
	return $low;
}


sub ranklist {
# page ranking is by the highest number for lowest hits;
# eg, one has "this" 5 times and "that" twice, two has both terms three times, so two wins.
# if both pages do not have all terms (tied at 0) or are otherwise tied, use the highest count.
	my $one = lowscore($Pages{$a});
	my $two = lowscore($Pages{$b});
	if ($one == $two) {
		$one = highscore($Pages{$a});
		$two = highscore($Pages{$b});
	}
	$two <=> $one;
}
