#!/usr/bin/perl -w
use strict;

# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

# makepolnotedb.pl -- for updating pol note database
# rev 1.1 (Oct/2010) Mark Eriksen
#	- uses utf8 for db files
#	- uses HTML::Parser (complete rewrite)
# 1.2 (Nov/2010)
#	- bug fix (action only when ULopen == 1)
# 1.3 Mark Eriksen
#	- Updated for SiteSearch namespace.
# 1.4 (Sept/2013 Mark Eriksen)
#	- Removed use of SiteSearch::CGIutil::baseDir().
#	- Modified so that only .html sources with mtimes
#	  newer than their db counterparts are scanned.
#	- $BadLog is now appended to, not re-created.
# 1.5 (April/2014 M. Eriksen)
#	- Fixed addition of duplicates due to skipping
#	  of old files by mtime.
#	- Added checking for mismatch of note content.
#	- $BadLog is now really appended to.
# 1.5.1 (June/2018 M.Eriksen)
#   - Very minor formatting.

BEGIN { use lib '/home/helpers/perl/lib' }

use SiteSearch::CGIutil qw(logger);
use HTML::Parser;

# Some global paths.
my $Root = $SiteSearch::CGIutil::Dir;
my $Polnotes = "$Root/archives";
my $DBDir = "$Root/cgi-bin/sitesearch/polnoteDB";
my $Log = 'makepolnote.log';
my $BadLog = 'polnote_error.log';

# Set up "warnings" handler.
$SIG{__WARN__} = \&logwarn;
sub logwarn { logger($Log,shift) }

# Check if the error log exists.
my $elog = "$SiteSearch::CGIutil::Logpath/$BadLog";
if (!-e $elog) {
	my $fh;
	if (!open $fh, '>', $elog) {
		logger($Log, "!!Could not write polnote_error.log");
	} else {
		print $fh $_ while (<DATA>);
		close $fh;
	}
}


# Configure parser.
my $Parser = HTML::Parser->new(api_version => 3);
$Parser->attr_encoded(0);
my $ULopen = 0;		# state flag: 1 = main note list, 2+ = nested lists in notes.
my $LIopen = 0;		# state flag: 1 = extract anchor name, 2 = extract title, 3 = extract body.
my $Count = 0;
my $DBH1;			# plain text
my $DBH2;			# mark-up
my %CheckAll = ();	# hash of note anchor names to prevent duplicates
my $CorrCheck = "";	# last anchor name to correlate href to
my $CurFile = "";	# current file (for logging name/href correlation errors)
my $CurNote;		# Reference to string body in %CheckAll for current note.

$Parser->handler ( 
start => sub {
	(my $att, my $tag, my $all) = (pop,pop,pop);
	if ($tag eq 'ul') {
		$ULopen += 1;
		return;
	}
	return if (!$ULopen);
	if ($ULopen == 1 && $tag eq 'li') { $LIopen = 1 }
	elsif ($tag eq 'a') {
		if ($LIopen == 1) {
			if (exists $att->{'name'}) {
			# Check for match based on anchor name. SPECIAL ->
			# By commenting this qualifier out and using "if (0) {}", 
			# creating the db from scratch, then uncommenting and
			# running again (see addToCheckAll()), duplicate notes
			# whose bodies mismatch can be found.
				if (exists $CheckAll{$att->{'name'}}) { $LIopen = 0; }
				else {
					if (tell($DBH1)) {
						print $DBH1 "\n";
						print $DBH2 "\n";
					}
					if ($att->{'name'} =~ s/\n/\\n/g) {
						logger($BadLog, "Newline in anchor name $CurFile:\n".$att->{'name'}."\n\n");
						# see __DATA__ section for an explanation of this;
						# nb, we can use this note anyway, but that anchor
						# will be bad regardless, so we indicate with a literal \n
						# (since there should not be real newlines in the db)
					};
					$CheckAll{$att->{'name'}} = "";
					$CurNote = \$CheckAll{$att->{'name'}};
					print $DBH1 $att->{'name'}.'<|>'; 	# local anchor name
					print $DBH2 $att->{'name'}.'<|>';
					$Count++;
					$CorrCheck = $att->{'name'};
					$LIopen = 2;
				}
			} else {
				logger($BadLog, "No name in anchor $CurFile:\n $all");
				$LIopen = 0;
			}
		} elsif ($LIopen == 2) {
			if (exists $att->{'href'} && $CorrCheck ne "") {
				(my $href = $att->{'href'}) =~ s/^[^#]*?#//;
				$href =~ s/\n//g;
				corrErr($href) if ($href ne $CorrCheck);
			}
		}
	} elsif ($tag eq 'p') {
		if ($LIopen == 2) {
			print $DBH1 '<|>';
			print $DBH2 '<|>';
			$LIopen = 3;
			$CorrCheck = "";
		}
	}
	if ($LIopen == 3) {
	# Marked-up body retains tags.
		$all =~ s/\n/ /g;
		print $DBH2 $all;
	}
}, 'text,tagname,attr');

$Parser->handler (
end => sub {
	(my $tag, my $txt) = (pop,pop);
	if ($LIopen == 3) {
		$txt =~ s/\n/ /g;
		print $DBH2 $txt;
	}
	if ($tag eq 'ul') { $ULopen -= 1 }
}, 'text,tagname');

$Parser->handler (
text => sub {
	my $txt = pop;
	return unless ($txt =~ /\S/);
	$txt =~ s/\n/ /g;
	if ($LIopen == 2) {
		print $DBH1 $txt; 	# the title
		print $DBH2 $txt;
	} elsif ($LIopen == 3) {
		$txt =~ s/\s+/ /g;	# even whitespace
		print $DBH1 $txt;
		print $DBH2 $txt;
		$$CurNote .= $txt;
	}
}, 'text');

# process pol note directory
opendir(my $dirH, $Polnotes) || die("Could not open $Polnotes: $!");
my @Files = readdir($dirH);
closedir($dirH);

foreach my $f (@Files) {
	my $fpath = "$Polnotes/$f";
	(my $db = $f) =~ s/\.html$//;
	next if (
		$f !~ /^20.+?\.html$/
		|| substr($f,0,12) eq '2003-jan-apr'
	);
	if (!compareMtimes($db)) {
	# No need to parse, but include this note in the global
	# %CheckAll table.
		addToCheckAll($db);
		next;
	}
	$CurFile = $f;
	$ULopen = $LIopen = 0;
	unless (open($DBH1, '>', "$DBDir/$db")) {
		warn "Could not create $DBDir/$db";
		next;
	}
	binmode $DBH1,':utf8';
	unless (open($DBH2, '>', "$DBDir/markup/$db")) {
		warn "Could not create $DBDir/markup/$db";
		close $DBH1;
		next;
	}
	binmode $DBH2,':utf8';
	$Parser->parse_file($fpath);
	close($DBH1);
	close($DBH2);
	DBcheck("$DBDir/$db");
}

my $totalNotes = 0;
$totalNotes++ foreach(keys %CheckAll);
logger($Log, "$Count notes added, $totalNotes notes total.");



####################
### Subrountines ###
####################

sub addToCheckAll {
	my $file = shift;
	open my $in, '<', "$DBDir/$file";
	while (<$in>) {
		chomp;
		my @note = split(/<\|>/, $_);
		if (!exists $CheckAll{$note[0]}) {
			$CheckAll{$note[0]} = $note[2];
		} elsif ($CheckAll{$note[0]} ne $note[2]) {
		# Check for mismatched duplicates. This will only work
		# on special tests (see SPECIAL above).  It requires
		# two runs because both copies must pass through here
		# due to the mtime check.
			logger($BadLog, "Mismatched content for '$note[1]'.");
		}
	}
	close($in);
}


# Returns true if the polnote source has been modified since the
# database was last updated, false otherwise.
sub compareMtimes {
	my $name = shift;
	my $srctime = (stat("$Polnotes/$name.html"))[9];
	my $dbtime = (stat("$DBDir/$name"))[9];
	return 1 if !$dbtime;
	return 0 if $srctime < $dbtime;
	return 1;
}


sub corrErr {
	my $href = pop;
	my $msg = "BAD CORRELATION in $CurFile: \n".
		"\"$CorrCheck\"\n\"$href\"\n\n";
	logger($BadLog, $msg);
	# see __DATA__ section for an explanation of this
}


sub DBcheck {
	my $file = pop;
	open(my $in, '<', $file);
	my $c = 0;
	while(<$in>) {
		$c++;
		if (length($_) < 10) {
			# see __DATA__ section for an explanation of this
			logger($BadLog, "Parser error:\n$file, line $c");
			close($in);
			return;
		}
	}
	close($in);
}


# Preamble to $BadLog:
__DATA__
Errors logged here:

"Newline in Anchor Name"
Anchor names with newlines in them will never match with anything. 

"No Name in Anchor"
This happens because an anchor name cannot be extracted from the anchor at the
beginning of the title line.  Usually it's because an = or " is missing inside
the tag.

"BAD CORRELATION"
Occurs if the href to link a note to it's anchor is not the same as the anchor name.
Some old notes do not use this, so if there is no href prior to the note body proper,
no correlation check is done.  However, the body is considered to begin with a <p>
(see line ~80 in makepolnote.db). If the note is missing a <p> after the title line, 
this error will occur anyway, and the body of the note will not be extracted properly.
Just add the <p> to the .html file.  This may also occur because there is a newline
in the href, and href newlines are not replaced with spaces here or by the browser. 

"Parser Error"
HTML::Parser is not an html validator, and bad html will cause it to do funny things
These may lead to blank lines in the DB file (because an <li> opened, but the parser 
has stopped returning other data).  First find the blank lines in the DB file,
then check the source .html file starting at the last note correctly added.

"Mismatched Content"
There are two copies of most polnotes because of overlap in the pages.  This indicates
a note was found whose duplicate's body does not match.

__________________________
