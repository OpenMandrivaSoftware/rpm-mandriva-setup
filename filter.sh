#!/bin/sh
#---------------------------------------------------------------
# Project         : Mandriva Linux
# Module          : rpm
# File            : filter.sh
# Version         : $Id: filter.sh 227371 2007-09-08 15:34:39Z anssi $
# Author          : Frederic Lepied
# Created On      : Tue May 13 15:45:17 2003
# Purpose         : filter using grep and first argument the
# command passed as the rest of the command line
#---------------------------------------------------------------

GREP_ARG="$1"
FILE_GREP_ARG="$2"
BUILDROOT="$3"
PROG="$4"
shift 4

# use ' ' to signify no arg as rpm filter empty strings from
# command line :(
if [ "$FILE_GREP_ARG" != ' ' ]; then
	# get rid of double and trailing slashes
	BUILDROOT="$(echo "$BUILDROOT" | perl -pe 's,/+,/,g;s,/$,,')"
	perl -pe "s,^$BUILDROOT,," | grep -v "$FILE_GREP_ARG" | perl -pe "s,^,$BUILDROOT,"
else
	cat
fi | \
$PROG "$@" | \
if [ "$GREP_ARG" != ' ' ]; then
	grep -v "$GREP_ARG"
else
	cat
fi
exit 0

# filter.sh ends here
