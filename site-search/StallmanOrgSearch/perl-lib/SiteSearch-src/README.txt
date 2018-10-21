The makefile for these have the INSTALL_BASE set to "00_Install" in this
directory.  They each must be built separately; from inside the toplevel
module directory:

	make clean
	perl Makefile.PL

Then if there is a t/ directory:
	make test

Finally:
	make install
