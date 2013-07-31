# Sources for sysconfig

module_DATA = \
  modules/Sysconfig.rb

client_DATA = \
  clients/sysconfig_auto.rb \
  clients/sysconfig.rb

yncludedir = @yncludedir@/sysconfig
ynclude_DATA = \
  include/sysconfig/wizards.rb \
  include/sysconfig/dialogs.rb \
  include/sysconfig/complex.rb \
  include/sysconfig/routines.rb \
  include/sysconfig/cmdline.rb \
  include/sysconfig/helps.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/sysconfig.rnc

ybin_SCRIPTS = \
  bin/parse_configs.pl

ydata_DATA = \
  data/descriptions \
  data/sysedit.agent

desktop_DATA = \
  desktop/sysconfig.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(schemafiles_DATA) $(ybin_SCRIPTS) $(ydata_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common