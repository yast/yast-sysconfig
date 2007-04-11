#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/sysconfig

client_DATA =			\
	sysconfig.ycp		\
	sysconfig_auto.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	cmdline.ycp		\
	routines.ycp

desktop_DATA =			\
	sysconfig.desktop

module_DATA =			\
	Sysconfig.ycp

ybin_SCRIPTS =			\
	parse_configs.pl

ydata_DATA =                    \
	sysedit.agent		\
	descriptions

sysconfig:
	ln -sf . sysconfig

ycpchook = sysconfig

SUBDIRS = config

YCPCFLAGS=-I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(ybin_SCRIPTS) $(ydata_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
