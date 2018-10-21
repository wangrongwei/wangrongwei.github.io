# (C) 2012 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package Polnote::Iframe;
use strict; # testing only

=head1 NAME

Polnote::Iframe

=head1 DESCRIPTION

This module contains a single function for turning a note from Polnote::Page into html suitable for use
in the stallman.org iframe on the front page, which mirrors the RSS feed.

=head1 SYNOPSIS

C<my $html = Polnote::Iframe::iframeNote($note, $url)>

=over

=item C<$note>

A hash reference as returned by Polnote::Page::nextnote().  Otherwise, the behaviour is undefined ;).

=item C<$url>

An http address to prepend to $note->{aname} to create a valid link.

=back

=head1 RETURNS

A html formatted note, or undef if $note is not defined.

=cut

# used by rss.cgi for the front page iframe

sub iframeNote {
	my ($pre, $note) = (pop,pop);
	return undef if (!$note);
	foreach (values %$note) {
		$_ =~ s/\n+/\n/g;
		$_ =~ s/[ \t]+/ /g;
	}
	# notice the target="_top" (so we don't load inside the iframe)
	(my $body = $note->{body}) =~ s/<a /<a target="_top" /g;
	my $r = '<div style="border-bottom: thin dotted #888888;">'."\n".
		'<p><a href="'.$pre.'#'.$note->{aname}.'" target="_top">'.
		"<b>$note->{title}</b></a><br>\n".
		"<i>$note->{date}</i></p>\n".
		$body."</div>\n";
	return $r;
}

1;
