# (C) 2013 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package Polnote::Page;
#use strict; #testing only
#use warnings FATAL => qw(all);

##### IMPORTANT #####
# The system wide perldoc may not be properly installed, 
# use ~/bin/perldoc or "hlperldoc" instead.
#####################

=head1 NAME

Polnote::Page

=head1 SYNOPSIS

C<my $page = Polnote::Page-E<62>new($input)>

B<$input>: A filepath or string ref.

=head1 DESCRIPTION

Scraper for stallman.org political notes.
Like the HTML::Parser base class, it is "event driven": we read thru and extract notes one by one, in order.

=cut

use base 'HTML::Parser';

# Both of these are localized to the instance in nextnote():
our $PP; 		# "self" obj ref needed because the handler functions do not get passed one
our %Note;		# likewise, they cannot be passed this

sub new {	# one arg: filename or string ref
	my $s = HTML::Parser->new(api_version => 3);
	$s->attr_encoded(1);	# eg, so &eacute; remains such in anchor names
	open ($s->{input},'<',(pop)) || return undef;
	$s->{list_depth} = 0;		# nested depth of lists (we only want <li>'s at a depth of 1) 
	$s->{state} = 0;			# 0 = not in note 1 = get anchor name 2 = get date & title 3 = note body
	$s->{pos} = 0;				# character position in file
	$s->{error} = undef;		# string to hold errors, undef when none
	$s->{lineno} = 0;			# current line number in file to report with errors
	$s->{accum} = "";			# temp buffer for date & title text
	$s->{bDone} = 0;			# boolean, 1 = page is finished
	$s->{keep_comments} = 0;	# 0 = no (this default), 1 = yes (must be set by user)
	$s->handler(start=>\&tagopen,'text,tagname,attr');
	$s->handler(end=>\&tagclose,'text,tagname');
	$s->handler(text=>\&pagetext,'text');
	$s->handler(comment=>\&comments,'text');
	bless $s;
}


=head1 METHODS

Just the publically useful ones, that is.

=cut

sub chunk {
# used by HTML::Parser's "parse", registered in nextnote()
# pulls next line of text from file and hands it to the parser
	return undef if ($PP->{bDone});
	$PP->{lineno}++;
	# hopefully notes begin on a fresh line ;) -- HTML::Parser can return an offset, but this seems more accurate:
	$PP->{pos} = tell($PP->{input});	
	my $r = readline $PP->{input};		
	$PP->end() if (!$r);		# Parser does not auto eof on null line
	return $r;
}


sub comments {
# keep comments found in note body
	$Note{body} .= (pop) if ($PP->{keep_comments} && $PP->{state});
}

=head2 C<$page-E<62>end()>

Terminates parsing.

=cut

sub end {
# this is used to terminate parsing internally, when the input source is finished
# could also be used externally (eg, to close a file after N notes)
	my $self = shift;
	close($self->{input});
	$self->eof();
	$self->{bDone} = 1;
}

=head2 C<$page-E<62>nextnote()>

Used to iterate thru notes one at a time.

B<Returns> undef if there are no notes left, or on error
($page->{error} will be set in this case). Otherwise,
a hash ref to the note with the following keys:

=over

=item aname

The local anchor name attribute, which can be used in links.

=item title

The title of the note.

=item date

The string date on the note.

=item body

The text of the note, including html markup.

=back

=cut 

sub nextnote {
# public function: use to iterate thru notes
# returns hash ref, or undef when notes are done
# returns undef with obj->{error} set on error
	my $s = shift;
	$s->{error} = undef;
	return undef if ($s->{bDone});

	local $PP = $s;
	$PP->{lineno}-- if ($PP->{lineno});		# end/begin from same line
	local %Note = (
		'aname' => "",	# local anchor name for links
		'title' => "", 
		'date' => "", 
		'body' => ""
	);

	seek($PP->{input},$PP->{pos},0);
	$s->parse(\&chunk);

	return undef if ($s->{error});
	return \%Note;
}


sub pagetext {
# HTML::Parser handler for plain text outside of tags
	my $txt = pop;
	if ($PP->{state} == 2) {
		$PP->{accum} .= $txt;
	} elsif ($PP->{state} == 3) {
		$Note{body} .= $txt;
	}
}


sub tagclose {
# HTML::Parser handler for end tags, eg. "</p>"
	(my $tag, my $txt) = (pop,pop);
	if ($tag eq 'ul' || $tag eq 'ol') {
		$PP->{list_depth}--;
		$PP->{state} = 0 if (!$PP->{list_depth});
		$Note{body} .= $txt if ($PP->{state} == 3);
		return;
	}
	if ($PP->{state} == 3) {	# accumlate in note body
		$Note{body} .= $txt;
	} elsif ($PP->{state} == 2 && $tag ne 'a' && $tag ne 'p') {	# accumlate in date/title
		$PP->{accum} .= $txt;
	}
}


sub tagopen {
# HTML::Parser handler for open tags, eg. "<p>"
	(my $attr, my $tag, my $txt) = (pop,pop,pop);
	if ($tag eq 'ul') {
		$PP->{list_depth}++;
		$Note{body} .= $txt if ($PP->{state} == 3);
		return;
	}
	return if (!$PP->{list_depth});
	if ($tag eq 'ol') {
		$PP->{list_depth}++;
		$Note{body} .= $txt if ($PP->{state} == 3);
		return;
	}
	if ($PP->{list_depth} == 1 && $tag eq 'li') {
		if ($PP->{state}) {	# end note
			$PP->{state} = 0;
			$PP->eof();
			$Note{body} =~ s/<p>$//;
		} else { $PP->{state} = 1 }	# begin note
	} elsif ($PP->{state} == 1 && $tag eq 'a') {	# get anchor name
		if (exists $attr->{name}) {
			$Note{aname} = $attr->{name};
			$PP->{state} = 2;
		} else {
			$PP->eof();
			%Note = ();
			$PP->{error} = "Line #".$PP->{lineno}.": No anchor name.";
		}
	} elsif ($PP->{state} == 2 && $tag eq 'p') {		# get date & title
	# this assumes the note body always starts with a <p>, which it should
		if ($PP->{accum} =~ s/^\s*(\d+\s+\w+\s+\d+)\s+//) {
			$Note{date} = $1;
		}
		$PP->{accum} =~ s/^\s*\(//;
		$PP->{accum} =~ s/\)\s*$//;
        $PP->{accum} =~ s/\n/ /;
        $PP->{accum} =~ s/<([\w-\:]+)>(.*?)<\/\1>/$2/g;
		$Note{title} = $PP->{accum};
		$PP->{accum} = "";
		$PP->{state} = 3;
		$Note{body} .= $txt;	# the tag (<p>) is part of the body
		return;
	} elsif ($PP->{state} == 3) {	# accumulate in note body
		$Note{body} .= $txt;
	} elsif ($PP->{state} == 2 && $tag ne 'a' && $tag ne 'p') {	# accumulate in date/title
		$PP->{accum} .= $txt;
	}
}

1;
