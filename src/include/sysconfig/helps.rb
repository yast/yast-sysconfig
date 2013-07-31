# encoding: utf-8

# File:	include/sysconfig/helps.ycp
# Package:	Configuration of sysconfig
# Summary:	Help texts of all the dialogs
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
module Yast
  module SysconfigHelpsInclude
    def initialize_sysconfig_helps(include_target)
      textdomain "sysconfig"

      # All helps are here
      @HELPS = {
        # Read dialog help
        "read"  => _(
          "<p><b><big>Initializing sysconfig Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ),
        # Write dialog help
        "write" => _(
          "<p><b><big>Saving sysconfig Configuration</big></b><br>\n" +
            "Please wait...<br></p>\n" +
            "\n"
        )
      } 

      # EOF
    end
  end
end
