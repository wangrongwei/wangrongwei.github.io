# (C) 2010 M. Eriksen
# Distributed under the terms of the GNU General Public License, v3.
# http://www.gnu.org/licenses/gpl.html

package Polnote::Fancy;
use strict;

use warnings FATAL => qw(all);
use base 'Exporter';
our @EXPORT = qw(PNfancy);

sub PNfancy {
	my ($pre, $note) = (pop,pop);
	return if (!$note);
	foreach (values %$note) {
		$_ =~ s/\n+/\n/g;
		$_ =~ s/[ \t]+/ /g;
	}
	my $r = "\n<div class=\"pnote\">\n".
		'<h3><a class="ntitle" href="'.$pre.$note->{aname}."\">\n".
		$note->{title}."</a></h3>\n<p class=\"date\">$note->{date}</p>\n".
		$note->{body}."\n</div>\n";
	return $r;
}

1;
