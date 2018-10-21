#!/usr/bin/perl -Tw

# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

use strict;

##############################################################
# polnote-search.cgi
################### 
# Mark Eriksen 2010		(stallman.org)
# 6/20/10 bugfix (empty terms after splitting search string)
# 1.1 (Oct/2010 M. Eriksen)
#	- updated to work with new makepolnoteDB.pl
#	- multiple term regular expression searching
#	- case sensitivity
#	- bucket sort by terms hit
#	- timer
#	- UTF8
#	- 1000 note page limit
# 1.2 (July/2013 M. Eriksen)
#	- slight reorganization to use SiteSearch namespace
# 1.3 (Sept/2013 M. Eriksen)
#	- Tidied, simplified, and improved comments.
# 1.4 (April/2013 M. Eriksen)
#	- Fixed bug with "terms hit" sorting.
#	- Tidied explanatory header.
#	- Allow for spaces in parenthesized regex term.
# 1.4.1 (June/2018 M.Eriksen)
#   - Removed reference to non-existent CGIutil::fatal method.
#   - Changed param('stype') call to silence spurious CGI warning.

BEGIN { use lib 'sitesearch/lib'; }

# This script responds to polnote search requests, which are returned to the client in
# (large) limited batches, and to subsequent requests for further batches from the same
# search; this data is saved temporarily in the 'tmp_data' directory. When returned,
# each batch contains a hidden form with the parameters needed for the next batch, if any.

use CGI qw(:standard);
use Time::HiRes qw(gettimeofday tv_interval);
use SiteSearch::CGIutil qw(clean checkRegexp extractTerms hiddenForm loadComp logger printComp setType);
use SiteSearch::PNSearch;

binmode (STDOUT,':utf8');

my $PERPAGE = 1000;		# notes returned per page
my $MAXNOTES = 8000;   	# max notes returned

# Set up "warnings" handler.
my $Log = "polnote_search.log";
$SIG{__WARN__} = \&logwarn;
sub logwarn { logger($Log,shift) }

# Start timing the search.
my @Now = gettimeofday();

# Untaint document root.
$ENV{DOCUMENT_ROOT} =~ /^(.*?)$/;
my $Root = $1;
if (!-d $Root) {
	logger($Log, "Bad DOCUMENT_ROOT: $Root");
	die "Bad DOCUMENT_ROOT";
}
my $DBDir = "$Root/cgi-bin/sitesearch/polnoteDB";

# Output HTTP header and beginning of page.
print header();
printComp (
	loadComp("header.comp"),
	["TITLE","Search Results"],
	["CSS","polnote.css"],
	["JS",""],
	["OPT",""]
);
print "<div id=\"main\">\n";

# Validate the search string from the form.
noTermError() unless (defined(param('term')));
my $SearchString = param('term');	# will become an array, @Terms
clean(\$SearchString);
noTermError() if ($SearchString eq "");
my $SSCopy = $SearchString;

# Set the search case sensitivity.
my $CaseSensitive = 0;
my $Pfix = "(?i)";
if (defined(param('case'))) {
	$CaseSensitive = 1;
	$Pfix = "";
}

# Check for "match all terms"
my $MatchAll = 0;
$MatchAll = 1 if (defined(param('matchAll')));

# Extract and validate the individual search terms.
my $st = param('stype');
(my $Stype, my $SpCh) = setType($st);
my @Terms = extractTerms(\$SearchString, $SpCh);
noTermError() if ($#Terms == -1);
if ($Stype eq 'regexp') {
	foreach (@Terms) {
		if (my $err = checkRegexp(\$_)) {
			printComp(loadComp("error.comp"),["ERROR","<i>$err"]);
			logger($Log, "Bad regexp: $_");
			exit(0);
		}
	}
}

# $BatchNo is the index in the number of search hit batches that have been
# returned so far, if any.
my $BatchNo = 0;
$BatchNo = param('batch') if (defined param('batch'));

# If this is not the first batch, get the name of the file the remaining hits
# are stashed in.  This process could be streamlined slightly by stashing the
# broken down search terms instead of parsing the whole search string again,
# but A) this is only a tiny part of the overall cost, B) those would need to
# be validated anyway in case of mischief/automation, as they are used in highlighting.
my $BatchDataFile = undef;
if (defined param('nbfn')) {
	# Untaint.
	param('nbfn') =~ /(\d+-\d+)/;
	if (!defined $1) {
		logger($Log,"Bad tmp_data file name.");
		exit (0);
	}
	$BatchDataFile = $1;
}

# Log this batch before proceeding.
my $logmessage = "";
if (!$BatchNo) {
	$logmessage = "Polnote search for: ";
	$logmessage .= "\"$_\" " foreach (@Terms);
} else { $logmessage = "Continuing $BatchDataFile, batch $BatchNo..." }
logger($Log,"$logmessage");


# An array to be populated with SiteSearch::PNSearch objects.
my @Notes;

# The initial search (i.e., if this is not a request for a subsequent batch).
if (!$BatchDataFile) {
	my $DIR;
	if (!opendir($DIR, $DBDir)) {
		logger($Log,"Open $DBDir fail: $!");
		exit 1
	}
	my @Files = sort readdir($DIR);
	closedir($DIR);

	foreach my $file (@Files) {
		next unless (-f "$DBDir/$file" && !-z "$DBDir/$file");
	# Scan text only database: each file represents one .html page,
	# each line represents one whole polnote.
		my $DBH;
		unless (open($DBH, "<", "$DBDir/$file")) {
			logger($Log,"!!Could not open $DBDir/$file: $!");
			next;
		}
		binmode $DBH,':utf8';
	# An array of arrays, 0 = line number 1 = terms found (qv. checkline() below).
		my @lines = ();
		my $ln = 1;
		while (<$DBH>) {
			my @found = ($ln,checkline($_));
			push @lines, \@found if $found[1];
			$ln++;
		}
		close($DBH);

	# Pull selected notes from parallel markup database (containing html).
		my $cur = 0;	# Tracks last line read in db
		my $MUH;	# DB filehandle
		unless (open($MUH, "<", "$DBDir/markup/$file")) {
			logger($Log,"!!Can't open /markup/$file:  $!");
			next;
		}
		binmode $MUH,':utf8';
		# Creation of the actual PNSearch objects.
		foreach my $l (@lines) {
			my $pns = SiteSearch::PNSearch->new($l->[1], $MUH, $l->[0] - $cur, $file);
			push @Notes, $pns if ($pns);
			$cur = $l->[0];
		}
		close($MUH);
	}
	if ($#Terms > 0) {
		# Primary (bucket) sort is by number of terms hit.
		my @buckets = ();
		while (my $n = shift @Notes) {
			push @{$buckets[$n->{terms}-1]},$n;
		}
		foreach (@buckets) {
			next if !defined($_);
			# Secondary sort is by date; do this backward to match the
			# subsequent unshift, since we are foreach'ing @buckets.
			my $pail = [sort {$a->{dateVal} <=> $b->{dateVal}} @$_];
			unshift @Notes, shift @$pail while ($#{$pail} >= 0 && $#Notes < $MAXNOTES-1);
		}
	} else {
	# If there was only one term, sort by date.
		@Notes = sort {$b->{dateVal} <=> $a->{dateVal}} @Notes;
	}

	# Print some information about the search.
	print "<div class=\"lab\">\n".
		'<center><p class="desc"><i>';
	if ($Stype eq 'norm') { print 'Normal search for:' }
	else { print 'Regular Expression search for:' }

	foreach (@Terms) {
		my $t = $_;
		if ($Stype eq 'norm') {
			$t =~ s/\\([\\\/\+\?\|\.\*\^\(\)\[\]\{\}\$])/$1/g # reverse escapes
		}
		print " $SpCh$t$SpCh"
	}
	print '.<br/>';

	my $notesFound = $#Notes + 1;
	if (!$notesFound) { print "No notes found!<br/>" }
	else {
		print "$notesFound notes found.<br/>";
		if ($notesFound >= $MAXNOTES) {
			print "Stopped searching after $MAXNOTES notes matched &mdash; this means your results may not be the best. "
				."(try omitting very common terms such as 'US', or tick 'match all terms').<br/>";
		}
		if ($notesFound >= $PERPAGE) {
			print "$PERPAGE notes will be listed per page (see bottom once completely loaded to continue).<br/>"
				.'The title of each note links to its location in the original page.<br/>'
		}
		if ($#Terms > 0 && !$MatchAll) {
			print 'Notes are sorted by the number of search terms found, then date (most recent first).'
		} else { print 'Notes are sorted by date, most recent first. ' }
	}
	print "</i></p></center>\n</div>\n\n";

} else {
# If this is not the preliminary search, continue using stashed hits
# from tmp_data directory.
	my $TDF;
	if (!open($TDF, "<", "$Root/cgi-bin/sitesearch/tmp_data/$BatchDataFile")) {
		logger($Log,"Could not open tmp_data/$BatchDataFile: $!");
		printComp(loadComp('error.comp'),
			['CAPTION','Data Expired'],
			['ERROR','Sorry, your search data has expired.  If you believe this is'
				.' an error, please report it.'
				." Otherwise, you'll have to try your search again."]
		);
		logger($Log,"Search expired (or error)");
		exit (0);
	}

	# Create the PNSearch objects starting from an appropriate point in the
	# stashed data (see "serialize @Notes below for the format).
	my $nn = -1;
	my $first = $PERPAGE*($BatchNo-1)*2;
	while(<$TDF>) {
		$nn++;
		next unless ($nn >= $first);
		chomp;
		my @l = split(/ /, $_);
		my $pns = SiteSearch::PNSearch->new($l[1], $TDF, 1, $l[0]);
		push @Notes, $pns if ($pns);
	}
	close($TDF);
}

# Output this batch of notes.
my $pnComp = loadComp("polnote.comp");
my $count = 0;
while (my $note = shift @Notes) {
	$note->hilight($Pfix.$_) foreach (@Terms);
	my $title = $note->{href}.$note->{title}."</a>";
	printComp($pnComp,["TITLE",$title], ["DATE",$note->{date}],['ID',$count]);
	print $note->{body}."</div>\n";
	last if (++$count == $PERPAGE);
}

# If there are remaining notes to be stashed, include a hidden form
# so they can be found via another request.
my $NextBatch = undef;
if ($#Notes > -1) {
	if (!$BatchNo) {
		(my $untaint = $ENV{REMOTE_ADDR}) =~ s/\.//g;
		$untaint =~ /(\d+)/;
		$NextBatch = $1.'-'.time();
	} else { $NextBatch = param('nbfn') }
	hiddenForm('nextbatch', 'polnote-search.cgi',
		['nbfn',$NextBatch],
		['batch',$BatchNo+1],
		['term',$SSCopy],
		['case',$CaseSensitive],
		['stype',$Stype]
	);
	my $more = $PERPAGE;
	$more = $#Notes+1 if ($#Notes < $PERPAGE-1);
	printComp(loadComp('nextbatch.comp'), ['NUM',$more]);
}

# Finish the page.
print "</div></body></html>";
close(STDOUT); # <<<<<<<<<<<<<<<<<<<<<<< STDOUT now closed ####
###############################################################


# If this is the preliminary search and there are more notes to batch, 
# serialize @Notes to a tmp_data file.
if ($NextBatch && !$BatchNo) {
	my $NB;
	if (!open($NB, ">", "$Root/cgi-bin/sitesearch/tmp_data/$NextBatch")) {
		logger($Log,"Could not create tmp_data/$NextBatch: $!");
	} else {
		binmode $NB,':utf8';
		while (my $note = shift @Notes) {
			while (chomp $note->{body}) {};
			$note->{href} =~ /href="\/archives\/([^\.]+?)\.html#([^"]+?)"/;
		# First line is the (suffixless) name of the source file for the note, space.
		# Second line is the anchor name in the file, "<|>", note data.
			print $NB "$1 $note->{terms}\n$2<|>".$note->{date}.' ('.$note->{title}.')<|>'.$note->{body}."\n";
		}
	}
	close($NB);
}

# Stop timing and log.
my $dur = tv_interval(\@Now);
logger($Log,'Complete ('.$dur.'s)');

# Take this opportunity to flush the tmp_data directory files which hold data from
# multi-batch searches.  The first number is seconds to retain tmp_data files,
# the second is max bytes in tmp_data.
cleanTmpData(7200,51200000);


#####################
#### SUBROUTINES ####
#####################


# Searches a DB entry for global @Terms.
sub checkline {
	my $line = pop;
	my $c = 0;
	foreach (@Terms) {
		# anchor name is before first <|> (don't search that) 
		if ($line =~ /$Pfix<\|>.*?$_/) { $c += 1 }
		elsif ($MatchAll) { return 0 }
	}
	# Return value is the number of terms found, not the number of individual hits.
	# I.e, if there is only one search term, this will be 0 or 1.
	return $c;
}


# Removes files from tmp_data storage based on age.
sub cleanTmpData {
	my ($maxbytes,$secs) = (pop,pop);
	my $dir = "$Root/cgi-bin/sitesearch/tmp_data";
	if (!$secs) {
		logger($Log,"$dir is full and cannot be cleaned\nSearch halted");
		printComp(loadComp('error.comp'),
			['CAPTION','Critical failure'],
			['ERROR','The political note search is currently unavailable']
		);
		exit (0);
	}

	if (!opendir(TD, $dir)) {
		logger($Log,"Could not opendir tmp_data for cleaning: $!");
		return;
	}
	my @files = readdir(TD);
	closedir(TD);

	my $total = 0;
	my $stale = time()-$secs;
	foreach (@files) {
		next unless ($_ =~ /^(\d+-\d+)$/);
		my ($size, $ctime) = (stat "$dir/$_")[7,10];
		if ($ctime < $stale) {
			logger ($Log, "Could not unlink tmp_data/$_: $!") if (!unlink("$dir/$1"));
		} else { $total += $size }
	}
	# If tmp_data is still full, recurse with half the max lifespan.
	if ($total > $maxbytes) {
		logger ($Log, "!!!tmp_data was full\n*************\n\n");
		cleanTmpData(int($secs/2),$maxbytes);
	}
}


# Called if there was no valid search string.
sub noTermError {
	printComp(loadComp('error.comp'),['CAPTION','No valid search term!'],['ERROR','']);
	logger($Log, "SearchString undefined!");
	exit 0;
}
