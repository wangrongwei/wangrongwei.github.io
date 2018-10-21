use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'SiteSearch::PNSearch',
	VERSION_FROM => 'lib/SiteSearch/PNSearch.pm',
	INSTALL_BASE => '../00_Install',
	MIN_PERL_VERSION => 5.10.0,
	NO_META => 1,
	NO_MYMETA => 1
);
