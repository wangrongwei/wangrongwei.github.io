Source package for Stallman.org Search
======================================

The search is written perl 5 and very site specific; i.e., it cannot be easily
adapted for some generic purpose elsewhere.  However, you are free to do what
you like with it under the under the terms of the GNU General Public License,
v3.  A copy of this is included here as LICENSE.txt.

The search engine consists of a number of parts:

- Perl modules under two namespaces:
	- `SiteSearch::` modules; the source for these are regular perl packages
	  found in perl-lib/SiteSearch-src.
	- `Polnote::` modules; these are just ready to use .pm files in
	  in perl-lib/Polnote.
- Scripts for generating the flat file database in bin/.
- CGI scripts in cgi/.  These actually execute the searches.
- HTML templates used with search results in cgi/search_comp.
- Client side artifacts:
	- Stylesheets in css/.
	- Javascript in js/.
	- The "Advanced search" HTML page in html/.

Note this directory scheme is **not** a replication of the installed system,
and there is no "installer" since again, all this would be useless as is
anywhere else.

Some of the modules have their API documented with POD, which you can read w/
`perldoc -t ./whatever.pm`.

If you have any comments or questions, you can contact me directly:
mk@cognitivedissonance.ca
