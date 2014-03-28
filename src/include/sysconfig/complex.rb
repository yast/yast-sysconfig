# encoding: utf-8

# File:	include/sysconfig/complex.ycp
# Package:	Configuration of sysconfig
# Summary:	Dialogs definitions
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
module Yast
  module SysconfigComplexInclude
    def initialize_sysconfig_complex(include_target)
      Yast.import "UI"

      textdomain "sysconfig"

      Yast.import "Wizard"
      Yast.import "Sysconfig"
      Yast.import "Mode"
      Yast.import "String"

      Yast.import "Popup"
      Yast.import "Label"

      Yast.include include_target, "sysconfig/helps.rb"
      Yast.include include_target, "sysconfig/routines.rb"
      Yast.include include_target, "sysconfig/dialogs.rb"

      # current selected variable in the tree widget
      @selected_variable = ""
      @empty_string = "                                             "
      @empty_string = Ops.add(@empty_string, @empty_string)
      @empty_string = Ops.add(@empty_string, @empty_string)
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      Sysconfig.Modified
    end


    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.SetHelpText(Ops.get_string(@HELPS, "read", ""))

      Sysconfig.Read

      :next
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.SetHelpText(Ops.get_string(@HELPS, "write", ""))

      ret = true

      if Sysconfig.Modified == true
        Builtins.y2milestone("Changes will be written.")
        # write and activate changes
        if Sysconfig.Write == false
          # error popup message
          Popup.Error(
            _("An error occurred while saving and activating the changes.")
          )
        else
          Builtins.sleep(500) # small delay, user should see 100% progress
        end 
        #Popup::Message(_("The changes were saved and successfully activated."));
      end

      :next
    end

    # Get string representation of type definition. Used at richtext description.
    # @param [Hash] description Variable description
    # @param [Boolean] richtext result is rich/plain text
    # @return [String] Textual description of the type
    def possible_values(description, richtext)
      description = deep_copy(description)
      ret = ""

      type = Ops.get_string(description, "Type", "")

      if type == ""
        return ret
      elsif type == "yesno"
        ret = Ops.add(ret, "yes,no")
      elsif type == "boolean"
        ret = "true,false"
      elsif Builtins.regexpmatch(type, "^list\\(.*\\)")
        spaces = []
        values = String.ParseOptions(
          Builtins.regexpsub(type, "^list\\((.*)\\)", "\\1"),
          Sysconfig.parse_param
        )

        Builtins.foreach(values) do |value|
          spaces = Builtins.add(
            spaces,
            Builtins.mergestring(Builtins.splitstring(value, " "), "&nbsp;")
          )
        end 


        ret = Builtins.mergestring(spaces, ", ")
      elsif Builtins.regexpmatch(type, "^string\\(.*\\)")
        spaces = []
        values = String.ParseOptions(
          Builtins.regexpsub(type, "^string\\((.*)\\)", "\\1"),
          Sysconfig.parse_param
        )

        Builtins.foreach(values) do |value|
          spaces = Builtins.add(
            spaces,
            Builtins.mergestring(Builtins.splitstring(value, " "), "&nbsp;")
          )
        end 


        # suffix added to the allowed (predefined) values
        ret = Ops.add(
          Ops.add(
            Ops.add(Builtins.mergestring(spaces, ", "), richtext ? " <I>" : " "),
            _("or any value")
          ),
          richtext ? "</I>" : ""
        )
      elsif Builtins.regexpmatch(type, "^regexp\\(.*\\)")
        regex = Builtins.regexpsub(type, "^regexp\\((.*)\\)", "\\1")
        # Translation: description of possible values, regular expression string is added after the text
        ret = Ops.add(
          (richtext ? "<I>" : "") + _("Value Matching Regular Expression:") +
            (richtext ? "</I>" : ""),
          regex
        )
      elsif type == "integer"
        # allowed value description
        ret = (richtext ? "<I>" : "") + _("Any integer value") +
          (richtext ? "</I>" : "")
      elsif Builtins.regexpmatch(type, "^integer\\(.*:.*\\)")
        min = Builtins.regexpsub(type, "^integer\\((.*):.*\\)", "\\1")
        max = Builtins.regexpsub(type, "^integer\\(.*:(.*)\\)", "\\1")

        Builtins.y2milestone("min: %1, max: %2", min, max)

        if max == "" && min != ""
          # allowed value description
          ret = Ops.add(
            Ops.add(
              richtext ? "<I>" : "",
              Builtins.sformat(_("Integer value greater or equal to %1"), min)
            ),
            richtext ? "</I>" : ""
          )
        elsif min == "" && max != ""
          # allowed value description
          ret = Ops.add(
            Ops.add(
              richtext ? "<I>" : "",
              Builtins.sformat(_("Integer value less or equal to %1"), max)
            ),
            richtext ? "</I>" : ""
          )
        else
          # Translation: allowed value description, %1 is minimum value, %2 is maximum integer value
          ret = Ops.add(
            Ops.add(
              richtext ? "<I>" : "",
              Builtins.sformat(_("Any integer value from %1 to %2"), min, max)
            ),
            richtext ? "</I>" : ""
          )
        end
      elsif type == "string"
        # allowed value description - any value is allowed
        ret = (richtext ? "<I>" : "") + _("Any value") +
          (richtext ? "</I>" : "")
      elsif type == "ip"
        # allowed value description - IP adress
        ret = (richtext ? "<I>" : "") + _("IPv4 or IPv6 address") +
          (richtext ? "</I>" : "")
      elsif type == "ip4"
        # allowed value description - IPv4 adress
        ret = (richtext ? "<I>" : "") + _("IPv4 address") +
          (richtext ? "</I>" : "")
      elsif type == "ip6"
        # allowed value description - IPv6 adress
        ret = (richtext ? "<I>" : "") + _("IPv6 address") +
          (richtext ? "</I>" : "")
      else
        Builtins.y2warning("Unknown type definition: %1", type)
      end

      ret
    end

    # Create rich text description string from description values
    # @param [Hash{String => Object}] description Description
    # @param [Boolean] richtext if true result is rich text, if false result is plain text
    # @return [String] Rich text string
    def create_description(description, richtext)
      description = deep_copy(description)
      varname = Ops.get_string(description, "name", "")
      file = Ops.get_string(description, "file", "")
      default_value = Ops.get_string(description, "Default")
      comment = Ops.get_string(description, "comment", "")

      possible_vals = possible_values(description, richtext)

      result = ""

      if file != "" && file != nil
        # rich text item
        result = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(Ops.add(result, richtext ? "<P><B>" : ""), _("File: ")),
              richtext ? "</B> " : ""
            ),
            file
          ),
          richtext ? "</P>" : "\n"
        )
      end

      if possible_vals != "" && possible_vals != nil
        # rich text item
        result = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(result, richtext ? "<P><B>" : ""),
                _("Possible Values: ")
              ),
              richtext ? "</B> " : ""
            ),
            possible_vals
          ),
          richtext ? "</P>" : "\n"
        )
      end

      if default_value != nil && Ops.greater_than(Builtins.size(file), 0)
        # TODO: replace empty value by special text (e.g. "</I>empty</I>")

        # rich text value
        result = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(result, richtext ? "<P><B>" : ""),
                _("Default Value: ")
              ),
              richtext ? "</B> " : ""
            ),
            default_value
          ),
          richtext ? "</P>" : "\n"
        )
      end

      # if value was modified add original value
      if Builtins.haskey(description, "new_value")
        original = Ops.get_string(description, "value", "")

        # quote empty value
        original = "\"\"" if original == ""
        # rich text value
        result = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(result, richtext ? "<P><B>" : ""),
                _("Original Value: ")
              ),
              richtext ? "</B> " : ""
            ),
            original
          ),
          richtext ? "</P>" : "\n"
        )
      end

      if Builtins.haskey(description, "actions")
        # display specified action command
        conf_modules = Ops.get_string(description, ["actions", "Cfg"])
        restart = Ops.get_string(description, ["actions", "Rest"])
        reload = Ops.get_string(description, ["actions", "Reld"])
        command = Ops.get_string(description, ["actions", "Cmd"])
        precommand = Ops.get_string(description, ["actions", "Pre"])

        # check whether action is defined
        if precommand != nil && Ops.greater_than(Builtins.size(precommand), 0)
          # header in the variable description text, bash command is appended
          result = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(result, richtext ? "<P><B>" : ""),
                  _("Prepare Command: ")
                ),
                richtext ? "</B> " : ""
              ),
              precommand
            ),
            richtext ? "</P>" : "\n"
          )
        end

        if conf_modules != nil &&
            Ops.greater_than(Builtins.size(conf_modules), 0)
          # parse string with options, then add them to the rich text
          conf = String.ParseOptions(conf_modules, Sysconfig.parse_param)
          # header in the variable description text
          result = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(result, richtext ? "<P><B>" : ""),
                  _("Configuration Script: ")
                ),
                richtext ? "</B> " : ""
              ),
              Builtins.mergestring(conf, ", ")
            ),
            richtext ? "</P>" : "\n"
          )
        end

        if reload != nil && Ops.greater_than(Builtins.size(reload), 0)
          services = String.ParseOptions(reload, Sysconfig.parse_param)
          # header in the variable description text, service names (e.g. "apache") are appended
          result = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(result, richtext ? "<P><B>" : ""),
                  _("Service to Reload: ")
                ),
                richtext ? "</B> " : ""
              ),
              Builtins.mergestring(services, ", ")
            ),
            richtext ? "</P>" : "\n"
          )
        end

        if restart != nil && Ops.greater_than(Builtins.size(restart), 0)
          services = String.ParseOptions(restart, Sysconfig.parse_param)
          # header in the variable description text, service names (e.g. "apache") are appended
          result = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(result, richtext ? "<P><B>" : ""),
                  _("Service to Restart: ")
                ),
                richtext ? "</B> " : ""
              ),
              Builtins.mergestring(services, ", ")
            ),
            richtext ? "</P>" : "\n"
          )
        end

        if command != nil && Ops.greater_than(Builtins.size(command), 0)
          # header in the variable description text, bash command is appended
          result = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(result, richtext ? "<P><B>" : ""),
                  _("Activation Command: ")
                ),
                richtext ? "</B> " : ""
              ),
              command
            ),
            richtext ? "</P>" : "\n"
          )
        end
      end

      if comment != "" && comment != nil
        if richtext
          # convert '<' and '>' to '&lt;' '&gt;'
          comment = Builtins.mergestring(
            Builtins.splitstring(comment, "<"),
            "&lt;"
          )
          comment = Builtins.mergestring(
            Builtins.splitstring(comment, ">"),
            "&gt;"
          )

          # keep comment formatting:
          # convert '\n' => '<BR>'
          comment = Builtins.mergestring(
            Builtins.splitstring(comment, "\n"),
            "<BR>"
          )

          # do not change node descriptions
          if file != ""
            # convert ' ' => '&nbsp;'
            comment = Builtins.mergestring(
              Builtins.splitstring(comment, " "),
              "&nbsp;"
            )
          end

          Builtins.y2debug("formatted comment: %1", comment)
        end

        # rich text value
        result = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(result, richtext ? "<P><B>" : ""),
                _("Description: ")
              ),
              richtext ? "</B><BR> " : ""
            ),
            comment
          ),
          richtext ? "</P>" : ""
        )
      end

      Builtins.y2debug("variable description : %1", result)

      result
    end

    # Get combo box editable status - depends on Type value
    # @param [Hash] description Description of variable
    # @return [Boolean] True if combo box should be editable
    def combo_editable(description)
      description = deep_copy(description)
      type = Ops.get_string(description, "Type", "")

      type == "" || Builtins.regexpmatch(type, "^integer\\(.*:.*\\)$") ||
        type == "integer" ||
        type == "string" ||
        Builtins.regexpmatch(type, "^string\\(.*\\)$") ||
        type == "ip" ||
        Builtins.regexpmatch(type, "^regexp\\(.*\\)$")
    end

    # Generic list function - add value to the list if it isn't already there
    # @param [Array] l Input list
    # @param [String] v Input value
    # @return [Array] List with value v
    def add_if_missing(l, v)
      l = deep_copy(l)
      !Builtins.contains(l, v) ? Builtins.add(l, v) : l
    end

    # Escape double quotes and back slash characters by back slash
    # @param [String] input String to escape
    # @return Escaped string
    def backslash_add(input)
      # escape double quotes and back slashes
      escaped = ""
      pos = 0

      while Ops.less_than(pos, Builtins.size(input))
        ch = Builtins.substring(input, pos, 1)
        ch_1 = Builtins.substring(input, Ops.add(pos, 1), 1)

        # don't add backslash before \$ (#34809)
        if ch == "\\" && ch_1 != nil && ch_1 != "$"
          escaped = Ops.add(escaped, "\\\\")
        else
          if ch == "\""
            escaped = Ops.add(escaped, "\\\"")
          elsif ch == "\n"
            # multi line value
            escaped = Ops.add(escaped, "\\\n")
          else
            escaped = Ops.add(escaped, ch)
          end
        end

        pos = Ops.add(pos, 1)
      end

      escaped
    end

    # Remove backslashes from string - opposite funtion to the backslash_add function.
    # @param [String] input Escaped string
    # @return [String] String without escape chars
    def backslash_remove(input)
      return nil if input == nil

      ret = Builtins.regexpsub(input, "(.*)\\([^$].*)", "\\1\\2")

      ret == nil ? input : ret
    end

    # Create list of values for combo box widget
    # @param [Hash{String => Object}] description Variable description
    # @param [Boolean] set_default If true add default value to the list
    # @return [Array] List of values for combo box widget
    def combo_list(description, set_default)
      description = deep_copy(description)
      new_value = Ops.get_string(description, "new_value")
      value = Ops.get_string(description, "value", "")

      # use default value (or emty string) instead of the curent value in autoyast
      if Mode.config
        value = Builtins.haskey(description, "Default") ?
          Ops.get_string(description, "Default", "") :
          ""
      end

      if Ops.get_string(description, ["actions", "SingleQt"], "") == "1"
        new_value = backslash_remove(new_value)
        value = backslash_remove(value)
      end

      ret = []
      deflt = Ops.get_string(description, "Default")

      if set_default == true && deflt != nil
        Builtins.y2debug("Adding default value: %1", deflt)
        ret = Builtins.add(ret, deflt) if !Builtins.contains(ret, deflt)
      end

      if new_value != nil
        ret = Builtins.add(ret, new_value) if !Builtins.contains(ret, new_value)
      elsif value != nil
        ret = Builtins.add(ret, value) if !Builtins.contains(ret, value)
      end


      type = Ops.get_string(description, "Type", "")

      if type == "yesno"
        ret = Builtins.add(ret, "yes") if !Builtins.contains(ret, "yes")
        ret = Builtins.add(ret, "no") if !Builtins.contains(ret, "no")
      elsif type == "boolean"
        ret = Builtins.add(ret, "true") if !Builtins.contains(ret, "true")
        ret = Builtins.add(ret, "false") if !Builtins.contains(ret, "false")
      elsif Builtins.regexpmatch(type, "^list\\(.*\\)")
        values_string = Builtins.regexpsub(type, "^list\\((.*)\\)", "\\1")
        parsed = String.ParseOptions(values_string, Sysconfig.parse_param)

        # add missing items
        Builtins.foreach(parsed) do |option|
          ret = Builtins.add(ret, option) if !Builtins.contains(ret, option)
        end
      elsif Builtins.regexpmatch(type, "^string\\(.*\\)")
        values_string = Builtins.regexpsub(type, "^string\\((.*)\\)", "\\1")
        parsed = String.ParseOptions(values_string, Sysconfig.parse_param)

        # add missing items
        Builtins.foreach(parsed) do |option|
          ret = Builtins.add(ret, option) if !Builtins.contains(ret, option)
        end
      end

      # add default value to the list
      if deflt != nil && !Builtins.contains(ret, deflt)
        ret = Builtins.add(ret, deflt)
      end

      # add old value to the list if variable was modified
      if new_value != nil
        ret = Builtins.add(ret, value) if !Builtins.contains(ret, value)
      end

      Builtins.y2debug("combo list: %1", ret)

      deep_copy(ret)
    end

    # Update combo box in dialog
    # @param [Hash{String => Object}] description Variable description
    # @param [Boolean] set_default Set to true ifdefault value should be in the combo box
    def update_combo(description, set_default)
      description = deep_copy(description)
      varname = Ops.get_string(description, "name", "")

      # modification flag added to variable name (if it was changed)
      modif_flag = Builtins.haskey(description, "new_value") ?
        "  " + _("(changed)") :
        ""

      if combo_editable(description)
        # combo box widget label - variable name is appended to the string
        UI.ReplaceWidget(
          Id(:replace),
          ComboBox(
            Id(:combo),
            Opt(:editable, :hstretch),
            Ops.add(Ops.add(_("S&etting of: "), varname), modif_flag),
            combo_list(description, set_default)
          )
        )
      else
        # combo box widget label - variable name is appended to the string
        UI.ReplaceWidget(
          Id(:replace),
          ComboBox(
            Id(:combo),
            Opt(:hstretch),
            Ops.add(Ops.add(_("S&etting of: "), varname), modif_flag),
            combo_list(description, set_default)
          )
        )
      end

      # disable combo for non-leaf nodes
      UI.ChangeWidget(
        Id(:combo),
        :Enabled,
        Ops.get_string(description, "file", "") != ""
      )

      # display warning if value is not single line
      # combobox is one line entry, multiline values are merged to one line
      # (new lines are displayed as spaces, but they are correctly preserved
      val = Ops.get(description, "new_value") != nil ?
        Ops.get_string(description, "new_value", "") :
        Ops.get_string(description, "value", "")

      if val != nil
        lines = Builtins.splitstring(val, "\n")

        if Ops.greater_than(Builtins.size(lines), 1)
          # current value has more than one line - it is displayed incorrectly
          # because combobox widget has single line entry (lines are merged)
          Popup.Warning(
            _(
              "The currently selected value has more than one line.\nJoined lines are displayed in the combo box.\n"
            )
          )
        end
      end

      nil
    end

    # Update "Default" button state (enable/disable) in the dialog
    # @param [Hash{String => Object}] description Variable description
    def update_button_state(description)
      description = deep_copy(description)
      _def = Ops.get_string(description, "Default")

      UI.ChangeWidget(Id(:def), :Enabled, _def != nil)

      nil
    end

    # Update location text in the dialog
    # @param [Hash] description Variable description
    def update_location(description)
      description = deep_copy(description)
      l = Ops.get_string(description, "location", "")

      # header label
      UI.ChangeWidget(
        Id(:heading),
        :Value,
        Ops.add(Ops.add(_("Current Selection: "), l), @empty_string)
      )

      nil
    end

    # Is selected item in the tree widget leaf node?
    # @param [String] id Value from tree widget
    # @return [Boolean] True if node is not leaf-node
    def is_node(id)
      Builtins.findfirstof(id, "$") == nil
    end

    # Set new value for variable, warn user if new value does not match type definition.
    # @param [Boolean] force_change force value as changed even if it is equal to the old one
    def check_set_current_value(force_change)
      # check current value
      if @selected_variable != ""
        new_value = Convert.to_string(UI.QueryWidget(Id(:combo), :Value))
        d = Sysconfig.get_description(@selected_variable)

        # check whether single quotes are used in the configuration file
        if Ops.get_string(d, ["actions", "SingleQt"], "") == "1"
          new_value = backslash_add(new_value)
        end

        if Sysconfig.get_name_from_id(@selected_variable) != ""
          # variable was selected (not category)
          result = Sysconfig.set_value(
            @selected_variable,
            new_value,
            false,
            force_change
          )

          if result == :not_valid
            t = Ops.get_string(d, "Type", "string")

            # popup question dialog: variable value does not match defined type - ask user to set value (%1 is value entered by user, %2 is allowed type - e.g. integer
            if Popup.AnyQuestion(
                Label.WarningMsg,
                Builtins.sformat(
                  _(
                    "Value '%1'\n" +
                      "does not match type '%2'.\n" +
                      "\n" +
                      "Really set this value?\n"
                  ),
                  new_value,
                  t
                ),
                Label.YesButton,
                Label.NoButton,
                :focus_no
              ) == true
              # force setting of value
              Sysconfig.set_value(
                @selected_variable,
                new_value,
                true,
                force_change
              )
            end
          end
        end
      end

      nil
    end

    # Create table content list for selected variables
    # @param [Array<String>] varids Variables which will be contained in the table
    # @return [Array] Table content
    def create_table_content(varids)
      varids = deep_copy(varids)
      table_content = []

      Builtins.foreach(varids) do |varid|
        descr = Sysconfig.get_description(varid)
        name = Ops.get_string(descr, "name", "")
        old = Ops.get_string(descr, "value", "")
        new = Ops.get_string(descr, "new_value", "")
        file = Ops.get_string(descr, "file", "")
        # display only beginning of comment (to limit table space used)
        comm = Ops.get_string(descr, "comment", "")
        # remove newlines
        comm = Sysconfig.remove_whitespaces(
          Builtins.mergestring(Builtins.splitstring(comm, "\n"), " ")
        )
        if Ops.greater_than(Builtins.size(comm), 90)
          comm = Builtins.substring(comm, 0, 90)
          # when a comment is too long to display it in the table
          # it is shortened and mark (three dot characters) is added to the end
          comm = Ops.add(comm, _("..."))
        end
        table_content = Builtins.add(
          table_content,
          Item(Id(varid), name, new, old, file, comm)
        )
      end 


      deep_copy(table_content)
    end

    def GenerateTree(_Tree, parent, input)
      _Tree = deep_copy(_Tree)
      input = deep_copy(input)
      Builtins.foreach(input) do |i|
        id = Ops.get_string(i, [0, 0], "")
        title = Ops.get_string(i, 1, "")
        enabled = Ops.get_boolean(i, 2, false)
        children = Ops.get_list(i, 3, [])
        _Tree = Wizard.AddTreeItem(_Tree, parent, title, id)
        if Ops.greater_than(Builtins.size(children), 0)
          _Tree = GenerateTree(_Tree, id, children)
        end
      end
      deep_copy(_Tree)
    end



    # Display main configuration dialog
    # @return dialog result
    def MainDialog
      button_box = HBox(
        # back pushbutton: the user input is ignored and the last dialog is called
        PushButton(Id(:abort), Opt(:key_F9), Label.AbortButton),
        HStretch(),
        PushButton(Id(:help), Opt(:key_F1), Label.HelpButton),
        HStretch(),
        # Translation: push button label
        PushButton(Id(:search), _("&Search")),
        HStretch(),
        PushButton(Id(:next), Opt(:key_F10), Label.FinishButton)
      )

      # tree widget label
      # term help_space_content = `Tree(`id(`tree), `opt(`notify, `vstretch), _("&Configuration Options"), Sysconfig::tree_content);

      # Wizard::OpenCustomDialog(help_space_content, button_box);
      Wizard.CreateTreeDialog
      _Tree = GenerateTree([], "", Sysconfig.tree_content)
      Wizard.CreateTree(_Tree, _("&Configuration Options"))

      helptext =
        # helptext for popup - part 1/2
        _(
          "<p>After you save your changes, this editor changes the variables in the\n" +
            "corresponding sysconfig file. Then it starts activation commands, which changes the underlying configuration files, stops and starts daemons,\n" +
            "and runs low-level configuration tools so your configuration in sysconfig takes effect.</p>\n"
        ) +
          # helptext for popup - part 2/2
          _(
            "<p><b>Important:</b> You still can edit each individual configuration file manually. The name of file is displayed in the variable description.</p>"
          )

      Wizard.SetContents(
        _("/etc/sysconfig Editor"),
        VBox(
          # label widget
          Left(
            Label(
              Id(:heading),
              Opt(:hstretch),
              Ops.add(_("Current Selection: "), @empty_string)
            )
          ),
          VSpacing(0.5),
          HBox(
            HWeight(
              1,
              ReplacePoint(
                Id(:replace),
                # combo box label
                ComboBox(
                  Id(:combo),
                  Opt(:disabled, :hstretch),
                  _("S&etting of: "),
                  [""]
                )
              )
            ),
            VBox(
              # dummy widget used to align button
              Label(""),
              # push button label
              PushButton(Id(:def), Opt(:disabled), _("&Default"))
            )
          ),
          VSpacing(1),
          # help rich text displayed after module start (1/2)
          RichText(
            Id(:rt),
            _(
              "<P><B>System Configuration Editor</B></P><P>With the system configuration editor, you can change some system settings. You can also use YaST to configure your hardware and system settings.</P>"
            ) +
              # help rich text displayed after module start (2/2)
              _(
                "<P><B>Note:</B> Descriptions are not translated because they are read directly from configuration files.</P>"
              )
          ),
          # push button label - displayed only in autoinstallation config mode
          Mode.config == true ?
            HBox(
              PushButton(Id(:use_current), _("&Use Current Value")),
              # push button label - displayed only in autoinstallation config mode
              PushButton(Id(:add_new), Opt(:key_F3), _("&Add New Variable..."))
            ) :
            Empty()
        ),
        helptext,
        true,
        true
      )

      # push button label
      Wizard.SetBackButton(:back, _("&Search"))
      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      if UI.WidgetExists(Id(:wizardTree))
        UI.ReplaceWidget(Id(:rep_button_box), button_box)
      end
      Wizard.SetDesktopTitleAndIcon("sysconfig")

      ret = nil

      while ret != :cancel && ret != :abort && ret != :next
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")


        # "Default" button
        if ret == :def
          description = Sysconfig.get_description(@selected_variable)
          update_combo(description, true)
        elsif ret == :next
          # check if current value was modified
          check_set_current_value(false)

          modified = Sysconfig.get_modified

          # show table with modified variables
          if Ops.greater_than(Builtins.size(modified), 0)
            Builtins.y2milestone("Modified variables: %1", modified)

            # popup dialog header - confirm to save the changes
            result = display_variables_dialog(
              _("Save Modified Variables"),
              "",
              # checkbox label
              create_table_content(modified),
              Label.SaveButton,
              Label.CancelButton,
              _("Confirm Each Activation Command"),
              false
            )

            ret = :again if Ops.get_symbol(result, "ui", :dummy) == :cancel

            # set confirmation flag
            Sysconfig.ConfirmActions = Ops.get_boolean(
              result,
              "checkbox",
              false
            )
          end
        elsif ret == :back || ret == :search # This is for Search actually FIXME
          search_parameters = display_search_dialog

          if search_parameters != {}
            found = Sysconfig.Search(search_parameters, true)

            if Ops.greater_than(Builtins.size(found), 0)
              # // popup dialog header
              input = display_variables_dialog(
                _("Search Result"),
                # help text in popup dialog
                _(
                  "The search results are displayed here. If you see the item you want, select it then click \"Go to\". Otherwise, click \"Cancel\" to close this dialog."
                ),
                create_table_content(found),
                # push button label
                _("&Go to"),
                Label.CancelButton,
                "",
                nil
              )

              if Ops.get_symbol(input, "ui", :dummy) == :cancel
                ret = :again
              else
                sel = Ops.get_string(input, "selected")
                if sel != nil
                  # select variable in the tree
                  #UI::ChangeWidget(`id(`tree), `CurrentItem, sel);
                  Wizard.SelectTreeItem(sel)

                  # display selected variable
                  if UI.WidgetExists(Id(:wizardTree))
                    ret = :wizardTree
                  else
                    ret = sel
                  end
                end
              end
            else
              # popup message - search result message
              Popup.Message(_("No entries found"))
            end
          end
        elsif ret == :help
          UI.OpenDialog(
            Opt(:decorated),
            HBox(
              VSpacing(16),
              VBox(
                HSpacing(60),
                # popup window header
                Heading(_("Help")),
                VSpacing(0.5),
                RichText(helptext),
                VSpacing(1.5),
                # push button label
                PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
              )
            )
          )

          UI.SetFocus(Id(:ok))
          UI.UserInput
          UI.CloseDialog
        elsif ret == :abort || ret == :cancel
          if !ReallyAbort()
            ret = nil
          else
            # `cancel is same as `abort
            ret = :abort
          end
        # autoinstallation config mode only
        elsif ret == :use_current
          # force current value as changed
          check_set_current_value(true)

          description = Sysconfig.get_description(@selected_variable)

          # update combo box - add "changed" status
          update_combo(description, false)
        # autoinstallation config mode only
        elsif ret == :add_new
          # ask user for new variable name, value and location (file name)
          _in = add_new_variable

          ui = Ops.get_symbol(_in, "ui", :cancel)
          name = Ops.get_string(_in, "name", "")
          file = Ops.get_string(_in, "file", "")
          value = Ops.get_string(_in, "value", "")

          if ui == :ok
            Sysconfig.set_value(
              Builtins.sformat("%1$%2", name, file),
              value,
              false,
              true
            )
          end
        end

        if ret == :wizardTree || Ops.is_string?(ret)
          check_set_current_value(false)

          # string selected = (string)UI::QueryWidget(`id(`tree), `CurrentItem);
          selected = Wizard.QueryTreeItem
          @selected_variable = selected
          Builtins.y2milestone("Selected: %1", selected)

          description = Sysconfig.get_description(selected)

          Builtins.y2milestone("Descr: %1", description)

          # update richtext content
          UI.ChangeWidget(
            Id(:rt),
            :Value,
            create_description(description, true)
          )

          # update combo box
          update_combo(description, false)

          # update "Default" button state (enable/disable)
          update_button_state(description)

          # update location in header
          update_location(description)
        end
      end

      UI.CloseDialog

      Convert.to_symbol(ret)
    end
  end
end
