use strict;
use warnings;

use Test::More tests => 1;
BEGIN {
	push @INC, "/home/helpers/perl/lib";
	use_ok('SiteSearch::PNSearch');
};

