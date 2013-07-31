# encoding: utf-8

# File:	include/sysconfig/routines.ycp
# Package:	Configuration of sysconfig
# Summary:	Miscelanous functions for configuration of sysconfig.
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
module Yast
  module SysconfigRoutinesInclude
    def initialize_sysconfig_routines(include_target)
      textdomain "sysconfig"

      Yast.import "Sysconfig"
      Yast.import "Popup"
    end

    # If modified, ask for confirmation
    # @return true if abort is confirmed
    def ReallyAbort
      !Sysconfig.Modified || Popup.ReallyAbort(true)
    end
  end
end
