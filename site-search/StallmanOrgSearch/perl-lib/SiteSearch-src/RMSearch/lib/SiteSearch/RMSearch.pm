# (C) 2014 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package SiteSearch::RMSearch;
our $VERSION = '1.2';
use strict;
use warnings;

##############################################################
# RMSearch.pm
#############	Provides OO functions to site-search.cgi 
# 1.1 Oct 2010
#	- added export
#	- incorporated getCounts
# 1.2 July 2013 Mark Eriksen
#	- slight reorganization to use SiteSearch namespace
#	- more detailed comments

# DO NOT EDIT THE INSTALLED VERSION OF THIS FILE.
# Your changes will eventually get overwritten.  Edit the version
# in /home/helpers/perl/src and follow the normal procedure for
# installing a perl module.

use SiteSearch::CGIutil;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(checkDB getCounts);

our $DB = "sitesearch/stallman-org.db";

# Used internally by checkDB().  Member {<content>} is the raw text of a page
# from $DB with html mark-up highlighting added for matches found.  The other
# members are keyed by seach term, and their value is the number of matches found
# for the term.
sub new {
	my $self = {};
	($self->{'<content>'}, my $terms, my $case) = @_;
	my $use = 0;
	my $c = 1;
	foreach my $word (@$terms) {
		my $n;
		if ($case) { $n = $self->{'<content>'} =~ s/($word)/<em class="f$c">$1<\/em>/g }
		else { $n = $self->{'<content>'} =~ s/($word)/<em class="f$c">$1<\/em>/gi }
		$n = 0 if (!$n);
		$self->{$word} = $n;
		$use++ if ($n);
		$c++;
		$c = 1 if ($c>4);
	}
	# If there were no matches for anything, return undef.
	return bless($self) if ($use);
	return undef;
}


# checkDB() returns a hash of RMSearch objects keyed by a filepath relative
# to public_html; only files which actually contain matches are returned.
sub checkDB {
	# If $case is non-zero the search is case sensitive.
	my $case = pop;
	# $terms is a reference to an array of search terms.
	my $terms = pop;
	# %files is the return hash.
	my %files;
	open(DB, "<$DB") || SiteSearch::CGIutil->logger("Could not open $DB: $!");
	while (<DB>) {
		(my $file, my $data) = split / \*%: /,$_,2;
		my $entry = new($data, $terms, $case);
		$files{$file} = $entry if ($entry);
	}
	return %files;
}


sub getCounts {
	(my $pages, my $terms) = (pop,pop);
	my %counts;
	$counts{$_} = 0 foreach(@$terms);
	foreach my $obj (values %$pages) {
		while (my ($k, $v) = each %$obj) {
			next if ($k eq '<content>');
			$counts{$k} += $v;
		}
	}
	return \%counts;
}


sub showithcontext {
	my $obj = shift;
	my @data = split(/ /,$obj->{'<content>'});
	$obj->{'<content>'} = undef; # free: no longer needed
	# break into X word segments
	my $c = 10;	# X
	while ($c < $#data) {
		$data[$c] .= "\n";
		$c += 10;	# X
	}		
	@data = split(/\n/,join(" ",@data));
			# now print relevent segments to page
	my $line = ""; my $print = 0;
	my $tag = "<\/?em[^>]*?>";
	for (my $i=0; $i<=$#data; $i++) {
		if (($i == 0) && ($data[$i] =~ /$tag/)) {
			$line .= $data[$i];
			$print = 1;
		}
		elsif ($print == 1) {
			$line .= $data[$i];
			if ($data[$i] =~ /$tag/) { $print = 1 }
			else { $print = 2 }
		}
		elsif ($print == 2) {
			if ($data[$i] =~ /$tag/) { 
				$line .= $data[$i];
				$print = 1 
			} else {
				print "<li>$line</li>\n";
				$print = 0;
				$line = "";
			}
		}
		elsif ($data[$i] =~ /$tag/) {
			$line .= $data[$i-1].$data[$i];
			$print = 1;
		}
		print "<li>$line</li>\n" if (($i == $#data) && ($line ne ""));
	}
}

1;
