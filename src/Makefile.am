#
# Makefile.am for y2c_sysconfig/src
#

iinfodir = $(YAST2DIR)
modulesdir = $(YAST2DIR)/clients

include_HEADERS = sys_dialogs.ycp

modules_DATA = sysconfig_step1.ycp sysconfig.ycp

config_DATA = sysconfig.y2cc

iinfo_DATA = meta_sys.config

EXTRA_DIST = $(modules_DATA) $(config_DATA) $(iinfo_DATA)

bin_PROGRAMS = syscreate_data
syscreate_data_SOURCES =		\
	RCDirectory.cpp RCDirectory.h	\
	RCVariable.cpp RCVariable.h	\
	TreeNode.cpp TreeNode.h		\
	main.cpp

syscreate_data_LDFLAGS = $(all_libraries)
