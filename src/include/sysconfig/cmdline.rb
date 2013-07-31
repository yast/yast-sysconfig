# encoding: utf-8

# File:
#   include/sysconfig/cmdline.ycp
#
# Package:
#   Editor for /etc/sysconfig files
#
# Summary:
#   Command line interface functions.
#
# Authors:
#   Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# All command line interface functions (handlers).
#
module Yast
  module SysconfigCmdlineInclude
    def initialize_sysconfig_cmdline(include_target)
      Yast.import "UI"
      Yast.import "Sysconfig"
      Yast.import "RichText"
      Yast.import "CommandLine"
      Yast.import "Progress"

      Yast.include include_target, "sysconfig/complex.rb"

      textdomain "sysconfig"
    end

    # Command line interface - handler for list command
    # @param [Hash] options list command options
    # @return [Boolean] Returns true (succeess)
    def listHandler(options)
      options = deep_copy(options)
      # display all variables or only modified ones?
      all = Builtins.haskey(options, "all")

      # header (command line mode output)
      CommandLine.Print(
        all == true ? _("All Variables:\n") : _("Modified Variables:\n")
      )

      modif = all == false ? Sysconfig.get_modified : Sysconfig.get_all
      result = ""

      Builtins.foreach(modif) do |v|
        descr = Sysconfig.get_description(v)
        # display a new value for modified variables
        value = Ops.get(descr, "new_value") != nil ?
          Ops.get_string(descr, "new_value", "") :
          Ops.get_string(descr, "value", "")
        result = Ops.add(
          result,
          Builtins.sformat("%1=\"%2\"\n", Sysconfig.get_name_from_id(v), value)
        )
      end 


      CommandLine.Print(result)

      true
    end

    def setHanlerProcess(variable, value, force)
      vid = variable2id(variable)

      return false if vid == nil

      result = Sysconfig.set_value(vid, value, force, false)

      # status message - %1 is a device name (/dev/hdc), %2 is a mode name (udma2), %3 is a result (translated Success/Failed text)
      CommandLine.Print(
        Builtins.sformat(
          _("\nSetting variable '%1' to '%2': %3"),
          variable,
          value,
          # result message
          result == :ok ?
            _("Success") :
            _("Failed")
        )
      )

      result == :ok
    end

    # Command line interface - handler for set command
    # @param [Hash{String => Object}] options list command options
    # @return [Boolean] True on success
    def setHandler(options)
      options = deep_copy(options)
      variable = ""
      value = ""
      force = Ops.get_boolean(options, "force", true)

      if Builtins.haskey(options, "variable") &&
          Builtins.haskey(options, "value")
        variable = Ops.get_string(options, "variable")
        value = Ops.get_string(options, "value")
      # there is just one pair in the option map,
      # user has called the module with option VARIABLE=value
      elsif Builtins.size(options) == 1
        Builtins.y2milestone("options: %1", options)

        Builtins.foreach(options) do |key, val|
          variable = key
          value = Convert.to_string(val)
        end
      end

      if variable != ""
        vid = variable2id(variable)

        if vid == nil
          # the variable was not found
          return false
        end

        # set the value
        return setHanlerProcess(variable, value, force)
      end

      false
    end


    # Command line interface - handler for clear command
    # @param [Hash{String => Object}] options command options
    # @return [Boolean] True on success
    def clearHandler(options)
      options = deep_copy(options)
      # set empty value
      Ops.set(options, "value", "")

      # do not check if the value is valid
      Ops.set(options, "force", true)

      # call set handler
      setHandler(options)
    end


    # Command line interface - handler for details command
    # @param [Hash{String => Object}] options details command options
    # @return [Boolean] True on success
    def detailsHandler(options)
      options = deep_copy(options)
      variable = Ops.get_string(options, "variable")
      varid = variable2id(variable)

      return false if varid == nil

      # header (command line mode output)
      CommandLine.Print("\nDescription:\n")
      description = Sysconfig.get_description(varid)

      # display a new value for modified variables
      value = Ops.add(
        Ops.get(description, "new_value") != nil ?
          Ops.add(
            _("New Value: "),
            Ops.get_string(description, "new_value", "")
          ) :
          Ops.add(_("Value: "), Ops.get_string(description, "value", "")),
        "\n"
      )

      # convert description into plain text
      plaintext = Ops.add(value, create_description(description, false))

      CommandLine.Print(plaintext)

      true
    end
    def variable2id(variable)
      if variable != nil
        all_names = Sysconfig.get_all_names
        vids = Ops.get(all_names, variable)

        if vids == nil
          # variable was not found
          # check whether variable name is complete variable identification
          all_vids = Sysconfig.get_all
          Builtins.y2milestone("variable: %2 all_vids: %1", all_vids, variable)

          if Builtins.contains(all_vids, variable)
            return variable
          else
            # command line output
            CommandLine.Print(
              Builtins.sformat(_("Variable %1 was not found."), variable)
            )
          end
        elsif Builtins.size(vids) == 1
          return Ops.get(vids, 0)
        else
          # duplicated variable, print found files
          CommandLine.Print(
            Builtins.sformat(
              "Variable %1 is located in the following files:\n",
              variable
            )
          )

          Builtins.foreach(vids) do |vid|
            fname = Sysconfig.get_file_from_id(vid)
            CommandLine.Print(fname)
          end 


          # variable name conflict - full name (with file name) is required
          CommandLine.Print(
            Builtins.sformat(
              _(
                "\n" +
                  "Use a full variable name in the form <VARIABLE_NAME>$<FILE_NAME>\n" +
                  "(e.g., %1$%2).\n"
              ),
              variable,
              Sysconfig.get_file_from_id(
                Ops.get(vids, 0, "/etc/sysconfig/unknown")
              )
            )
          )
        end
      end

      nil
    end

    # Write handler - disable progress bar (there is no UI) and write settings to the system.
    # @return [Boolean] True on sucess
    def writeHandler
      # disable progress bar
      Progress.off

      # write changes, start activation commands
      Sysconfig.Write
    end
  end
end
