#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

# $Id: configure.ac 273855 2012-03-13 16:40:25Z peroyvind $

AC_PREREQ(2.59)
AC_INIT(rpm-mandriva-setup, 1.140, peroyvind@mandriva.org)
AC_CANONICAL_TARGET
AM_INIT_AUTOMAKE(1.9 -Wno-portability no-dist-gzip dist-xz)
AC_CONFIG_SRCDIR

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_CONFIG_FILES([
                 Makefile
                 ])

dnl See if we have pkgconfig for rpm, resort to old behavior if not
PKG_CHECK_MODULES([RPM], [rpm], [
      AC_DEFINE_UNQUOTED([HAVE_RPM],1,[Define if RPM backend is available])
      CPPFLAGS="$RPM_CFLAGS $CPPFLAGS"
      LDFLAGS="$RPM_LIBS $LDFLAGS"
   ], [
      AC_PATH_PROG(RPM_PATH,rpm,none)
      if test "$RPM_PATH" = "none"; then
         AC_MSG_ERROR([RPM executable was not found in your system])
      else
         AC_DEFINE_UNQUOTED([HAVE_RPM],1,[Define if RPM backend is available])
      fi
   ]
)

AC_CHECK_LIB([rpmio], [rpmLoadMacroFile])
AC_HEADER_STDC
AC_CHECK_HEADERS([string.h rpm/rpmmacro.h rpm/rpmlib.h rpm/rpmio.h rpm/rpmtag.h])

CANONTARGETCPU=${target_cpu}
CANONTARGETGNU=-gnu

case "${target_cpu}" in
    *86|athlon|k6|pentium*) 
    RPMALLARCH="i386 i486 i586 i686 k6 athlon pentium3 pentium4"
    CANONTARGETCPU=i586
    ;;
    x86_64|amd64)
    RPMALLARCH="i386 i486 i586 i686 k6 athlon pentium3 pentium4 amd64 x86_64"
    CANONTARGETCPU=x86_64
    CANONTARGETCPU32=i586
    ;;
    ppc|powerpc)
    RPMALLARCH="ppc"
    CANONTARGETCPU=ppc
    ;;
    ppc64|powerpc64)
    RPMALLARCH="ppc ppc32 ppc64"
    CANONTARGETCPU=ppc64
    ;;
    sparc|sparcv9)
    RPMALLARCH="sparc"
    CANONTARGETCPU=sparc
    ;;
    sparc64)
    RPMALLARCH="sparc sparc64"
    CANONTARGETCPU=sparc64
    ;;
    mipsel)
    RPMALLARCH="mipsel mips32el mips64el"
    CANONTARGETCPU=mipsel
    ;;
    armv4tl)
    RPMALLARCH="arml armv4tl"
    CANONTARGETCPU=armv4tl
    CANONTARGETGNU=-gnueabi
    ;;
    armv5tl)
    RPMALLARCH="arml armv4tl armv5tl"
    CANONTARGETCPU=armv5tl
    CANONTARGETGNU=-gnueabi
    ;;
    # some armv5te cpu have buggy instruction so better disable
    # the "e" extension
    armv5tel)
    RPMALLARCH="arml armv4tl armv5tel armv5tl"
    CANONTARGETCPU=armv5tl
    CANONTARGETGNU=-gnueabi
    ;;
    armv7l)
    RPMALLARCH="arml armv4tl armv5tl armv5tel armv7l"
    CANONTARGETCPU=armv7l
    CANONTARGETGNU=-gnueabi
esac
RPMALLARCH="${RPMALLARCH} noarch"
AC_SUBST(RPMALLARCH)
AC_SUBST(CANONTARGETCPU)
AC_SUBST(CANONTARGETCPU32)
AC_SUBST(CANONTARGETGNU)

#
# get rid of the 4-th tuple, if config.guess returned "linux-gnu" for build_os
#
if echo "$build_os" | grep '.*-gnulibc1' > /dev/null ; then
    build_os=`echo "${build_os}" | sed 's/-gnulibc1$//'`
fi
if echo "$build_os" | grep '.*-gnu' > /dev/null ; then
    build_os=`echo "${build_os}" | sed 's/-gnu$//'`
fi

changequote(<, >)
build_os_exact="${build_os}"
build_os_major=`echo "${build_os}" | sed 's/\..*$//'`
build_os_noversion=`echo "${build_os}" | sed 's/[0-9]*\..*$//'`
changequote([, ])

dnl Find our os
RPMOS="$build_os_noversion"
AC_SUBST(RPMOS)

# Checks for library functions.
RPMVENDOR="Mandriva"
AC_ARG_WITH(vendor, [  --with-vendor            the vendor of this config  ])
if test $with_vendor; then
    RPMVENDOR=$with_vendor
fi
AC_SUBST(RPMVENDOR)

RPMCANONVENDOR=`echo "${RPMVENDOR}" | tr [A-Z] [a-z]`
AC_SUBST(RPMCANONVENDOR)

if test X"$prefix" = XNONE ; then
    usrprefix="$ac_default_prefix"
else
    usrprefix=$prefix
fi

RPMLIBDIR="${usrprefix}/lib/rpm"
AC_ARG_WITH(rpmlibdir, [  --with-rpmlibdir=dir    location of rpm config file ])
if test $with_rpmlibdir; then
    RPMLIBDIR=$with_rpmlibdir
fi
AC_SUBST(RPMLIBDIR)

RPMCONFDIR=${RPMLIBDIR}
AC_ARG_WITH(rpmconfdir, [  --with-rpmconfdir=dir    location of our config ])
if test $with_rpmconfdir; then
    RPMCONFDIR=$with_rpmconfdir
fi
AC_SUBST(RPMCONFDIR)

RPMVENDORDIR="${RPMCONFDIR}/${RPMCANONVENDOR}"
AC_SUBST(RPMVENDORDIR)

RPMSYSCONFDIR="/etc/rpm"
AC_ARG_WITH(rpmsysconfdir, [  --with-rpmsysconfdir=dir location of etc ])
if test $with_rpmsysconfdir; then
    RPMSYSCONFDIR=$with_rpmsysconfdir
fi
AC_SUBST(RPMSYSCONFDIR)


AC_ARG_WITH(rpmplatform, [  --with-rpmplatform		use /etc/rpm/platform ])
AM_CONDITIONAL([RPMPLATFORM],[test $with_rpmplatform])

AC_ARG_WITH(platformmacros, [  --with-platformmacros	install arch-specific macros under /usr/lib/rpm/<vendor>/platform ])
AM_CONDITIONAL([PLATFORMMACROS],[test $with_platformmacros])

AC_ARG_WITH(only-rpmrc, [  --with-only-rpmrc		rpm uses rpmrc ])
AM_CONDITIONAL([ONLY_RPMRC],[test $with_only_rpmrc])

AC_OUTPUT
