#
# Makefile.am for y2c_sysconfig/src
#

iinfodir = $(YAST2DIR)

ynclude_HEADERS = sys_dialogs.ycp

client_DATA = sysconfig_step1.ycp sysconfig.ycp

config_DATA = sysconfig.y2cc

iinfo_DATA = meta_sys.config

EXTRA_DIST = $(client_DATA) $(config_DATA) $(iinfo_DATA)

ybin_PROGRAMS = syscreate_data
syscreate_data_SOURCES =		\
	RCDirectory.cpp RCDirectory.h	\
	RCVariable.cpp RCVariable.h	\
	TreeNode.cpp TreeNode.h		\
	main.cpp

syscreate_data_LDFLAGS = $(all_libraries)
