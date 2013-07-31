# encoding: utf-8

# File:	include/sysconfig/wizards.ycp
# Package:	Configuration of sysconfig
# Summary:	Wizards definitions
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
module Yast
  module SysconfigWizardsInclude
    def initialize_sysconfig_wizards(include_target)
      Yast.import "UI"

      textdomain "sysconfig"

      Yast.import "Wizard"
      Yast.import "Sysconfig"

      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "Sequencer"
      Yast.import "Confirm"

      Yast.include include_target, "sysconfig/complex.rb"
      Yast.include include_target, "sysconfig/dialogs.rb"
    end

    # Main workflow of the sysconfig configuration
    # @return sequence result
    def MainSequence
      aliases = { "main" => lambda { MainDialog() } }

      sequence = {
        "ws_start" => "main",
        "main"     => { :abort => :abort, :next => :next }
      }

      ret = Sequencer.Run(aliases, sequence)

      ret
    end

    # Whole configuration of sysconfig but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def SysconfigAutoSequence
      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("sysconfig")

      # initialization
      if Mode.config && !Sysconfig.Modified &&
          (Sysconfig.tree_content == nil ||
            Builtins.size(Sysconfig.tree_content) == 0)
        Sysconfig.Read
      end

      ret = MainSequence()

      UI.CloseDialog
      ret
    end

    def CheckRoot
      return :abort if !Confirm.MustBeRoot

      :next
    end


    # Whole configuration of sysconfig
    # @return sequence result
    def SysconfigSequence
      aliases = {
        "check" => [lambda { CheckRoot() }, true],
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "check",
        "check"    => { :next => "read", :abort => :abort },
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("sysconfig")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog

      ret == :next
    end
  end
end
