#
# Makefile.am for y2c_rc_config/src
#

infodir    = $(YAST2DIR)
modulesdir = $(YAST2DIR)/clients
menudir    = $(YAST2DIR)/menuentries
 

include_HEADERS = \
		rc_dialogs.ycp

modules_DATA = rc_config_step1.ycp	\
		  rc_config.ycp

menu_DATA = menuentry_rc_config.ycp

info_DATA = meta_rc.config 


EXTRA_DIST = $(modules_DATA) $(menu_DATA) $(info_DATA) 



bin_PROGRAMS = rc_create_data
rc_create_data_SOURCES = \
	RCDirectory.cpp	 \
	RCDirectory.h	 \
	RCVariable.cpp	 \
	RCVariable.h	 \
	TreeNode.cpp	 \
	TreeNode.h	 \
	main.cpp	 


rc_create_data_LDADD   = -lg++
# $(LIBSOCKET)


# the library search path. 
rc_create_data_LDFLAGS = $(all_libraries) 

# them while "make clean", use CLEANFILES
#DISTCLEANFILES = $(rc_create_data_METASOURCES)

