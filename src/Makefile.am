#
# Makefile.am for y2c_sysconfig/src
#

client_DATA = sysconfig_step1.ycp sysconfig.ycp

yncludedir = @yncludedir@/sysconfig
ynclude_DATA = sys_dialogs.ycp

config_DATA = sysconfig.y2cc

ydata_DATA = meta_sys.config

ybin_PROGRAMS = syscreate_data

EXTRA_DIST = $(ynclude_DATA) $(client_DATA) $(config_DATA) $(ydata_DATA) $(ybin_PROGRAMS)

syscreate_data_SOURCES =		\
	RCDirectory.cpp RCDirectory.h	\
	RCVariable.cpp RCVariable.h	\
	TreeNode.cpp TreeNode.h		\
	main.cpp

syscreate_data_LDFLAGS = $(all_libraries)
