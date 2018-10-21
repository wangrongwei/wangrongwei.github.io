# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package SiteSearch::CGIutil;
our $VERSION = '1.4.0';
use strict;
use warnings;

##############################################################
# CGIutil.pm
#############
# 1.1 Oct/10
#	- added unified methods for extracted and checking terms
# 1.1.1 Dec/10 
#	- corrected minor issue with extractTerms
# 1.2 July 2013 Mark Eriksen
#	- slight reorganization to use SiteSearch namespace
# 1.3 Sept 2013 Mark Eriksen
#	- Added POD documentation.
#	- Removed baseDir().
#	- Added $Logpath.
# 1.4.0 April 2014 M. Eriksen
#	- Now uses traditional module source directory.
#	- Adapted extractTerms() to deal with paranthesized segments
#	  with space in regular expression searches, reject duplicates.
#	- Added unit tests for extractTerms()
#	- Added restriction on terms with only one non-whitespace character

# DO NOT EDIT THE INSTALLED VERSION OF THIS FILE.
# Your changes will eventually get overwritten.  Edit the version
# in /home/helpers/perl/src and follow the normal procedure for
# installing a perl module.

# You can view the POD documentation with "perldoc SiteSearch::CGIutil".
# Use the '-t' switch if the output is mangled.

our $Dir = "/home/helpers/public_html";
our $Logpath = "$Dir/site-search/log";
our $Log = "CGIutil.log";

# Set up "warnings" handler. Probably only meaningful when
# warnings are enabled, and possibly overridden by user scripts ;)
$SIG{__WARN__} = \&logwarn;
sub logwarn { logger($Log,shift) }

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw (
	clean
	checkRegexp
	extractTerms 
	hiddenForm
	loadComp logger
	printComp
	setType
);

=encoding utf8

=head1 NAME

SiteSearch::CGIutil

=head1 DESCRIPTION

Miscellaneous collection of general purpose functions used by other SiteSearch modules
and the scripts in public_html/cgi-bin.

If you mirror stallman.org somewhere, beware that the web root /home/helpers/public_html
is hardcoded in this module.  You must either install under this root, create a symlink
to make it work, or else change the value of $Dir at the top of CGIutil.pm.  All the
other hard coded paths are relative to that one.

Since this is mostly stuff used in both polnote-search.cgi and site-search.cgi, these could
scripts could be re-written along more OO lines, with this module as the base class.


=head1 SUBROUTINES


=head2 C<clean($strref)>

B<$strref> is a I<reference> to a string.

Replaces '<' and '>' with html entities and reduces any sequence of
whitespace to a single ' '.

=cut
sub clean {
	my $ref = pop;
	$$ref =~ s/</&lt;/g;
	$$ref =~ s/>/&gt;/g;
	$$ref =~ s/\s+/ /g;
}


=head2 C<checkRegexp($strref)>

B<$strref> is a I<reference> to a string.

Removes ^ and $ from a regexp submitted to the search engine, then
evaluates it.  If the regexp is no good, adds some mark-up
indicating the problem and returns it.  Otherwise (if the regexp is
okay) returns undef.

=cut
sub checkRegexp {
	my $t = pop;
	$$t =~ s/(?<!\/)[\^\$]//g;	# unescaped ^ and $ out
	eval { (my $test = "whatever") =~ /$$t/ };
	if ($@) {
		$@ =~ s/at \/.+$//;
		$@ =~ s/(marked by <-- HERE in)/$1:<\/i><br\/>/;
		$@ =~ s/(<-- HERE)/<span style="color: #ff0000;">$1<\/span>/g;
		return $@;
	}
	return undef;
}


=head2 C<extractTerms($strref, $chr)>

B<$strref> is a reference to a string.

B<$chr> is the character used to quote search phrases, either '"' or '`'.
(See setType() below).

Returns an array of phrases extracted from $strref.

=cut

sub extractTerms {
	my ($str, $ch) = @_;
	# Escape special charcters in normal search.
	$$str =~ s/([\\\$\|\+\?\.\*\^\(\)\[\]\{\}])/\\$1/g if ($ch eq '"');

	# Precedence is:
	#	1. Extract quoted terms.
	#	2. For regexp, extract parenthesized terms.
	#	3. Split on whitespace.

	# 1. Extract terms quoted in "" (for normal) or `` (for regexp).
	my $rgx = "$ch([^$ch]+?)$ch";
	my @terms = $$str =~ /$rgx/g;
	$$str =~ s/$rgx//g;

	if ($ch eq '`') { # regexp
	# 2. Extract paranthesized terms.
	# Since extracting quotes takes precedence, stuff like
	# `foo (bar|blat)` will already be a term.
		my $rgx = '\(.*?\)';
		@terms = (@terms, ($$str =~ /$rgx/g));
		$$str =~ s/$rgx//g;
	}

	# 3. Split the rest on whitespace.
	@terms = (@terms, split(/\s+/, $$str));

	# Use a hash table filter to eliminate duplicate terms 
	# those with a single non-whitespace character.
	# Nb. 'split' will have left undef elements if, e.g., 
	# there's a space at the beginning of the string.
	my %filter;
	foreach (@terms) {
		next if !$_;
		(my $test = $_) =~ s/\s+//g;
		next if length($test) < 2;
		$filter{$_} = 1;
	}
	return keys %filter;
}


=head2 C<hiddenForm($id, @fields)>

B<$id> is used as for the form tag id attribute.

B<@fields> is a series of array references.  The first element of each should be the
name attribute for an input tag and the second the value attribute.

Prints an html form of hidden fields to STDOUT.

=cut
sub hiddenForm {
	print "\n<form id=\"".(shift).'" method="POST" action="'.(shift)."\">\n";
	foreach (@_) {
		print "\t".'<input type="hidden" name="'.$_->[0].'" value="'.$_->[1]."\" />\n";
	}
	print "</form>\n";
}


=head2 C<loadComp($compname)>

B<$compname> is the name of a file in the hardcoded search_comp directory.

Returns an html component or other text file as a single string.

=cut
sub loadComp {
	my $file = shift;
	unless (open (SRC, "<$Dir/cgi-bin/sitesearch/search_comp/$file")) {
		logger($Log, "comp() -- Can't open $file: $!");
		die "SiteSearch::CGIutil::loadComp() open failed, see log";
	}
	my $str = "";
	$str .= $_ while (<SRC>);
	close(SRC);
	return $str;
}

=head2 C<logger($Logname, $msg)>

B<$Logname> is the name of a file to use in the hardcoded log directory.

B<$msg> is the message to log.

Prints a message to a log prepended with a timestamp and appended with a newline.

=cut
sub logger {
	(my $msg, my $file) = (pop,pop);
	$file = $Log if (!$file);
	unless (open(LOG, ">>$Logpath/$file")) {
		logger($Log, "logger() -- Can't open $file: $!") unless ($file eq $Log);
		return 0;
	}
	binmode(LOG,":utf8");
	print LOG timestamp()." $msg\n";
	close(LOG);
	return "Success";
}


=head2 C<printComp($compstr, @fields)>

B<$compstr> is an html component as returned by loadComp().

B<@fields> is a series of array references.  The first element of each should
be a word to replace and the second the replacement string.

Works as a crude templating system.

=cut
sub printComp {
	my $str = shift;
	foreach my $pair (@_) {
		$str =~ s/<!$pair->[0]!>/$pair->[1]/g;
	}
	print $str;
}


=head2 C<setType($type)>

B<$type> should be either 'regexp' or 'norm'.

Returns the character used to separate search phrases.

=cut
sub setType {
	if (defined($_[0]) && $_[0] eq 'regexp') {
		return ('regexp', '`');
	}
	else { return ('norm', '"') }
}


=head2 C<timestamp()>

Returns a human readable date - time string based on the current time.

=cut
sub timestamp {
	my ($min,$hour,$day,$m,$y) = ((localtime(time()))[1,2,3,4,5]);
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	$y += 1900;
	foreach ($min,$hour,$day) { $_ = "0$_" if ($_ < 10) }
	return "$day $months[$m] $y $hour:$min";
}

1;
