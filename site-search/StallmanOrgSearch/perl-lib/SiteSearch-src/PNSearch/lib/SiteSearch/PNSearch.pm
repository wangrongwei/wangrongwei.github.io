# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package SiteSearch::PNSearch;
our $VERSION = '1.4';
use strict;
use warnings;

##############################################################
# PNSearch.pm
################
# 1.1 (Oct/2010 M. Eriksen)
#	-object changed from per directory to per file
#	-added logging of malformed entries
# 1.2 (July/2013 M. Eriksen)
#	- slight reorganization to use SiteSearch namespace
# 1.3 (Sept/2013 M. Eriksen)
#	- Added POD annotations for perldoc.
#	- Removed unused 'terms' field.
#	- Added 'dateVal' field for sorting.
# 1.4 (April/2014 M. Eriksen)
#	- Now uses traditional module source directory.
#	- Replaced needed 'terms' field.

# DO NOT EDIT THE INSTALLED VERSION OF THIS FILE.
# Your changes will eventually get overwritten.  Edit the version
# in /home/helpers/perl/src and follow the normal procedure for
# installing a perl module.

# You can view the POD documentation with "perldoc SiteSearch::PNSearch".
# Use the '-t' switch if the output is mangled.

use SiteSearch::CGIutil qw(logger);

our $Log = "PNSearch.log";

# Used in translating the string date to a numerical value for comparison.
our %Months = (
	Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
	Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12
);

=encoding utf8

=head1 NAME

SiteSearch::PMSearch

I<See also SiteSearch::CGIutil.>

=head1 DESCRIPTION

Represents an individual pol note found as the result of a search, qv. polnote-search.cgi
in public_html/cgi-bin.

=head1 SYNOPSIS

 my $pns = SiteSearch::PNSearch->new (
	$termsHit,
	$fh,
	$lineNo,
	$srcname
 );

=over

=item B<$termsHit>

The number of search terms found in this note.

=item B<$fh>

An I<open> file handle to the html marked-up database file containing the note.

=item B<$lineNo>

The line number of the note I<relative to the position of $fh>.

=item B<$srcname>

The suffixless name of the source file which was the original source of the
note, e.g. "2012-sep-dec".

=back

The constructor will return undef on error, but the error will be logged to
SiteSearch::PNSearch::$Log.

=head1 MEMBER FIELDS

=over

=item C<$pns-E<62>{date}>

The date in string form, 'Day Month Year'.

=item C<$pns-E<62>{dateVal}>

The date translated to a number for comparison to other PNSearch objects.
This is not epoch seconds or anything else generally useful.

=item C<$pns-E<62>{title}>

The note title.

=item C<$pns-E<62>{href}>

An unclosed HTML anchor element referencing the original source of the note,
in string form.

=item C<$pns-E<62>{body}>

The text of the note including mark-up.

=back

=cut

sub new {
	my ($class, $self) = (shift, {
		terms => shift
	});
	my ($dbh, $ln, $src) = @_;
	my $cur = 0;
	while (<$dbh>) {
		next unless (++$cur == $ln);
		my @parts = split /<\|>/,$_,3;
		if ($#parts != 2) {
			logger($Log, "Bad split: $src\n$_\n\n");
			return undef;
		}
		if (length($parts[0]) < 3) {
			logger($Log, "No href defined: $src\n$_\n\n");
			return undef;
		}
	# The line parsed was structured by helpers/bin/search/makepolenoteDB.pl.
		my $found =()= $parts[1] =~ /^\s*(\d+) (\w+) (\d+)\s*\(?(.*?)\)?\s*$/;
		if ($found < 3) {
			logger($Log, "No date, no title: $src\n$_\n\n");
			$self->{date} = "&mdash;";
			$self->{title} = "[no title]";
		# Notes without dates are older, so give them a low dateVal.
			$self->{dateVal} = 0;
		} else {
			$self->{date} = "$1 $2 $3";
		# Create a corresponding dateVal.
			$self->{dateVal} = 0;
			my $month = $Months{substr($2,0,3)};
			if (!$month) { logger($Log, "Odd date: $src\n$self->{date}\n\n") }
			else { $self->{dateVal} += 100 * $month }
			$self->{dateVal} += ($3 - 2000) * 10000;
			$self->{dateVal} += $1;
			if (!defined $4) { $self->{title} = "[no title]" }
			else { $self->{title} = $4 };
		}
		$self->{href} = "<a class=\"ntitle\" href=\"/archives/$src.html#$parts[0]\">";
		$self->{body} = $parts[2];
		last;
	}
	bless $self, $class;
}

=head1 METHODS

=head2 C<$pns-E<62>hilight($term)>

B<$term> is the string to highlight.

Adds HTML mark-up to emphasize a search term hit in the {body} or {title} of a note.

=cut

sub hilight {
	(my $self, my $term) = (shift,shift);
	my @left = split /</,$self->{body};
	foreach (@left) {	# @right halves each elem of @left
		my @right = split />/,$_;
		next if ($#right < 1);	# no half = <tag><tag>
		$right[1] =~ s/($term)/<em class="hlite">$1<\/em>/g;
		$_ = join(">",@right);
	}
	$self->{body} = join("<",@left);
	$self->{title} =~ s/($term)/<em class="hlite">$1<\/em>/g; 
}


1;
