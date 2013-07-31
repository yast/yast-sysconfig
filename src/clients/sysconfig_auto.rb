# encoding: utf-8

# File:       clients/sysconfig_auto.ycp
# Package:    Configuration of sysconfig
# Summary:    Client for autoinstallation
# Authors:    Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation.
# Does not do any changes to the configuration.
#
module Yast
  class SysconfigAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "sysconfig"

      Yast.import "Sysconfig"
      Yast.include self, "sysconfig/wizards.rb"

      # The main ()
      Builtins.y2milestone("---------------------------------")
      Builtins.y2milestone("Sysconfig autoinst client started")
      @ret = nil
      @func = ""
      @param = []


      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))

        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_list?(WFM.Args(1))
          @param = Convert.to_list(WFM.Args(1))
        end
      end

      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Import data
      if @func == "Import"
        @ret = Sysconfig.Import(@param)
      # create a summary
      elsif @func == "Summary"
        @ret = Sysconfig.Summary
      elsif @func == "Packages"
        @ret = {}
      elsif @func == "Reset"
        @ret = Sysconfig.Import([])
      elsif @func == "Change"
        @ret = SysconfigAutoSequence()
      elsif @func == "Export"
        @ret = Sysconfig.Export
      elsif @func == "GetModified"
        @ret = Sysconfig.Modified
      elsif @func == "SetModified"
        Sysconfig.SetModified
      elsif @func == "Write"
        Yast.import "Progress"
        Sysconfig.write_only = true
        Progress.off
        Sysconfig.RegisterAgents
        @ret = Sysconfig.Write
        Progress.on
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = false
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Sysconfig autoinit client finished")
      Builtins.y2milestone("----------------------------------")

      deep_copy(@ret) 
      # EOF
    end
  end
end

Yast::SysconfigAutoClient.new.main
