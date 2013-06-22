# $Id: Makefile.am 273835 2012-02-24 10:39:43Z peroyvind $

arch_macrosfiles = $(RPMALLARCH:=.macros)

pkg_data = 

pkg_gconfig = \
		   platform \
		   $(if $(CANONTARGETCPU32), platform32, )

pkg_scripts = \
           filter.sh \
	        git-repository--after-tarball \
	        git-repository--apply-patch \
		   http.req \
		   magic.prov \
		   magic.req \
		   desktop-file.prov \
		   fontconfig.prov \
		   perl.prov \
		   perl.req \
		   perl.req-from-meta \
		   php.prov \
		   php.req \
		   drop-ld-no-undefined-for-shared-lib-modules-in-libtool \
		   fix-dlsearch-path-in-libtool-for-multilib \
		   fix-libtool-from-moving-options-after-libs \
		   fix-libtool-ltmain-from-overlinking \
		   force-as-needed-for-shared-lib-in-libtool


pkg_gscripts = \
		   find-provides \
		   find-requires \
		   find-provides.perl

pkg_scripts_in = $(pkg_gscripts:=.in)

BUILT_SOURCES = macros-perarch make_arch_macrosfiles.sh rpmgenplatform

pkgdatadir = @RPMVENDORDIR@

noinst_DATA = $(pkg_gconfig)

pkgdata_DATA = \
	       $(pkg_data) \
	       $(pkg_gconfig)

pkgdata_SCRIPTS = \
	$(pkg_scripts) \
	$(pkg_gscripts)

EXTRA_DIST = \
	$(pkg_data) \
	$(pkg_data_in) \
	$(pkg_scripts) \
	$(pkg_scripts_in) \
	macros-perarch.in make_arch_macrosfiles.sh.in \
	rpmgenplatform.in rpmrc.in \
	rpm-spec-mode.el

edit = sed \
	-e 's,@RPMVENDOR\@,$(RPMVENDOR),g' \
	-e 's,@RPMVENDORDIR\@,$(RPMVENDORDIR),g' \
	-e 's,@RPMCANONVENDOR\@,$(RPMCANONVENDOR),g' \
	-e 's,@RPMLIBDIR\@,$(RPMLIBDIR),g' \
	-e 's,@RPMSYSCONFDIR\@,$(RPMSYSCONFDIR),g'\
	-e 's,@RPMOS\@,$(RPMOS),g' \
	-e 's,@CANONTARGETCPU\@,$(CANONTARGETCPU),g' \
	-e 's,@CANONTARGETGNU\@,$(CANONTARGETGNU),g' \
	-e 's,@RPMALLARCH\@,$(RPMALLARCH),g'

%: %.in Makefile
	$(edit) $< > $@

$(arch_macrosfiles): rpmrc macros-perarch make_arch_macrosfiles.sh
	arch=`echo $@ | sed 's,\\.macros,,'`; \
	sh ./make_arch_macrosfiles.sh macros-perarch $$arch > $@

platform: rpmgenplatform Makefile
	perl rpmgenplatform $(CANONTARGETCPU) > $@

platform32: rpmgenplatform Makefile
	perl rpmgenplatform $(CANONTARGETCPU32) > $@

install-data-local: $(pkg_gconfig)
if ONLY_RPMRC
	echo "not installing per-arch macros which are already in rpmrc and standard rpm per-arch macros"
endif
if PLATFORMMACROS
	for i in $(RPMALLARCH); do \
	  $(mkinstalldirs) $(DESTDIR)$(RPMVENDORDIR)/platform/$${i}-$(RPMOS); \
	  $(install_sh_DATA) $${i}.macros $(DESTDIR)$(RPMVENDORDIR)/platform/$${i}-$(RPMOS)/macros; \
	done
endif
if RPMPLATFORM
	for i in $(pkg_gconfig); do \
		$(install_sh_DATA) $${i} $(DESTDIR)$(RPMSYSCONFDIR)/$${i}; \
	done
	$(install_sh_SCRIPT) rpmgenplatform $(DESTDIR)$(bindir)/rpmgenplatform
endif

.PHONY: ChangeLog

ChangeLog:
	@if [ -e ".svn" ]; then \
	    $(MAKE) ChangeLog-svn; \
	elif [ -e ".git" ]; then \
	    $(MAKE) ChangeLog-git; \
	else \
	    echo "Unknown SCM (not SVN nor GIT)";\
	    exit 1; \
	fi;

ChangeLog-svn:
	LC_ALL=C svn2cl
	rm -f *.bak

ChangeLog-git:
	@git2cl >ChangeLog

CLEANFILES = $(pkg_gscripts) $(arch_macrosfiles) $(pkg_gconfig)\
			 rpmrc macros-perarch \
			 make_arch_macrosfiles.sh
