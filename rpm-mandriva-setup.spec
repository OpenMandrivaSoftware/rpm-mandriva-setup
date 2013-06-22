# we want /etc/rpm/platform and rpmgenplatform only on rpm5.org < 5.2
%define rpmplatform %{?evr_tuple_select: 0}%{!?evr_tuple_select: %(if rpm --help | grep -q yaml; then echo 1; else echo 0; fi)}

Summary:	The Mandriva rpm configuration and scripts
Name:		rpm-mandriva-setup
Version:	1.140
Release:	5
Source0:	%{name}-%{version}.tar.xz
License:	GPLv2+
Group:		System/Configuration/Packaging
Url:		http://svn.mandriva.com/cgi-bin/viewvc.cgi/soft/rpm/rpm-setup/
# for "make test":
BuildRequires:	rpm-devel
#BuildRequires:	rpm-manbo-setup-build
#Requires:		rpm-manbo-setup-build
%if !%{rpmplatform}
# older rpm do not load /usr/lib/rpm/manbo/rpmrc:
Conflicts:	rpm < 1:5.4.4
BuildArch:	noarch
%endif

%description
The Mandriva rpm configuration and scripts.

%package build
Group:		System/Configuration/Packaging
Summary:	The Mandriva rpm configuration and scripts to build rpms
Requires:	spec-helper >= 0.6-5mdk
Requires:	pkgconfig
Requires:	python-pkg-resources
Requires:	perl(JSON)
Requires:	perl(YAML)
Requires:	perl(File::Basename)
Requires:	perl(File::Find)
Requires:	perl(Getopt::Long)
Requires:	perl(Pod::Usage)
Conflicts:	spec-helper <= 0.26.1

%description build
The Mandriva rpm configuration and scripts dedicated to build rpms.

%prep
%setup -q

%build

%configure	--build=%{_build} \
%if %{rpmplatform}
		--with-rpmplatform \
%endif

%make

%install
%makeinstall_std

# spec mode for emacs
install -d %{buildroot}%{_datadir}/emacs/site-lisp/
install -m644 rpm-spec-mode.el %{buildroot}%{_datadir}/emacs/site-lisp/

install -d %{buildroot}%{_sysconfdir}/emacs/site-start.d
cat <<EOF >%{buildroot}%{_sysconfdir}/emacs/site-start.d/%{name}.el
(setq auto-mode-alist (cons '("\\\\.spec$" . rpm-spec-mode) auto-mode-alist))
(autoload 'rpm-spec-mode "rpm-spec-mode" "RPM spec mode (mandrakized)." t)
EOF

# workaround to fix build with rpm-mandriva-setup 1.96
touch debugfiles.list

%files
%if %rpmplatform
%{_bindir}/rpmgenplatform
%config(noreplace) %{_sysconfdir}/rpm/platform
%ifarch x86_64
%config(noreplace) %{_sysconfdir}/rpm/platform32
%endif
%endif

%files build
%doc NEWS ChangeLog
%dir %{_prefix}/lib/rpm/mandriva
%{_prefix}/lib/rpm/mandriva/*
%{_datadir}/emacs/site-lisp/rpm-spec-mode.el
%config(noreplace) %{_sysconfdir}/emacs/site-start.d/%{name}.el


%changelog
* Thu May 31 2012 Andrey Bondrov <abondrov@mandriva.org> 1.140-2
+ Revision: 801621
- Bump release

* Tue Mar 13 2012 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.140-1
+ Revision: 784800
- perl.prov: generate perl(abi) provides

* Sat Mar 03 2012 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.139-1
+ Revision: 781973
- perl.prov: skip modules with lower-case names

* Fri Mar 02 2012 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.138-1
+ Revision: 781892
- perl.req: generate perl(abi) >= <version> dependencies for perl modules
  that's not perl extensions
- php.req: fix warning
  	'Having no space between pattern and following word is deprecated1'
- php.{req,prov}: fix passing files as arguments
- php.req: print warning in stead of dying on problems reading files
- kill off dead macro.in & build.macros.in
- kill rpmeval
- drop dead tests
- perl.req: move perl(abi) dependency from find-requires so that it may
  be picked up by the internal dependency generator
- perl.req: skip any modules not starting with upper case letters to get
  consistent behaviour for internal dependency generator
- check suite is dead

* Thu Feb 23 2012 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.137-1
+ Revision: 779589
- remove dependency on rpm-mandriva-setup for -build package, it's about to die
- rpm-mandriva-setup-build now owns %%{_prefix}/lib/rpm/mandriva
- clean out some old junk
- perl.req: avoid emitting empty perl() module deps (@rpm.org)
- perl.prov: skip over =for ... perlpod construct (rhbz#477516, @rpm.org)
- perl.prov: handle multiline split package defs better (rhbz#214496, @rpm5.org)
- perl.prov: do not emit perl(main) (rhbz#177960, @rpm5.org)
- perl.{req,req-from-meta,prov}: warn about unreadable files (@rpm.org)
- perl.req: improved handling of here-docs and POD sections (@rpm5.org)
- perl.req: fix 'Failed dependencies: perl(\s+) is needed by rpm-build' (@rpm5)
- perl.req: fix 'use base qw($isa);' matching (@rpm5.org)
- perl.req: skip multiline qw() sections a bit better (@rpm5.org)
- perl.req: bugfix for statements like:
  	use base qw(DBIx::SearchBuilder RT::Base); (@rpm5.org)
- perl.req: handle statements like:
  	use base qw( Class::Accessor::Chained::Fast ); (@rpm5.org)
- perl.{prov,req}: skip new-fangled head[34] while gerenerating deps (@rpm5.org)
- perl.req: allow for "our" in from front of $RPM_Requires (@rpm5.org)
- perl.req: avoid extracting bogus deps in q{} sections (rhbz#198033, @rpm5.org)
- keep lower-case perl provides in automatic extraction (from Mageia)
- extract perl requires from MYMETA.yml/MYMETA.json when present (from Mageia)
- ignore files not supported for perl.req-from-meta
- modify perl.req-from-meta to accept list of files read from stdin so that
  it potentially may be used with rpm's internal dependency generator
- get rid of extra newlines printed by perl dependency generator which will
  confuse rpm's internal dependency generator

* Tue Feb 07 2012 Oden Eriksson <oeriksson@mandriva.com> 1.136-2
+ Revision: 771513
- bump release
- the manbo crap was merged into rpm i believe

* Mon Jan 23 2012 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.136-1
+ Revision: 767023
- package is now noarch
- drop overlapping conflicts
- change to strict version requires on perl(abi) for perl extensions as ABI
  backward compatibility cannot be guaranteed

* Sun Dec 11 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.135-1
+ Revision: 740222
- new version:
  	o "resolve" /bin/env foo interpreter to actual path, rather than
  	  generating dependencies on coreutils, should trim off ~800
  	  dependencies more

* Sun Dec 11 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.134-1
+ Revision: 740216
- new version:
  	o drop automatically generated dependencies on interpreters we either
  	  don't need dependencies on or that we have other dedicated dependency
  	  generators for making them duplicate, reducing another ~5K packages'
  	  dependencies at next rebuild.
  	o drop automatically generated rtld(GNU_HASH) dependencies, it's been
  	  provided by glibc for five years now and can safely be assumed that
  	  there's no longer any need for it, reducing ~5K packages' dependency
  	  on it during next rebuild.

* Sat Nov 26 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.133-2
+ Revision: 733521
- add conflict on older rpm releases to ensure that we won't end up with the
  macros moved out from this package missing

* Thu Nov 24 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.133-1
+ Revision: 733194
- drop generating dependencies on packages for triggers, these will be fired
  when packages gets installed at later time anyways
- move remaining macros to rpm package

* Thu Nov 17 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.132-1
+ Revision: 731388
- merge scripts and parts of macros from rpm-manbo-setup package
- drop brp-compress, brp-strip, brp-strip-comment-note & brp-strip-static-archive

* Fri Nov 11 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.131-1
+ Revision: 730065
- new version:
  	o drop python macros that's now part of rpm upstream.
  	o drop using our own find-lang.pl as well, use find-lang.sh distributed
  	  with rpm in stead.
  	o drop using our own version of find-debuginfo.sh, our changes has now
  	  been merged upstream.

* Thu Jul 14 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.130-1
+ Revision: 689988
- new version:
  	o add a EXCLUDE_FROM_FULL_STRIP environment variable to find-debuginfo.sh, so
  	  that we can exclude files from being completely stripped, but for their
  	  debugging symbols.

* Fri Jun 17 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.129-1
+ Revision: 685858
- new version:
  	o only generate platform macros if explicitly enabled
  	o generate a perl(abi) = <version> provide when libperl.so is found
  	o make perl packages require perl(abi) >= <version> rather than
  	  perlapi-<version>
  	o use python, ruby, kernel module, pkgconfig & gstreamer dependency
  	  extractors from rpm5.org upstream

* Fri May 27 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.128-1
+ Revision: 679744
- remove dead perl-base dependency with broken epoch hack giving tons of errors..

* Tue May 17 2011 Funda Wang <fwang@mandriva.org> 1.127-1
+ Revision: 675140
- 1.127: add desktop-file.prov and fontconfig.prov from rpm.org

* Mon May 09 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.126-1
+ Revision: 672987
- new version:
  	o revert _host full triplet, due to lack of testing and breakage (#63234)

* Fri May 06 2011 Funda Wang <fwang@mandriva.org> 1.125-2
+ Revision: 669775
- 1.125: fix script file filtering, according to latest changes in file command

* Thu May 05 2011 Oden Eriksson <oeriksson@mandriva.com> 1.124-2
+ Revision: 669435
- mass rebuild

* Thu May 05 2011 Funda Wang <fwang@mandriva.org> 1.124-1
+ Revision: 669241
- 1.1.124: fix trigger requirements helpers

* Wed May 04 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.123-1
+ Revision: 666892
- drop dependency on multiarch-utils as it's now merged with rpm
- new version:
  	o fix _host to have full host triplet, in order to unbreak arm
  	  (from Arnaud Patard)
  	o merge updated pkgconfigdeps.sh script from mageia
  	o drop autogenerated dependencies on multiarch-utils as it's now merged
  	  with rpm
  	o autogenerate dependencies on various packages required for triggers
  	  (from Funda Wang)
  	o strip kernel modules also even if executable bit isn't set

* Sun Apr 24 2011 Funda Wang <fwang@mandriva.org> 1.122-3
+ Revision: 658257
- more runtime req for various scripts

* Sun Apr 24 2011 Funda Wang <fwang@mandriva.org> 1.122-2
+ Revision: 658250
- requires perl-json for /usr/lib/rpm/mandriva/perl.req-from-meta

* Tue Apr 19 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.122-1
+ Revision: 655871
- pick up python(abi) version from python path only, when adding requires

* Tue Apr 05 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.121-1
+ Revision: 650743
- revert compiler optimization disablers now fixed in gcc 4.6.0 (#62900)

* Thu Mar 31 2011 Funda Wang <fwang@mandriva.org> 1.120-2
+ Revision: 649356
- rebuild

  + Per Øyvind Karlsen <peroyvind@mandriva.org>
    - drop %%mkrel
    - revert removal of %%with macros which broke stuff..

* Wed Mar 30 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.119-1
+ Revision: 649322
- new version:
  	o temporarily disable certain compiler optimizations on x86_64 (#62900)
  	o build with -fPIC on x86_64 (#62900)
  	o start on dropping macros and functionality that's either deprecated
  	  or merged with rpm5 upstream since, first step in phasing out
  	  rpm-setup...

* Sun Feb 27 2011 Funda Wang <fwang@mandriva.org> 1.118-2
+ Revision: 640328
- rebuild to obsolete old packages

* Sun Feb 13 2011 Funda Wang <fwang@mandriva.org> 1.118-1
+ Revision: 637515
- new version 1.118
  really fix icon cache macro

* Fri Feb 11 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.117-1
+ Revision: 637341
- reenable %%clean_icon_cache & %%update_icon_cache macros so that they can be used
  in rpm5 file triggers (#62469)
- replace EVR separator characters (':' & '-') in kmod provides with '_' so that
  kmod() provides gets valid EVR (#62472)

* Tue Jan 25 2011 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.115-1
+ Revision: 632492
- fix pythonegg dependencies to always be lower case (#62883)

* Mon Dec 13 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.114-1mdv2011.0
+ Revision: 620641
- don't disable python dependency extractor
- new release:
  	o use upstream %%_query_all_fmt definition to get disttag, distepoch &
  	  arch returned on queries
  	o only add runtime dependencies for rubygem extractor (R?\195?\169my Clouard)

* Thu Nov 04 2010 Funda Wang <fwang@mandriva.org> 1.113-1mdv2011.0
+ Revision: 593270
- 1.113: find gstreamer provides (first step to migrate to packagekit)

* Tue Nov 02 2010 Michael Scherer <misc@mandriva.org> 1.112-2mdv2011.0
+ Revision: 592313
- disable the automatic requires based on egg for the moment, as we are busy rebuilding packages for python 2.7

* Tue Nov 02 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.112-1mdv2011.0
+ Revision: 591741
- ditch %%only_rpmrc, no need & rpmrc will die soon
  * platform specific macros only has use in -build package, so stick it there
- don't include platform specific macros in both packages
- new release: 1.112
  	o enable python egg provides/requires

* Sat Oct 30 2010 Anssi Hannula <anssi@mandriva.org> 1.111-1mdv2011.0
+ Revision: 590335
- version 1.111
  o generate requires on "python(abi) = x.y" instead of "python >= x.y" for
    python modules to properly handle the strict dependency.
  o remove runtime dependencies from %%py_requires as they are now handled
    automatically

  + Per Øyvind Karlsen <peroyvind@mandriva.org>
    - add dependency on python-pkg-resources (required for dependency generation)

* Mon Oct 18 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.110-1mdv2011.0
+ Revision: 586622
- new release 1.110:
  	o fix warning from rubygems.rb
  	o drop %%gem_unpack, equivalent behaviour has been implemented in
  	  %%setup now

* Sun Oct 17 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.109-1mdv2011.0
+ Revision: 586143
- new release: 1.109
  	o don't install dependencies for gems when using %%gem_install
  	o fix build with rpm 5.3

* Sat Oct 16 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.108-1mdv2011.0
+ Revision: 585986
- don't exclude platform macros
- new release: 1.108
  	o add gem_helper.rb and it's corresponding macros %%gem_unpack,
  	  %%gem_build & gem_install for simplifying & streamlining ruby gem packaging.

* Thu Sep 09 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.107-1mdv2011.0
+ Revision: 576894
- new release: 1.07
  	o enables automatic ruby gem dependency extractor

* Fri Jul 16 2010 Jérôme Quelin <jquelin@mandriva.org> 1.106-1mdv2011.0
+ Revision: 554229
- update to version 1.106

* Wed Jul 14 2010 Jérôme Quelin <jquelin@mandriva.org> 1.105-1mdv2011.0
+ Revision: 553267
- update to 1.105

* Tue Apr 27 2010 Christophe Fergeau <cfergeau@mandriva.com> 1.104-1mdv2010.1
+ Revision: 539551
- 1.104
- revert library stripping change which has the unwanted side-effect of
  making shared libs bigger

* Fri Apr 16 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.103-1mdv2010.1
+ Revision: 535502
- nwe release: 1.103 (ensures '-g' gets passed to strip for libraries)

* Thu Apr 08 2010 Michael Scherer <misc@mandriva.org> 1.102-1mdv2010.1
+ Revision: 532866
- new release 1.102, to fix python3 being non installable

* Fri Mar 26 2010 Jérôme Quelin <jquelin@mandriva.org> 1.101-1mdv2010.1
+ Revision: 527811
- update to 1.101

* Sun Mar 14 2010 Jérôme Quelin <jquelin@mandriva.org> 1.100-1mdv2010.1
+ Revision: 519089
- update to 1.100

* Tue Mar 09 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.99-1mdv2010.1
+ Revision: 516814
- new release: 1.99

* Fri Mar 05 2010 Per Øyvind Karlsen <peroyvind@mandriva.org> 1.98-1mdv2010.1
+ Revision: 514658
- cosmetics
- new release: 1.98

* Sat Dec 12 2009 Anssi Hannula <anssi@mandriva.org> 1.97-1mdv2010.1
+ Revision: 477735
- 1.97
  o fix package build when the debug package is empty (regression
    introduded in 1.96)

* Thu Dec 10 2009 Anssi Hannula <anssi@mandriva.org> 1.96-1mdv2010.1
+ Revision: 476112
- 1.96
  o fix perl.prov to assign versions to provides when the version is
    declared with 'our' or 'my' keyword, or when it is prepended with
    code (J?\195?\169r?\195?\180me Quelin)
  o replace %%sunsparc with %%sparc & %%sparcx (from rpm5.org,
    Per ?\195?\152yvind Karlsen)
  o support ELF executables only as a.out has been deprecated since ages
    ago (fixes objdump 'File format not recognized' errors)
    (Per ?\195?\152yvind Karlsen)
  o don't try finding debug files in buildroot when there's none
- drop obsolete external ChangeLog, use up-to-date internal one instead
- move ChangeLog to build subpackage and provide NEWS as well

* Fri Sep 25 2009 Olivier Blin <blino@mandriva.org> 1.95-1mdv2010.0
+ Revision: 448670
- 1.95
- MIPS and ARM support (from Arnaud Patard):
  o add mipsel support
  o introduce CANONTARGETGNU, to be able to use -gnueabi for ARM
  o add arm support and use -gnueabi instead of -gnu
- fix bootstrapping by defining some macros (from Arnaud Patard)

* Sat Aug 08 2009 Anssi Hannula <anssi@mandriva.org> 1.94-1mdv2010.0
+ Revision: 411661
- 1.94
  o update perl_convert_version to keep alphabetic tail in version number
    (Luca Berra)

* Tue Jul 28 2009 Christophe Fergeau <cfergeau@mandriva.com> 1.93-1mdv2010.0
+ Revision: 402283
- 1.93:
- update perl_convert_version macro (J?\195?\169r?\195?\180me Quelin)

  + Per Øyvind Karlsen <peroyvind@mandriva.org>
    - always include platform specific macros for rpm5.org compatibility, rpm.org
      is also planning on burying rpmrc in the future anyways...

* Fri Jul 10 2009 Christophe Fergeau <cfergeau@mandriva.com> 1.92-1mdv2010.0
+ Revision: 394187
- 1.92:
- making sure automatic provides & requires for perl package are using the
  new macro %%perl_convert_version (jquelin)
- rpm5 fixes (peroyvind)

  + Per Øyvind Karlsen <peroyvind@mandriva.org>
    - install common.macros to same location for rpm5.org as well
    - move platform specific directories under a dedicated 'platform/' directory
    - disable /etc/rpm/platform for rpm >= 5.2

* Tue Feb 03 2009 Christophe Fergeau <cfergeau@mandriva.com> 1.91-1mdv2009.1
+ Revision: 336912
- 1.91:
- build.macros.in
  o add new perl_convert_version macro to convert cpan version to rpm version
- git-repository--after-tarball:
  o commit the tarball with user "unknown author <cooker@mandrivalinux.org>"
  o commit the tarball using the tarball's modification time

* Thu Jan 29 2009 Pixel <pixel@mandriva.com> 1.90-1mdv2009.1
+ Revision: 335288
- 1.90: call patch with -U (aka --unified-reject-files)

* Thu Jan 29 2009 Pixel <pixel@mandriva.com> 1.89-1mdv2009.1
+ Revision: 335222
- 1.89:
- when %%_with_git_repository is set, define %%_after_setup and %%_patch to use
  the new scripts git-repository--after-tarball and git-repository--apply-patch

* Wed Jan 07 2009 Christophe Fergeau <cfergeau@mandriva.com> 1.88-1mdv2009.1
+ Revision: 326731
- Version 1.88 - 7 January 2009, by Christophe Fergeau
- fix ugly warning during invocation of php.req
- RPM5 fixes

* Mon Sep 22 2008 Pixel <pixel@mandriva.com> 1.87-1mdv2009.0
+ Revision: 286462
- 1.87: really don't add php dependencies for doc files

* Fri Sep 19 2008 Pixel <pixel@mandriva.com> 1.86-1mdv2009.0
+ Revision: 285819
- 1.86: php.req: don't add php dependencies for doc files

* Mon Jul 21 2008 Olivier Blin <blino@mandriva.org> 1.85-1mdv2009.0
+ Revision: 239425
- 1.85
- add make_dm_session macro that calls fndSession

* Thu Jul 10 2008 Pixel <pixel@mandriva.com> 1.84-1mdv2009.0
+ Revision: 233360
- 1.84, bugfix release:
- fix %%update_icon_cache/%%clean_icon_cache

* Thu Jul 10 2008 Pixel <pixel@mandriva.com> 1.83-1mdv2009.0
+ Revision: 233345
- 1.83: intelligent %%update_icon_cache/%%clean_icon_cache which are null for
  caches handled through filetriggers, but as used to be for other caches

* Mon Jun 23 2008 Pixel <pixel@mandriva.com> 1.82-1mdv2009.0
+ Revision: 227992
- 1.82:
- find-lang.pl: do not own /usr/share/locales/$lang/LC_MESSAGES to speed-up rpm

* Fri Jun 20 2008 Pixel <pixel@mandriva.com> 1.81-1mdv2009.0
+ Revision: 227397
- 1.81: fixes deprecated macros that were broken in previous release
  (%%update_icon_cache, %%clean_icon_cache, %%post_install_gconf_schemas)

* Fri Jun 13 2008 Pixel <pixel@mandriva.com> 1.80-1mdv2009.0
+ Revision: 218689
- 1.80: macros deprecated by rpm filetriggers now return nothing

* Tue Jun 10 2008 Pixel <pixel@mandriva.com> 1.79-1mdv2009.0
+ Revision: 217534
- 1.79: use lzma by default to compress binary packages (instead of gzip)

* Mon Jun 02 2008 Pixel <pixel@mandriva.com> 1.78-1mdv2009.0
+ Revision: 214280
- 1.78 (remove test for %%_localstatedir)
- 1.77: activate filetriggers (cf http://wiki.mandriva.com/en/Rpm_filetriggers)
- add "requires: mandriva-release" in rpm-mandriva-setup-build
  (but note that one should really have basesystem-minimal installed)

* Tue Apr 01 2008 Olivier Blin <blino@mandriva.org> 1.76-1mdv2008.1
+ Revision: 191515
- 1.76
- provide "kmod(module) = PACKAGE_VERSION" for dkms binary modules as
  well (#35074)
- prefer DEST_MODULE_NAME over BUILT_MODULE_NAME if present in
  dkms.conf for dkms modules provides

* Fri Mar 28 2008 Pixel <pixel@mandriva.com> 1.75-1mdv2008.1
+ Revision: 190831
- 1.75:
- remove some more macros which are now in rpm-manbo-setup
- make sure debug files are world-readable

* Fri Feb 15 2008 Pixel <pixel@mandriva.com> 1.74-1mdv2008.1
+ Revision: 168865
- order macros.d files to be loaded after rpm-manbo-setup macros
- 1.74: remove macros needed for Manbo packages (they are now in rpm-manbo-setup)

* Thu Feb 14 2008 Pixel <pixel@mandriva.com> 1.73-1mdv2008.1
+ Revision: 168467
- 1.73: rpmpopt, rpmb_deprecated and rpmrc are now in rpm-manbo-setup

* Thu Feb 14 2008 Pixel <pixel@mandriva.com> 1.72-2mdv2008.1
+ Revision: 167732
- move /usr/lib/rpm/mandriva/macros to /etc/rpm/macros.d/common.macros
  (to be more path agnostic) (nb: only done when using rpmrc)

* Tue Jan 29 2008 Pixel <pixel@mandriva.com> 1.72-1mdv2008.1
+ Revision: 159862
- 1.72
- add option --with-only-rpmrc: per-arch macros are not installed
  (since %%optflags is already in rpmrc and other macros are now in standard
   rpm per-arch macros)
- /etc/rpm/macros.d/build.macros
  o move here most macros from /usr/lib/rpm/<vendor>/macros,
    those macros will not be available anymore when rpm-<vendor>-setup-build
    is not installed
  o restore %%check macro. it allows "--without check".
  o explain the advantage of "--without <section>" (inherited from conectiva)
  o remove duplicated macros
  o remove %%_multilibno (already defined in both /usr/lib/rpm/<arch>/macros
    and/or /usr/lib/rpm/<vendor>/<arch>/macros)
- /usr/lib/rpm/<vendor>/macros:
  o add %%_gnu and %%_target_platform (was in <arch>/macros)
- /usr/lib/rpm/<vendor>/rpmopt:
  o drop --scripts alias (nicely handled by rpm's rpmpopt for some time)

* Thu Jan 24 2008 Pixel <pixel@mandriva.com> 1.71-1mdv2008.1
+ Revision: 157286
- 1.71: do package rpmb_deprecated

* Wed Jan 23 2008 Pixel <pixel@mandriva.com> 1.70-1mdv2008.1
+ Revision: 157063
- 1.70: deprecate "rpm -b" in favor of "rpmbuild -b"

* Tue Jan 22 2008 Pixel <pixel@mandriva.com> 1.69-1mdv2008.1
+ Revision: 156378
- 1.69: Make %%serverbuild define CFLAGS, CXXFLAGS and RPM_OPT_FLAGS variables
  as used to be (cf #32050)

* Thu Jan 17 2008 Pixel <pixel@mandriva.com> 1.68-2mdv2008.1
+ Revision: 154002
- ensure one can't upgrade rpm-mandriva-setup without upgrading rpm (#36291)

* Mon Jan 07 2008 Pixel <pixel@mandriva.com> 1.68-1mdv2008.1
+ Revision: 146334
- 1.68: do not use ssp_flags on archs which do not handle it (thanks to rtp)

  + Olivier Blin <blino@mandriva.org>
    - restore BuildRoot

* Fri Dec 21 2007 Pixel <pixel@mandriva.com> 1.67-1mdv2008.1
+ Revision: 136418
- 1.67: automatically require perlapi-<perl-version> for binary perl modules
        (so that we can cleanly handle perl API breakage)

* Thu Dec 20 2007 Pixel <pixel@mandriva.com> 1.66-2mdv2008.1
+ Revision: 135434
- 1.66:
- rpm-spec-mode.el: update known rpm groups (#27773)
- make %%serverbuild modify %%optflags instead of shell variables (Anssi) (#32050)

* Wed Dec 19 2007 Pixel <pixel@mandriva.com> 1.65-1mdv2008.1
+ Revision: 134746
- use --with-rpmplatform when building with jbj's rpm
  (since rpm 4.4.2.2 works better with no /etc/rpm/platform)
- 1.65:
- add option --with-rpmplatform to install or not /etc/rpm/platform and genplatform
- rpm-spec-mode.el: use buildroot macro instead of RPM_BUILD_ROOT environment variable

  + Thierry Vignaud <tv@mandriva.org>
    - kill re-definition of %%buildroot on Pixel's request

* Mon Dec 17 2007 Pixel <pixel@mandriva.com> 1.64-1mdv2008.1
+ Revision: 125513
- 1.64:
- define %%defaultbuildroot instead of %%buildroot (fixes #34705),
  this needs at least rpm 4.4.2.2-2mdv
- add rpm 4.4.6 python macros for compatibility
  (even if it overlaps with py_* macros)

* Tue Oct 02 2007 Olivier Blin <blino@mandriva.org> 1.63-1mdv2008.0
+ Revision: 94525
- 1.63
- fix check for kmod.prov (reported by Vincent Danen)

* Thu Sep 27 2007 Olivier Blin <blino@mandriva.org> 1.62-1mdv2008.0
+ Revision: 93247
- 1.62 (#30935, thanks to Danny for the help)
- kmod.prov: print module provides even if no version is found
- kmod.prov: use vermagic instead of srcversion
- kmod.prov: fix match of modules with '-'

* Tue Sep 25 2007 Olivier Blin <blino@mandriva.org> 1.61-1mdv2008.0
+ Revision: 92786
- 1.61
- substitute $PACKAGE_NAME in kmod() provides
- fix handling multiple dkms.conf files (it probably won't happen in real life)

* Thu Sep 20 2007 Pixel <pixel@mandriva.com> 1.60-1mdv2008.0
+ Revision: 91655
- 1.60:
- handle symlinks the same way as files in find-lang.pl, some symlinks in
  documentation were previously left out (Anssi)

* Fri Sep 14 2007 Pixel <pixel@mandriva.com> 1.59-1mdv2008.0
+ Revision: 85645
- 1.59:
- find-requires:
  o fix GCJ AOT directory regexp in find-requires.in (anssi)
  o remove "Using BuildRoot: ..." message, it's mostly a duplicate of rpm's
    "Finding Requires ...", and it's too verbose when using "rpm -bb --quiet"

* Mon Sep 10 2007 Pixel <pixel@mandriva.com> 1.58-1mdv2008.0
+ Revision: 84080
- 1.58:
- find-requires.in:
  o do not use buildroot since it may contain double slashes whereas filelist
    do not (fixes missing require on perl-base and python-base)
- filter.sh, macros.in:
  o handle double slashes in buildroot in filter.sh in new file exception
    macros, in case tmppath contains a trailing slash as in iurt. This also
    fixes handling of exception macros that contain spaces, which has been
    broken for a while.
- find-provides.in, find-requires.in: (Anssi)
  o ignore library dependencies of objects in /usr/lib(64)/gcj/, which are GCJ
    AOT compiled shared objects and are only useful when running the software
    in the package with gij (gcc java). If the user uses some other java VM,
    they do not need their dependencies satisfied.

* Thu Sep 06 2007 Pixel <pixel@mandriva.com> 1.57-1mdv2008.0
+ Revision: 81010
- 1.57:
- create /etc/rpm/platform32 (used instead of /etc/rpm/platform when run through linux32)

* Thu Sep 06 2007 Pixel <pixel@mandriva.com> 1.56-1mdv2008.0
+ Revision: 80698
- 1.56:
- find-lang.pl: include file by file except with --all-name (nanardon)
- set %%_host_cpu32 (used instead of %%_host_cpu when run through linux32)

* Tue Sep 04 2007 Olivier Blin <blino@mandriva.org> 1.55-1mdv2008.0
+ Revision: 79435
- 1.55: add package version in dkms.conf kmod() provides

* Tue Sep 04 2007 Olivier Blin <blino@mandriva.org> 1.54-1mdv2008.0
+ Revision: 79141
- 1.54: find kmod() provides in dkms.conf files

* Tue Aug 28 2007 Pixel <pixel@mandriva.com> 1.53-1mdv2008.0
+ Revision: 72787
- 1.53 (ensure %%debug_package doesn't modify %%{summary} in %%install section)

* Sun Aug 26 2007 Olivier Thauvin <nanardon@mandriva.org> 1.52-1mdv2008.0
+ Revision: 71487
- 1.52

* Thu Aug 23 2007 Olivier Thauvin <nanardon@mandriva.org> 1.51-1mdv2008.0
+ Revision: 69965
- 1.51 (find-lang fixes again)

* Tue Aug 21 2007 Olivier Thauvin <nanardon@mandriva.org> 1.50-1mdv2008.0
+ Revision: 68455
- 1.50

* Tue Aug 21 2007 Olivier Thauvin <nanardon@mandriva.org> 1.49-1mdv2008.0
+ Revision: 68393
- 1.49 (fix #32366)

* Thu Aug 02 2007 Pixel <pixel@mandriva.com> 1.48-1mdv2008.0
+ Revision: 58139
- tell rpmlib to open all indices before doing chroot.
  fixes "db4 error"s like #31922, and may fix #31873
  + Olivier Thauvin <nanardon@mandriva.org>
    - add default buildroot definition
    -fix #31973 (Impossible to exclude single files from autoreq/autoprov)

* Sat Jul 14 2007 Olivier Thauvin <nanardon@mandriva.org> 1.47-1mdv2008.0
+ Revision: 51909
- 1.47:
  o restore lost change after rpm breakage
  o lzma switch
  o bug fixes

* Fri Jul 06 2007 Olivier Thauvin <nanardon@mandriva.org> 1.46-1mdv2008.0
+ Revision: 48842
- 1.46: fix gconf macros (F. Crozat)

* Tue Jun 26 2007 Olivier Thauvin <nanardon@mandriva.org> 1.45-1mdv2008.0
+ Revision: 44447
- 1.45:
  o platform handle all linux case
  o rework find_lang (managing man page too)
  o use --stack-protector in optflags

* Tue Jun 19 2007 Andreas Hasenack <andreas@mandriva.com> 1.44-1mdv2008.0
+ Revision: 41507
- updated to version 1.44:
  - added -fstack-protector to serverbuild macro

* Tue Jun 19 2007 Olivier Thauvin <nanardon@mandriva.org> 1.43-1mdv2008.0
+ Revision: 41157
- 1.43 (improve platform list)
- 1.42
  o disable libtoolize by default
  o doc files are going into PKGNAME/ instead PKGNAME/VERSION
  o provide a /etc/rpm/platform for rpm 4.4.8 and above

* Wed May 09 2007 Herton Ronaldo Krzesinski <herton@mandriva.com.br> 1.41-1mdv2008.0
+ Revision: 25687
- Updated from 1.41, it removes duplicated macros already in rpm-helper,
  see ticket #30568.
- Added ChangeLog as Source, it isn't provided with svn branch on
  mandriva but was in previous 1.40 tarball, and is generated from svn
  branch from what I could see. Also updated it with changelog from 1.40
  to 1.41.


* Fri Mar 16 2007 Olivier Thauvin <nanardon@mandriva.org> 1.40-1mdv2007.1
+ Revision: 144778
- 1.40: fix install-info macros
- 1.39: add --with-html option for */doc/HTML (blino)

* Sat Mar 10 2007 Olivier Thauvin <nanardon@mandriva.org> 1.38-1mdv2007.1
+ Revision: 140790
- fix buildrequires
- 1.38
 o handle haskell dependencies (using external tools)

* Mon Feb 19 2007 Götz Waschk <waschk@mandriva.org> 1.37-1mdv2007.1
+ Revision: 122772
- filter devel(ld-linux) if using the objdump method too
- fix url
- use the right configure macro

* Sun Feb 18 2007 Olivier Thauvin <nanardon@mandriva.org> 1.36-2mdv2007.1
+ Revision: 122329
- requires pkgconfig for building to ensure dependencies are properly filled

* Sat Feb 17 2007 Olivier Thauvin <nanardon@mandriva.org> 1.36-1mdv2007.1
+ Revision: 122189
- 1.36

* Fri Feb 16 2007 Olivier Thauvin <nanardon@mandriva.org> 1.35-1mdv2007.1
+ Revision: 122015
- 1.35

* Mon Jan 15 2007 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.34-1mdv2007.1
+ Revision: 109088
- auto-detect binary files that Requires: rtld(GNU_HASH)

* Fri Dec 01 2006 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.33-1mdv2007.1
+ Revision: 89719
- fix ppc optflags
- fix ppc64 multilib
- add ppc32 optflags

* Thu Nov 30 2006 Pixel <pixel@mandriva.com> 1.32-1mdv2007.1
+ Revision: 89343
- make "rpm -qa" fast, using --nosignature (#23121)
- find-requires: (gb)
  o Merge: exclude linux-vdso64 from devel() autorequires.

* Fri Nov 10 2006 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.31-1mdv2007.1
+ Revision: 80557
- 1.31
- update default optimization flags for i586 & ppc64
- fix conditionals

* Thu Sep 07 2006 Olivier Thauvin <nanardon@mandriva.org> 1.29-3mdv2007.0
+ Revision: 60327
- revert again mkrel which magically came back, grrr

* Sat Sep 02 2006 Olivier Thauvin <nanardon@mandriva.org> 1.29-2mdv2007.0
+ Revision: 59389
- back to 0.29 + patch to please the FREEZE
- 1.30 emergency fix clean_icon_cache (goetz)

* Fri Sep 01 2006 Olivier Thauvin <nanardon@mandriva.org> 1.29-1mdv2007.0
+ Revision: 59067
- being wrong hapen sometimes: revert last change

* Fri Sep 01 2006 Olivier Thauvin <nanardon@mandriva.org> 1.28-1mdv2007.0
+ Revision: 58928
- 1.28 (subrel before distsuffix)

* Thu Aug 31 2006 Olivier Thauvin <nanardon@mandriva.org> 1.27-1mdv2007.0
+ Revision: 58819
- 1.27
- Import rpm-mandriva-setup

* Thu Jul 27 2006 Olivier Thauvin <nanardon@mandriva.org> 1.26-1mdv2007.0
- 1.26
- pkgconfig file can be located in /usr/share/pkgconfig, looking for it
  to create requirement (thanks Gotz)

* Fri Jul 14 2006 Olivier Blin <oblin@mandriva.com> 1.25-1mdv2007.0
-  1.25:
   o Force also icon cache generation on uninstall
     or removed files might be left in cache (Frederic Crozat)

* Fri Jun 30 2006 Olivier Blin <oblin@mandriva.com> 1.24-1mdv2007.0
- 1.24:
  o use %%mkrel by default in new spec files (rpm-spec-mode for emacs)

* Sun Jun 18 2006 Olivier Thauvin <nanardon@mandriva.org> 1.23-1mdv2007.0
- 1.23
- add desktop and scrollkeeper macro (F. Crozat)
- add _webapp* macros

* Sun Jun 04 2006 Olivier Thauvin <nanardon@mandriva.org> 1.22-1mdv2007.0
- 1.22
- enable pkgconfig/libtool provides
- strip bad requirement for ppc

* Thu May 25 2006 Olivier Thauvin <nanardon@mandriva.org> 1.21-1mdk
- new %%mkrel behavior

* Sun May 21 2006 Olivier Thauvin <nanardon@mandriva.org> 1.20-1mdk
- fix X11 location
- latest spec-helper adaptation

* Thu May 11 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.19-1mdk
- Revert changes made in 1.18

* Tue Apr 04 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.18-1mdk
- find-requires: require only .so that are in standard paths, and use ldd
  instead of objdump to get their list.

* Fri Mar 24 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.17-1mdk
- Don't provide .so files that aren't in standard paths
- Don't search perl files for provides if they don't end with .pm
- Fix rename macro (don't obsolete what is provided) (Ze)

* Thu Mar 16 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.16-1mdk
- Fix automatic deps for some devel packages (Guillaume Rousse)
- Update OS name

* Tue Mar 14 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.15-1mdk
- Set _repackage_all_erasures to 0 (rgs)
- Add a way to disable fortify from cflags (Olivier Thauvin)
- Add a macro to list all sparc-compatible archs (Per Øyvind Karlsen)
- Emacs mode fixes (Pixel)
- Remove pre flags on python requirement (Helio)

* Sun Jan 15 2006 Olivier Thauvin <nanardon@mandriva.org> 1.14-1mdk
- remove /etc/rpm/macros.* from macros search path
- add macro for gcjdb (Giuseppe)

* Wed Jan 11 2006 Olivier Thauvin <nanardon@mandriva.org> 1.13-1mdk
- add PYTHON-LIBDIR-NOT-FOUND, PYTHON-LIBDIR-NOT-FOUND (misc)

* Tue Jan 10 2006 Olivier Thauvin <nanardon@mandriva.org> 1.12-1mdk
- fix typo in RequireS (#20574)

* Fri Jan 06 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.11-1mdk
- Set _changelog_truncate to "3 years ago"
- Restore _query_all_fmt to its default 4.4.2 value

* Thu Jan 05 2006 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.10-1mdk
- Add _rpmlock_path to default macros

* Wed Jan 04 2006 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.9-1mdk
- find-debuginfo.sh: preserve setuid/setgid permissions when stripping
  files for -debug package
- Rafael Garcia-Suarez <rgarciasuarez at mandriva.com>
  * perl.req: Fix typo in comment
  * macros.in: Typo fix
- Olivier Thauvin <thauvin at aerov.jussieu.fr>
  * find-requires.in: - rpm output to stdout if file exists, so we
    have ignore first output in all case and keep the result only if
    we are sure rpm exit with 0
  * macros.in: - Fix PreReq, thanks neoclust to recall me this

* Tue Oct 18 2005 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.8-1mdk
- Ignore perl version requires
- Get correctly the Perl dependencies from "use base"

* Wed Oct 12 2005 Rafael Garcia-Suarez <rgarciasuarez@mandriva.com> 1.7-1mdk
- Insert a dependency on libperl.so for XS perl modules

* Fri Oct 07 2005 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.6-1mdk
- enable -debug packages for 2007
- build with -fasynchronous-unwind-tables on regular x86 too
- build C code with -fexceptions too

* Fri Oct 07 2005 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.5.1-1mdk
- fix %%py_libdir for lib64 platforms (#18772)
- perl.req: add the proper detection of 'use base qw(Foo::Bar)'
  construct (Michael Scherer)

* Fri Aug 26 2005 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.5-1mdk
- make generation of debug packages work again
- factor out compile flags and build with -D_FORTIFY_SOURCE=2

* Fri Aug 19 2005 Olivier Thauvin <nanardon@mandriva.org> 1.4-1mdk
- fix php.req about include of relatives path (P. Terjan)

* Wed Aug 17 2005 Gwenole Beauchesne <gbeauchesne@mandriva.com> 1.3-1mdk
- check-multiarch-files: fix invocation and path (/usr/lib/rpm/check-*),
  default to not check for multiarch files in 2006

* Mon Aug 08 2005 Olivier Thauvin <nanardon@zarb.org> 1.2-1mdk
- add req/prov for php pear
- add conectiva macros

* Sun Jun 26 2005 Olivier Thauvin <nanardon@mandriva.org> 1.1-4mdk
- require multiarch-utils

* Fri Jun 24 2005 Olivier Thauvin <nanardon@mandriva.org> 1.1-3mdk
- enforce requirement to avoid conflict during update

* Thu Jun 23 2005 Olivier Thauvin <nanardon@mandriva.org> 1.1-2mdk
- split package for dep

* Tue Jun 14 2005 Olivier Thauvin <nanardon@zarb.org> 1.1-1mdk
- few connectiva macros
- from Gwenole Beauchesne
  - merge from old ppc64 branch:
  * find-requires: handle ppc64 loaders

* Thu May 26 2005 Olivier Thauvin <nanardon@zarb.org> 1.0-1mdk
- 1.0:
  - disable automatic gpg key query on server
  - add automatic require for ocaml (G. Rousse)

* Fri May 13 2005 Olivier Thauvin <nanardon@mandriva.org> 0.8-1mdk
- 0.8: fix %%_localstatedir

* Fri May 13 2005 Olivier Thauvin <nanardon@mandriva.org> 0.7-1mdk
- 0.7 (integrate spec mode for emacs)

* Wed May 11 2005 Olivier Thauvin <nanardon@mandriva.org> 0.6-1mdk
- 0.6 /usr/lib

* Tue May 10 2005 Olivier Thauvin <nanardon@mandriva.org> 0.5-1mdk
- 0.5 (translate pentium[34] => i586)

* Sat May 07 2005 Olivier Thauvin <nanardon@mandriva.org> 0.4-1mdk
- 0.4
  - fix popt options

* Wed May 04 2005 Olivier Thauvin <nanardon@mandriva.org> 0.3-1mdk
- 0.3 (better compatiblity)

* Mon May 02 2005 Olivier Thauvin <nanardon@mandriva.org> 0.2-1mdk
- 0.2 (minor fix)

* Thu Apr 28 2005 Olivier Thauvin <nanardon@mandriva.org> 0.1-1mdk
- First mandriva spec

