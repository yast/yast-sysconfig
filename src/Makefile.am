#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/sysconfig

client_DATA =			\
	sysconfig.ycp		\
	sysconfig_auto.ycp	\
	sysconfig_proposal.ycp	\
	sysconfig_write.ycp	\
	powertweak.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

config_DATA =			\
	sysconfig.y2cc		\
	powertweak.y2cc

module_DATA =			\
	Sysconfig.ycp

ybin_SCRIPTS =			\
	parse_configs.pl

ydata_DATA =                    \
	sysedit.agent		\
	powertweak.agent	\
	descriptions

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(config_DATA) $(module_DATA) $(ybin_SCRIPTS) $(ydata_DATA)
