#
# Makefile.am for y2c_rc_config/src
#

modulesdir = $(YAST2DIR)/clients
menudir    = $(YAST2DIR)/menuentries
 
include_HEADERS = \
		rc_process_db.ycp       \
		rc_dialogs.ycp

modules_DATA = rc_config_step1.ycp	\
		  rc_config.ycp

menu_DATA = menuentry_rc_config.ycp

EXTRA_DIST = $(modules_DATA) $(menu_DATA)
