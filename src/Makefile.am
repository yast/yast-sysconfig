#
# Makefile.am for y2c_sysconfig/src
#

infodir    = $(YAST2DIR)
modulesdir = $(YAST2DIR)/clients
menudir    = $(YAST2DIR)/menuentries


include_HEADERS = \
		sys_dialogs.ycp

modules_DATA = sysconfig_step1.ycp	\
		  sysconfig.ycp

menu_DATA = menuentry_sysconfig.y2cc

info_DATA = meta_sys.config

EXTRA_DIST = $(modules_DATA) $(menu_DATA) $(info_DATA)



bin_PROGRAMS = syscreate_data
syscreate_data_SOURCES = \
	RCDirectory.cpp	 \
	RCDirectory.h	 \
	RCVariable.cpp	 \
	RCVariable.h	 \
	TreeNode.cpp	 \
	TreeNode.h	 \
	main.cpp


#syscreate_data_LDADD   = -lg++
# $(LIBSOCKET)


# the library search path.
syscreate_data_LDFLAGS = $(all_libraries)

# them while "make clean", use CLEANFILES
#DISTCLEANFILES = $(syscreate_data_METASOURCES)

