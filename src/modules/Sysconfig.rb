# encoding: utf-8

# File:	modules/Sysconfig.ycp
# Package:	Configuration of sysconfig
# Summary:	Data for configuration of sysconfig, input and output functions.
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# Representation of the configuration of sysconfig.
# Input and output routines.
require "yast"
require "yast2/systemd/service"

module Yast
  class SysconfigClass < Module
    include Yast::Logger

    def main
      Yast.import "UI"
      textdomain "sysconfig"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Directory"
      Yast.import "Label"
      Yast.import "IP"
      Yast.import "String"
      Yast.import "Service"
      Yast.import "Mode"


      @configfiles = [
        "/etc/sysconfig/*",
        "/etc/sysconfig/network/ifcfg-*",
        "/etc/sysconfig/network/dhcp",
        "/etc/sysconfig/network/config",
        Ops.add(Directory.ydatadir, "/descriptions"),
        "/etc/sysconfig/powersave/*",
        "/etc/sysconfig/uml/*"
      ]

      # Additional files from Import
      @custom_files = []

      # modified variables
      @modified_variables = {}

      # comment for non-variable nodes
      @node_comments = {}

      # location for each variable
      @variable_locations = {}

      @parse_param = {
        "separator"         => ",",
        "unique"            => true,
        "remove_whitespace" => true
      }

      @write_only = false

      @tree_content = []

      # map of actions to start when variable is modified
      @actions = {}

      @ConfirmActions = false

      @config_modified = false
    end

    def inspect
      "<#{self} @configfiles=#{@configfiles} >"
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Ops.greater_than(Builtins.size(@modified_variables), 0) || @config_modified
    end

    def SetModified
      @config_modified = true

      nil
    end

    # Get variable name from variable identification or empty string if input is invalid
    # @param [String] id Variable identification
    # @return [String] Variable name
    # @example get_name_from_id("var$file") -> "var"
    def get_name_from_id(id)
      return "" if id == nil

      pos = Builtins.findfirstof(id, "$")

      if pos != nil && Ops.greater_or_equal(pos, 0)
        return Builtins.substring(id, 0, Builtins.findfirstof(id, "$"))
      else
        return ""
      end
    end


    # Get file name where is variable located from variable identification
    # @param [String] id Variable identification
    # @return [String] File name
    def get_file_from_id(id)
      return "" if id == nil

      pos = Builtins.findfirstof(id, "$")

      if pos != nil && Ops.greater_or_equal(pos, 0)
        return Builtins.substring(id, Ops.add(pos, 1))
      else
        return ""
      end
    end

    # Get comment without metadata
    # @param [String] input Input string
    # @return [String] Comment used as variable description
    def get_only_comment(input)
      return "" if input == nil || input == ""

      lines = Builtins.splitstring(input, "\n")

      ret = ""

      Builtins.foreach(lines) do |line|
        com_line = Builtins.regexpsub(line, "^#([^#].*)", "\\1")
        if com_line == nil
          # add empty lines
          if Builtins.regexpmatch(line, "^#[ \t]*$") == true
            ret = Ops.add(ret, "\n")
          end
        else
          ret = Ops.add(Ops.add(ret, com_line), "\n")
        end
      end


      ret
    end

    # Search in syscnfig files for value
    # @param [Hash] params search parameters
    # @param [Boolean] show_progress if true progress bar will be displayed
    # @return [Array<String>] List of found variables (IDs)
    def Search(params, show_progress)
      params = deep_copy(params)
      found = []

      # get all configuration files
      files = SCR.Dir(path(".syseditor.section"))

      if show_progress == true
        # Translation: Progress bar label
        UI.OpenDialog(
          ProgressBar(Id(:progress), _("Searching..."), Builtins.size(files), 0)
        )
      end

      search_varname = Ops.get_boolean(params, "varname", true)
      search_description = Ops.get_boolean(params, "description", false)
      search_value = Ops.get_boolean(params, "value", false)
      case_insensitive = Ops.get_boolean(params, "insensitive", false)
      search_string = Ops.get_string(params, "search", "")

      if search_string == ""
        UI.CloseDialog
        return deep_copy(found)
      end

      if case_insensitive == true
        search_string = Builtins.tolower(search_string)
      end

      index = 0

      Builtins.foreach(files) do |file|
        # skip backup files
        if Builtins.regexpmatch(file, "\\.bak$") ||
            Builtins.regexpmatch(file, "~$")
          Builtins.y2milestone("Ignoring backup file %1", file)
          next
        end
        # get all variables in file
        var_path = Builtins.add(path(".syseditor.value"), file)
        variables = SCR.Dir(var_path)
        Builtins.y2debug("Searching in file %1", file)
        Builtins.foreach(variables) do |var|
          already_found = false
          Builtins.y2debug("Searching in variable %1", var)
          if search_varname == true
            var2 = var
            var2 = Builtins.tolower(var) if case_insensitive

            if Builtins.issubstring(var2, search_string)
              found = Builtins.add(found, Ops.add(Ops.add(var, "$"), file))
              already_found = true
            end
          end
          # search in variable value if it is requested and previous check was unsuccessful
          if search_value == true && already_found == false
            read_value = Convert.to_string(
              SCR.Read(
                Builtins.add(Builtins.add(path(".syseditor.value"), file), var)
              )
            )

            read_value = Builtins.tolower(read_value) if case_insensitive

            if Builtins.issubstring(read_value, search_string)
              found = Builtins.add(found, Ops.add(Ops.add(var, "$"), file))
              already_found = true
            end
          end
          if search_description == true && already_found == false
            # read comment without metadata
            read_comment = get_only_comment(
              Convert.to_string(
                SCR.Read(
                  Builtins.add(
                    Builtins.add(path(".syseditor.value_comment"), file),
                    var
                  )
                )
              )
            )

            read_comment = Builtins.tolower(read_comment) if case_insensitive

            if Builtins.issubstring(read_comment, search_string)
              found = Builtins.add(found, Ops.add(Ops.add(var, "$"), file))
            end
          end
        end
        if show_progress == true
          index = Ops.add(index, 1)
          UI.ChangeWidget(Id(:progress), :Value, index)
        end
      end


      UI.CloseDialog if show_progress == true

      Builtins.y2debug("Found: %1", found)

      deep_copy(found)
    end

    # Remove white spaces at beginning or at the end of string
    # @param [String] input Input string
    # @return [String] String without white spaces
    def remove_whitespaces(input)
      return nil if input == nil

      removed_whitespaces = Builtins.regexpsub(
        input,
        "^[ \t]*(([^ \t]*[ \t]*[^ \t]+)*)[ \t]*$",
        "\\1"
      )

      removed_whitespaces != nil ? removed_whitespaces : input
    end

    # Get metadata lines from input string
    # @param [String] input Input string
    # @return [Array<String>] Metadata lines in list
    def get_metadata(input)
      return [] if input == nil || input == ""

      lines = Builtins.splitstring(input, "\n")
      Builtins.filter(lines) { |line| Builtins.regexpmatch(line, "^##.*") }
    end

    # Parse metadata from comment
    # @param [String] comment Input comment
    # @return [Hash] parsed metadata
    def parse_metadata(comment)
      ret = {}

      # get metadata part of comment
      metalines = get_metadata(comment)
      joined_multilines = []
      multiline = ""

      Builtins.y2debug("metadata: %1", metalines)

      # join multi line metadata lines
      Builtins.foreach(metalines) do |metaline|
        if Builtins.substring(
            metaline,
            Ops.subtract(Builtins.size(metaline), 1),
            1
          ) != "\\"
          if multiline != ""
            # this not first multiline so remove comment mark
            without_comment = Builtins.regexpsub(metaline, "^##(.*)", "\\1")

            metaline = without_comment if without_comment != nil
          end
          joined_multilines = Builtins.add(
            joined_multilines,
            Ops.add(multiline, metaline)
          )
          multiline = ""
        else
          part = Builtins.substring(
            metaline,
            0,
            Ops.subtract(Builtins.size(metaline), 1)
          )

          if multiline != ""
            # this not first multiline so remove comment mark
            without_comment = Builtins.regexpsub(part, "^##(.*)", "\\1")

            part = without_comment if without_comment != nil
          end

          # add line to the previous lines
          multiline = Ops.add(multiline, part)
        end
      end


      Builtins.y2debug(
        "metadata after multiline joining: %1",
        joined_multilines
      )

      # parse each metadata line
      Builtins.foreach(joined_multilines) do |metaline|
        # Ignore lines with ### -- general comments
        next if Builtins.regexpmatch(metaline, "^###")
        meta = Builtins.regexpsub(metaline, "^##[ \t]*(.*)", "\\1")
        # split sting to the tag and value part
        colon_pos = Builtins.findfirstof(meta, ":")
        tag = ""
        val = ""
        if colon_pos == nil
          # colon is missing
          tag = meta
        else
          tag = Builtins.substring(meta, 0, colon_pos)

          if Ops.greater_than(Builtins.size(meta), Ops.add(colon_pos, 1))
            val = Builtins.substring(meta, Ops.add(colon_pos, 1))
          end
        end
        # remove whitespaces from parts
        tag = remove_whitespaces(tag)
        val = remove_whitespaces(val)
        Builtins.y2milestone("tag: %1 val: '%2'", tag, val)
        # add tag and value to map if they are present in comment
        if tag != ""
          ret = Builtins.add(ret, tag, val)
        else
          # ignore separator lines
          if !Builtins.regexpmatch(metaline, "^#*$")
            Builtins.y2warning("Unknown metadata line: %1", metaline)
          end
        end
      end


      deep_copy(ret)
    end


    # Get variable location in tree widget from variable identification
    # @param [String] id Variable identification
    # @return [String] Variable location
    def get_location_from_id(id)
      Ops.get(@variable_locations, id, "")
    end

    # Get description of selected variable
    # @param [String] varid Variable identification
    # @return [Hash] Description map
    def get_description(varid)
      varname = get_name_from_id(varid)
      fname = get_file_from_id(varid)

      comment_path = Builtins.add(
        Builtins.add(path(".syseditor.value_comment"), fname),
        varname
      )
      value_path = Builtins.add(
        Builtins.add(path(".syseditor.value"), fname),
        varname
      )
      comment = Convert.to_string(SCR.Read(comment_path))
      all_variables = SCR.Dir(Builtins.add(path(".syseditor.value"), fname))
      used_comment = varname

      # no comment present
      if comment != nil && Builtins.size(comment) == 0 &&
          !Builtins.regexpmatch(fname, "^/etc/sysconfig/network/ifcfg-.*")
        Builtins.y2warning("Comment for variable %1 is missing", varid)

        reversed = []

        i = 0
        found = false

        while Ops.less_than(i, Builtins.size(all_variables)) && found == false
          v = Ops.get(all_variables, i, "")

          if v == varname
            found = true
          else
            reversed = Builtins.prepend(reversed, v)
          end

          i = Ops.add(i, 1)
        end

        if found == true
          i = 0
          comment = ""
          v = ""

          Builtins.y2debug("reversed: %1", reversed)
          while Ops.less_than(i, Builtins.size(reversed)) && comment == ""
            v = Ops.get(reversed, i, "")
            used_comment = v
            comment = Convert.to_string(
              SCR.Read(
                Builtins.add(
                  Builtins.add(path(".syseditor.value_comment"), fname),
                  v
                )
              )
            )

            i = Ops.add(i, 1)
          end

          Builtins.y2warning(
            "Variable: %1 Using comment from variable: %2",
            varname,
            v
          )
        end
      end

      # remove config file header at the beginning of the file
      # header is comment from beginning of the file to the empty line
      if used_comment == Ops.get(all_variables, 0, "") && comment != nil
        Builtins.y2debug("Reading first variable from the file")
        # comment is read from the first variable
        # remove header if it's present
        Builtins.y2debug("Whole comment: %1", comment)
        lines = Builtins.splitstring(comment, "\n")
        filtered = []

        # remove last empty string from list (caused by last new line char)
        if Ops.get(lines, Ops.subtract(Builtins.size(lines), 1)) == ""
          lines = Builtins.remove(lines, Ops.subtract(Builtins.size(lines), 1))
        end

        if Builtins.contains(lines, "") == true
          Builtins.y2milestone("Header comment detected")
          adding = false

          # filter out variables before empty line
          filtered = Builtins.filter(lines) do |line|
            if line == ""
              adding = true
            elsif adding == true
              next true
            end
            false
          end

          # merge strings
          comment = Builtins.mergestring(filtered, "\n")
        end
      end

      meta = parse_metadata(comment)

      template_only_comment = ""

      # for network configuration file read comments from configuration template
      if Builtins.regexpmatch(fname, "^/etc/sysconfig/network/ifcfg-.*")
        template_comment = Convert.to_string(
          SCR.Read(
            Builtins.add(
              Builtins.add(path(".sysconfig.network.template"), "value_comment"),
              varname
            )
          )
        )
        template_meta = parse_metadata(template_comment)

        if Ops.greater_than(Builtins.size(template_meta), 0)
          # add missing metadata values from template
          Builtins.foreach(template_meta) do |key, value|
            Ops.set(meta, key, value) if !Builtins.haskey(meta, key)
          end
        end

        template_only_comment = get_only_comment(template_comment)

        if Ops.greater_than(Builtins.size(template_only_comment), 0)
          template_only_comment = Ops.add(template_only_comment, "\n")
        end

        Builtins.y2milestone(
          "Comment read from template: %1",
          template_only_comment
        )
        Builtins.y2milestone("Meta read from template: %1", template_meta)
      end

      deflt = Ops.get_string(meta, "Default")

      if deflt != nil
        parsed = String.ParseOptions(deflt, @parse_param)
        Ops.set(meta, "Default", Ops.get_string(parsed, 0, ""))

        Builtins.y2debug(
          "Read default value: %1",
          Ops.get_string(parsed, 0, "")
        )
      end

      new_value = Ops.get(@modified_variables, varid)

      # check if value was changed
      Ops.set(meta, "new_value", new_value) if new_value != nil

      Ops.set(meta, "name", varname)
      Ops.set(meta, "file", get_file_from_id(varid))
      Ops.set(
        meta,
        "location",
        varname != "" ? get_location_from_id(varid) : varid
      )
      Ops.set(
        meta,
        "comment",
        varname != "" ?
          Ops.add(template_only_comment, get_only_comment(comment)) :
          Ops.get_string(@node_comments, varid, "")
      )
      Ops.set(meta, "value", SCR.Read(value_path))

      # add action commands
      if Ops.greater_than(Builtins.size(Ops.get_map(@actions, varid, {})), 0)
        Ops.set(meta, "actions", Ops.get_map(@actions, varid, {}))
      end

      deep_copy(meta)
    end

    # Set new variable value
    # @param [String] variable Variable identification
    # @param [String] new_value New value
    # @param [Boolean] force If true - do not check if new value is valid
    # @param [Boolean] force_change Force value as changed even if it is equal to old value
    # @return [Symbol] Result: `not_found (specified variable was not found in config file),
    #   `not_valid (new  value is not valid - doesn't match variable type definition),
    #   `ok (success)
    def set_value(variable, new_value, force, force_change)
      desc = get_description(variable)
      name = get_name_from_id(variable)

      return :not_found if name == ""

      modif = Ops.get(@modified_variables, variable)
      old = Ops.get_string(desc, "value", "")

      # use default value (or emty string) instead of the curent value in autoyast
      if Mode.config
        old = Builtins.haskey(desc, "Default") ?
          Ops.get_string(desc, "Default", "") :
          ""
      end


      curr_val = modif != nil ? modif : old

      if force_change || new_value != curr_val
        Builtins.y2milestone(
          "variable: %1 changed from: %2 to: %3",
          variable,
          curr_val,
          new_value
        )

        if new_value == old && !force_change
          # variable was reset to the original value, remove it from map of modified
          Builtins.y2debug(
            "Variable %1 was reset to the original value",
            variable
          )
          @modified_variables = Builtins.remove(@modified_variables, variable)
        else
          valid = false

          if force == false
            # check data type
            type = Ops.get_string(desc, "Type", "string")

            if type == "string" ||
                Builtins.regexpmatch(type, "^string\\(.*\\)$") == true
              # string type is valid always
              valid = true
            elsif type == "yesno"
              valid = new_value == "yes" || new_value == "no"
            elsif type == "boolean"
              valid = new_value == "true" || new_value == "false"
            elsif type == "integer"
              valid = Builtins.regexpmatch(new_value, "^-{0,1}[0-9]*$")
            elsif Builtins.regexpmatch(type, "^list\\(.*\\)$")
              listopt = Builtins.regexpsub(type, "^list\\((.*)\\)$", "\\1")
              parsed_opts = String.ParseOptions(listopt, @parse_param)

              valid = Builtins.contains(parsed_opts, new_value)
            elsif Builtins.regexpmatch(
                type,
                "^integer\\(-{0,1}[0-9]*:-{0,1}[0-9]*\\)$"
              )
              # check if input is integer
              valid = Builtins.regexpmatch(new_value, "^-{0,1}[0-9]*$")

              if valid == true
                # it is integer, check range
                min = Builtins.regexpsub(
                  type,
                  "^integer\\((-{0,1}[0-9]*):-{0,1}[0-9]*\\)$",
                  "\\1"
                )
                max = Builtins.regexpsub(
                  type,
                  "^integer\\(-{0,1}[0-9]*:(-{0,1}[0-9]*)\\)$",
                  "\\1"
                )

                Builtins.y2milestone("min: %1  max: %2", min, max)

                min_int = Builtins.tointeger(min)
                max_int = Builtins.tointeger(max)
                new_int = Builtins.tointeger(new_value)

                Builtins.y2milestone(
                  "min_int: %1  max_int: %2",
                  min_int,
                  max_int
                )

                if max != "" && min != ""
                  valid = Ops.greater_or_equal(new_int, min_int) &&
                    Ops.less_or_equal(new_int, max_int)
                elsif max == ""
                  valid = Ops.greater_or_equal(new_int, min_int)
                elsif min == ""
                  valid = Ops.less_or_equal(new_int, max_int)
                else
                  # empty range, valid is set to true
                  Builtins.y2warning(
                    "empty integer range, assuming any integer"
                  )
                end
              end
            elsif Builtins.regexpmatch(type, "^regexp\\(.*\\)$")
              regex = Builtins.regexpsub(type, "^regexp\\((.*)\\)$", "\\1")
              valid = Builtins.regexpmatch(new_value, regex)
            elsif type == "ip"
              # check IP adress using function from network/ip.ycp include
              valid = IP.Check(new_value)
            elsif type == "ip4"
              # check IP adress using function from network/ip.ycp include
              valid = IP.Check4(new_value)
            elsif type == "ip6"
              # check IP adress using function from network/ip.ycp include
              valid = IP.Check6(new_value)
            else
              Builtins.y2warning(
                "Unknown data type %1 for variable %2",
                type,
                name
              )
            end
          end

          if valid == false && force == false
            return :not_valid
          else
            Ops.set(@modified_variables, variable, new_value)
            return :ok
          end
        end
      end

      # value was not changed => OK
      :ok
    end

    # Return modification status of variable
    # @param [String] varid Variable identification
    # @return [Boolean] True if variable was modified
    def modified(varid)
      Builtins.haskey(@modified_variables, varid)
    end

    # Get list of modified variables
    # @return [Array] List of modified variables
    def get_modified
      ret = []

      Builtins.foreach(@modified_variables) do |varid, new_value|
        ret = Builtins.add(ret, varid)
      end


      deep_copy(ret)
    end

    # Get list of all variables
    # @return [Array] List of variable identifications
    def get_all
      ret = []

      Builtins.foreach(@variable_locations) do |varid, new_value|
        ret = Builtins.add(ret, varid)
      end


      deep_copy(ret)
    end

    # Get map of all variables
    # @return [Hash] Map of variable names, key is variable name, value is a list of variable identifications
    def get_all_names
      ret = {}

      Builtins.foreach(@variable_locations) do |varid, new_value|
        name = get_name_from_id(varid)
        if Builtins.haskey(ret, name) == true
          ret = Builtins.add(
            ret,
            name,
            Builtins.add(Ops.get(ret, name, []), varid)
          )
        else
          ret = Builtins.add(ret, name, [varid])
        end
      end


      deep_copy(ret)
    end

    # Register .syseditor path (use INI agent in multiple file mode)
    def RegisterAgents
      files = deep_copy(@configfiles)
      tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))

      if tmpdir == nil || tmpdir == ""
        Builtins.y2security("Using /tmp directory !")
        tmpdir = "/tmp"
      end

      # register configuration files in SCR using INI-agent
      agentdef = Ops.add(
        Builtins.sformat(".syseditor\n\n`ag_ini(`IniAgent( %1,\n", files),
        Convert.to_string(
          SCR.Read(
            path(".target.string"),
            Ops.add(Directory.ydatadir, "/sysedit.agent")
          )
        )
      )
      tmp = Ops.add(tmpdir, "/sysconfig-agent.scr")

      SCR.Write(path(".target.string"), tmp, agentdef)
      SCR.RegisterAgent(path(".syseditor"), tmp)

      nil
    end

    # Read all sysconfig variables
    # @return true on success
    def Read
      # TODO: solve custom_files parameter problem (used in Import)
      # read only powerteak config or all sysconfig files
      files = deep_copy(@configfiles)

      tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))
      if tmpdir == nil || tmpdir == ""
        Builtins.y2security("Using /tmp directory !")
        tmpdir = "/tmp"
      end

      # register .syseditor path
      RegisterAgents()

      # register agent for reading network template
      agentdef = Ops.add(
        Builtins.sformat(
          ".sysconfig.network.template,\n" +
            "\n" +
            "`ag_ini(`IniAgent(\"/etc/sysconfig/network/ifcfg.template\"\n" +
            ","
        ),
        Convert.to_string(
          SCR.Read(
            path(".target.string"),
            Ops.add(Directory.ydatadir, "/sysedit.agent")
          )
        )
      )
      tmp = Ops.add(tmpdir, "/sysconfig-template-agent.scr")

      SCR.Write(path(".target.string"), tmp, agentdef)
      SCR.RegisterAgent(path(".sysconfig.network.template"), tmp)


      # list of all config files
      Builtins.y2milestone(
        "Registered config files: %1",
        SCR.Dir(path(".syseditor.section"))
      )

      # create script options
      param = ""
      Builtins.foreach(files) do |par|
        param = Ops.add(Ops.add(Ops.add(param, "'"), par), "' ")
      end

      # create tree definition list and description map using external Perl script
      SCR.Execute(
        path(".target.bash"),
        "#{Directory.bindir}/parse_configs.pl #{param} > #{tmpdir}/treedef.ycp"
      )

      # read list
      parsed_output = Convert.to_list(
        SCR.Read(path(".target.ycp"), Ops.add(tmpdir, "/treedef.ycp"))
      )
      @tree_content = Ops.get_list(parsed_output, 0, [])

      @node_comments = Ops.get_map(parsed_output, 1, {})

      @variable_locations = Ops.get_map(parsed_output, 2, {})

      # redefined variables (variables which are defined in more files)
      redefined_vars = Ops.get_map(parsed_output, 3, {})
      if Ops.greater_than(Builtins.size(redefined_vars), 0)
        Builtins.y2warning("Redefined variables: %1", redefined_vars)
      end

      # read map with activation commands
      @actions = Ops.get_map(parsed_output, 4, {})

      true
    end

    # Display confirmation dialog
    # @param [String] message Confirmation message. It can include newlines
    # @return [Symbol] `cont - start command, `skip - skip this command, `abort - skip all remaining commands
    def ConfirmationDialog(message)
      msg_lines = message.lines.map {|l| Label(l) }

      UI.OpenDialog(
        Opt(:decorated),
        VBox(
          *msg_lines,
          VSpacing(0.5),
          HBox(
            PushButton(Id(:cont), Label.ContinueButton),
            # button label
            PushButton(Id(:skip), _("S&kip")),
            PushButton(Id(:abort), Label.AbortButton)
          )
        )
      )

      ret = nil

      while ![:cont, :skip, :abort].include?(ret)
        ret = UI.UserInput

        ret = :abort if ret == :close
      end

      UI.CloseDialog

      ret
    end

    # Write all sysconfig settings
    # @return [Boolean] true on success
    def Write
      return false unless exec_pre_actions

      # remember all actions - start each action only once
      post_actions = calculate_post_actions

      # write dialog caption
      caption = _("Saving sysconfig Configuration")

      # set the right number of stages
      steps = @modified_variables.size +
        post_actions.values.flatten.size +
        4 # 1 for flushing the cache plus 3 stages

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # progress bar item
          _("Write the new settings"),
          _("Activate the changes")
        ],
        nil,
        ""
      )

      Progress.NextStage

      ret = save_modified_variables

      Progress.Title(_("Saving changes to the files..."))
      # flush changes
      SCR.Write(path(".syseditor"), nil)
      Progress.NextStep

      # now start required activation commands
      Progress.NextStage

      # reload required services
      post_actions[:reload].each do |servicename|
        Progress.NextStep
        next unless service_active?(servicename)
        return false if exec_service_action(servicename, :reload) == :abort
      end

      # restart required services
      post_actions[:restart].each do |servicename|
        Progress.NextStep
        next unless service_active?(servicename)
        return false if exec_service_action(servicename, :restart) == :abort
      end

      # start generic commands
      post_actions[:cmd].each do |cmd|
        Progress.NextStep
        next if cmd.nil? || cmd.size == 0
        return false if exec_cmd_action(cmd) == :abort
      end

      Progress.NextStep

      Progress.Title(_("Finished"))

      # set "finished" mark for the last stage
      Progress.Finish

      ret
    end

    # Set all sysconfig settings from the list
    # (For use by autoinstallation.)
    # @param [Array<Hash>] settings The YCP structure to be set.
    def Set(settings)
      settings = deep_copy(settings)
      if settings != nil
        @modified_variables = {}
        @custom_files = deep_copy(@configfiles)

        # convert from 8.1 export format
        Builtins.foreach(settings) do |setting|
          n = Ops.get_string(setting, "sysconfig_key", "")
          f = Ops.get_string(setting, "sysconfig_path", "")
          v = Ops.get_string(setting, "sysconfig_value", "")
          # compatibility mode for older release with relative path
          if Builtins.findfirstof(f, "/") != 0
            f = Builtins.sformat("/etc/sysconfig/%1", f)
          end
          key = Builtins.sformat("%1$%2", n, f)
          @modified_variables = Builtins.add(@modified_variables, key, v)
          # add configuration file if it isn't already specified
          if !Builtins.contains(@custom_files, f)
            @custom_files = Builtins.add(@custom_files, f)
          end
        end
      end

      nil
    end

    # Set all sysconfig settings from the list and read information from files
    # (For use by autoinstallation.)
    # @param [Array] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      settings_maps = Convert.convert(
        settings,
        :from => "list",
        :to   => "list <map>"
      )
      # set values in the list
      Set(settings_maps)

      # register agent for user defined files, read values
      true
    end

    # Dump the sysconfig settings to a single map
    # (For use by autoinstallation.)
    # @return [Array] Dumped settings (later acceptable by Import ())
    def Export
      # return structured map (for 8.1 compatibility)

      ret = []

      if Ops.greater_than(Builtins.size(@modified_variables), 0)
        Builtins.foreach(@modified_variables) do |varid, val|
          n = get_name_from_id(varid)
          f = get_file_from_id(varid)
          m = {
            "sysconfig_key"   => n,
            "sysconfig_path"  => f,
            "sysconfig_value" => val
          }
          ret = Builtins.add(ret, m)
        end
      end
      deep_copy(ret)
    end

    # Create a textual summary
    # @return summary of the current configuration
    def Summary
      # configuration summary headline
      summary = Summary.AddHeader("", _("Configuration Summary"))

      Builtins.y2milestone("Summary: %1", @modified_variables)

      if Ops.greater_than(Builtins.size(@modified_variables), 0)
        Builtins.foreach(@modified_variables) do |varid, newval|
          varnam = get_name_from_id(varid)
          filename = get_file_from_id(varid)
          summary = Summary.AddLine(
            summary,
            Builtins.sformat("%1=\"%2\" (%3)", varnam, newval, filename)
          )
        end
      else
        summary = Summary.AddLine(summary, Summary.NotConfigured)
      end

      summary
    end

    publish :variable => :configfiles, :type => "list <string>"
    publish :variable => :parse_param, :type => "map"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :tree_content, :type => "list <list>"
    publish :variable => :ConfirmActions, :type => "boolean"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :SetModified, :type => "void ()"
    publish :function => :get_name_from_id, :type => "string (string)"
    publish :function => :get_file_from_id, :type => "string (string)"
    publish :function => :get_only_comment, :type => "string (string)"
    publish :function => :Search, :type => "list <string> (map, boolean)"
    publish :function => :remove_whitespaces, :type => "string (string)"
    publish :function => :get_metadata, :type => "list <string> (string)"
    publish :function => :parse_metadata, :type => "map <string, string> (string)"
    publish :function => :get_location_from_id, :type => "string (string)"
    publish :function => :get_description, :type => "map <string, any> (string)"
    publish :function => :set_value, :type => "symbol (string, string, boolean, boolean)"
    publish :function => :modified, :type => "boolean (string)"
    publish :function => :get_modified, :type => "list <string> ()"
    publish :function => :get_all, :type => "list <string> ()"
    publish :function => :get_all_names, :type => "map <string, list <string>> ()"
    publish :function => :RegisterAgents, :type => "void ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Set, :type => "void (list <map>)"
    publish :function => :Import, :type => "boolean (list)"
    publish :function => :Export, :type => "list ()"
    publish :function => :Summary, :type => "string ()"

    private

    # Executes some code asking first for user confirmation if required.
    # Displays specified error message when an error is detected.
    # @param action [Proc] Code to execute, it must return false in case of failure
    # @param label [String] Progress bar label
    # @param error_msg [String] Error message displayed when execution fails
    # @param confirm_msg [String] Confirmation message, can contain newline characters
    # @return [Symbol] :success - code was executed, :failed - execution failed (false returned),
    #   :skip - command was skipped, :abort - command starting was aborted
    def exec_action(action, label, error_msg, confirm_msg)
      return :success unless action

      # set progress bar label
      Progress.Title(label)

      if @ConfirmActions
        # show confirmation dialog
        input = ConfirmationDialog(confirm_msg)
        return input if input != :cont
      end

      if action.call
        :success
      else
        Report.Error(error_msg)
        :failed
      end
    end

    # Executes a bash command using #exec_action
    # @see #exec_action
    # @param cmd [String] command to execute
    # @return [Symbol] result returned by #exec_action
    def exec_cmd_action(cmd)
      label = Builtins.sformat(_("Starting command: %1..."), cmd)
      error = Builtins.sformat(_("Command %1 failed"), cmd)
      confirm = _("A command will be executed") + "\n" + _("Command: ") + cmd

      # Any command executed here is taken verbatim from a file in
      # /etc/sysconfig. The command should contain an absolute path, and if it
      # has any arguments, they should be properly quoted.
      #
      # There does not seem to be a single example where such a command has any
      # arguments, though.
      #
      # Example specification from /etc/sysconfig/fonts-config:
      #
      #   ## Command:     /usr/sbin/fonts-config
      #
      # Specification:
      #  https://github.com/yast/yast-sysconfig/blob/master/doc/metadata.txt#L141-L159

      action = lambda do
        log.warn("No absolute path in command #{cmd}") unless cmd.lstrip.start_with?("/")

        log.info "Starting: #{cmd}"
        cmd_out = SCR.Execute(path(".target.bash_output"), "#{cmd} 2>&1")
        log.info "Result: #{cmd_out['exit']}"
        log.info "Output: #{cmd_out['stdout']}"

        cmd_out["exit"] == 0
      end

      exec_action(action, label, error, confirm)
    end

    # Restarts or reloads a service using #exec_action
    # @see #exec_action
    # @param name [String] service name
    # @param action [Symbol] :reload or :restart
    # @return [Symbol] result returned by #exec_action
    def exec_service_action(name, type = :reload)
      case type
      when :reload
        label = _("Reloading service %s...") % name
        error = _("Reload of the service %s failed") % name
        confirm = _("Service %s will be reloaded") % name
      when :restart
        label = _("Restarting service %s...") % name
        error = _("Restart of the service %s failed") % name
        confirm = _("Service %s will be restarted") % name
      else
        raise "Wrong action type #{type}"
      end

      action = lambda do
        log.info "Service #{name} will be restarted (#{type})"
        service = Yast2::Systemd::Service.find(name)
        return false unless service
        service.send(type)
      end

      exec_action(action, label, error, confirm)
    end

    # Returns whether given service is active (info from systemd)
    # If service is not found, reports error in UI and returns nil
    #
    # @param service name
    # @return [Boolean] active?
    def service_active?(service_name)
      service_unit = Yast2::Systemd::Service.find(service_name)

      unless service_unit
        Report.Error(
          _("Cannot determine service state, systemd service does not exist:") +
            "\n#{service_name}"
        )

        return nil
      end

      service_unit.active?
    end

    # Executes actions that are required before saving the variables
    #
    # @return [Boolean] false if the user aborts, true otherwise
    def exec_pre_actions
      # start pre_save commands
      @modified_variables.each_pair do |vid, new_val|
        # get activation map for variable
        cmd = Ops.get_string(@actions, [vid, "Pre"])
        if cmd && !cmd.empty?
          result = exec_cmd_action(cmd)

          return false if result == :abort
        end
      end

      true
    end

    # Calculates the services to restart, the services to reload and the
    # commands to execute after saving the variables
    #
    # @return [Hash] Hash with three keys (:restart, :reload, :cmd) and arrays
    #   of strings as values
    def calculate_post_actions
      restart_services = []
      reload_services = []
      services_commands = []

      @modified_variables.each_key do |variable_id|
        # get activation map for variable
        activate = @actions.fetch(variable_id, {})

        restart_service = activate["Rest"]
        reload_service = activate["Reld"]
        bash_command = activate["Cmd"]

        if restart_service && !restart_service.empty?
          parsed = String.ParseOptions(restart_service, @parse_param)
          parsed.each { |s| restart_services << s }
        end

        if reload_service && !reload_service.empty?
          parsed = String.ParseOptions(reload_service, @parse_param)
          parsed.each { |s| reload_services << s }
        end

        if bash_command && !bash_command.empty?
          services_commands << bash_command
        end
      end

      {
        restart: restart_services.uniq,
        reload: reload_services.uniq,
        cmd: services_commands.uniq
      }
    end

    # Writes the modified variables into the corresponding files
    #
    # @return [Boolean] true if all the variables were correctly written
    def save_modified_variables
      ret = true

      # save each changed variable
      @modified_variables.each do |value_id, new_val|
        file = get_file_from_id(value_id)
        name = get_name_from_id(value_id)
        # progress bar label, %1 is variable name (e.g. DISPLAYMANAGER)
        Progress.Title(Builtins.sformat(_("Saving variable %1..."), name))
        value_path = path(".syseditor.value") + file + name

        unless SCR.Write(value_path, new_val)
          # error popup: %1 - variable name (e.g. DISPLAYMANAGER), %2 - file name (/etc/sysconfig/displaymanager)
          Report.Error(
            Builtins.sformat(
              _("Saving variable %1 to the file %2 failed."),
              name,
              file
            )
          )
          ret = false
        end

        Progress.NextStep
      end

      ret
    end

  end

  Sysconfig = SysconfigClass.new
  Sysconfig.main
end
