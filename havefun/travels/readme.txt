readme_thumbnails.txt for thumbnail_webpage.txt version 1.7
This program is Copyright 2003-2012, 2013, 2014 John C. Vernaleo

Unfortunately, I am not comfortable putting unobscured email addresses
on the web, but this shouldn't be too hard to figure out.

		(my_first_name)@netpurgatory.com

This is free software and is distributed under the terms of the GNU
GPL.  See file gpl.txt (which should be included) for the full text.

This program requires perl (obviously) as well as ImageMagick.  It has
only been tried on GNU/Linux, but should work on anything with a
roughly unix style directory structure (.. and /, and all that).  It
is also not able to deal with picture file names spaces or funny
charaters (but you shouldn't use those anyway).  Just run the script
and tell it a directory with pictures (which you must have write
permissions to), and it will produce a directory of thumbnails, a
webpage with all the thumbnails, and links to the origional pictures.
If you put the '-c' option after the directory name, it will make new
thumbnails and mid-sized pictures, even if old ones exist (to allow
for updating old pages).

As of version 1.2, it recursively looks through all directories under
the one you give it and make thumbnails and pages of any page with
pictures below it.  It then makes a page called pictures_main.html
with links to all the subpages of thumbnails.

For version 1.3, some navigation improvements have been added.  It also
makes use of the fact that apache usually will display index.html if
no other page is selected for a directory.

Version 1.4 is a bugfix (sort of) release.  Safari (based on KHTML)
and Internet Explorer both displayed certain images incorrectly
because they do not properly follow the height and width options to
the img tag.  I fixed things for KHTML and as a side effect, Internet
Explorer also displays things correctly.

For Version 1.5, the web pages contain medium sized pictures and a
link to the full sized ones.  Also the '-c' option to make new
thumbnails and mid-sized pictures even when old ones exist has been
added.

Version 1.5.1 Minor change for stallman.org, don't think I bothered to
	      put this on up seperately.

Version 1.6.0 2012/04/16
	      Switch to html5 output.
	      Also corrected link to my website.

Version 1.6.1 2012/09/27
	      Added 'use strict;'

Version 1.6.2 2012/02/09
	      Remove extraneous slash from some paths.
	      Correct my url (hasn't been umd for years).
	      Fix bug from v1.6.1 where pictures can be counted more
	      than once.

Version 1.6.3 2013/06/09
	      Can add captions.  For a picture named FILE.jpg include
	      a file with the caption named FILE.jpg.txt  For the
	      index pages, include a file in the same directory named
	      index.html.txt (or index2.html.txt for top-level
	      directories that have pictures and directories.
	      Always generate page text.  Clean option (-c) only
	      impacts if we try to regenerate images.

Version 1.7 2014/08/28
	      Some code cleanup.
	      Fix typo in html comment.
	      Add links to directories below the current directory
	      (except on the main page which is dealt with
	      specially).  Requested by rms.