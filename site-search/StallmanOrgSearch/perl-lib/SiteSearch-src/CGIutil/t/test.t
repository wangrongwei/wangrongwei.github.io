use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('SiteSearch::CGIutil'); };

my $str = 'Canada (oil|fossil fuels) (foo|bar) `this and (more|less)`';
my @terms = SiteSearch::CGIutil::extractTerms(\$str, '`');
# Can't predict the order, so:
my %check;
$check{$_} = 1 foreach (@terms);
is_deeply (
	\%check,
	{
		"this and (more|less)" => 1,
		"(oil|fossil fuels)" => 1,
		"(foo|bar)" => 1,
		"Canada" => 1
	},
	'regexp #1'
);

my $str = '(oil|fossil fuels) \bUS\b';
my @terms = SiteSearch::CGIutil::extractTerms(\$str, '`');
%check = ();
$check{$_} = 1 foreach (@terms);
is_deeply (
	\%check,
	{
		"(oil|fossil fuels)" => 1,
		'\bUS\b' => 1
	},
	'regexp #2'
);

$str = 'something "yada blah yada" something';
@terms = SiteSearch::CGIutil::extractTerms(\$str, '"');
%check = ();
$check{$_} = 1 foreach (@terms);
is_deeply (
	\%check,
	{
		"yada blah yada" => 1,
		"something" => 1
	},
	'normal'
);

