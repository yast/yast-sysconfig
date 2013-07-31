# encoding: utf-8

# File:	clients/sysconfig.ycp
# Package:	Sysconfig editor
# Summary:	Main file
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# Main file for sysconfig configuration. Uses all other files.
module Yast
  class SysconfigClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of the sysconfig</h3>

      textdomain "sysconfig"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Sysconfig module started")

      Yast.import "Sysconfig"
      Yast.import "CommandLine"

      Yast.include self, "sysconfig/wizards.rb"
      Yast.include self, "sysconfig/cmdline.rb"

      # Command line definition
      @cmdline = {
        # help text header - sysconfig editor
        "help"       => _(
          "Editor for /etc/sysconfig Files"
        ),
        "id"         => "sysconfig",
        "guihandler" => fun_ref(method(:SysconfigSequence), "boolean ()"),
        "initialize" => fun_ref(Sysconfig.method(:Read), "boolean ()"),
        # use write handler - disable progress bar
        "finish"     => fun_ref(
          method(:writeHandler),
          "boolean ()"
        ),
        "actions"    => {
          "list"    => {
            # help text for command 'list'
            "help"    => _(
              "Display configuration summary"
            ),
            "handler" => fun_ref(method(:listHandler), "boolean (map)")
          },
          "set"     => {
            # help text for command 'set' 1/3
            # Split string because of technical issues with line breaks.
            # Adjust translation with other two parts to give a clear final text.
            "help"    => [
              _(
                "Set value of the variable. Requires options 'variable' and 'value'"
              ),
              # help text for command 'set' 2/3
              # Split string because of technical issues with line breaks.
              # Adjust translation with other two parts to give a clear final text.
              _(
                "or 'variable=value', for example, variable=DISPLAYMANAGER value=gdm"
              ),
              # help text for command 'set' 3/3
              # Split string because of technical issues with line breaks.
              # Adjust translation with other two parts to give a clear final text.
              _("or simply DISPLAYMANAGER=gdm")
            ],
            "handler" => fun_ref(
              method(:setHandler),
              "boolean (map <string, any>)"
            ),
            "options" => ["non_strict"]
          },
          "clear"   => {
            # help text for command 'set'
            "help"    => _(
              "Set empty value (\"\")"
            ),
            "handler" => fun_ref(
              method(:clearHandler),
              "boolean (map <string, any>)"
            )
          },
          "details" => {
            # help text for command 'details'
            "help"    => _(
              "Show details about selected variable"
            ),
            "handler" => fun_ref(
              method(:detailsHandler),
              "boolean (map <string, any>)"
            )
          }
        },
        "options"    => {
          "all"      => {
            # help text for option 'all'
            "help" => _("Display all variables")
          },
          "variable" => {
            # help text for option 'variable'
            "help" => [
              _("Selected variable"),
              _("If the variable is available in several files use"),
              _("<variable>$<file_name> syntax,"),
              _("for example CONFIG_TYPE$/etc/sysconfig/mail.")
            ],
            "type" => "string"
          },
          "value"    => {
            # help text for option 'value'
            "help" => _("New value"),
            "type" => "string"
          }
        },
        "mappings"   => {
          "list"    => ["all"],
          "set"     => ["variable", "value"],
          "clear"   => ["variable"],
          "details" => ["variable"]
        }
      }

      # main ui function
      @ret = CommandLine.Run(@cmdline)

      Builtins.y2debug("ret == %1", @ret)

      # Finish
      Builtins.y2milestone("Sysconfig module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::SysconfigClient.new.main
