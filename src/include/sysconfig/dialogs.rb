# encoding: utf-8

# File:	include/sysconfig/dialogs.ycp
# Package:	Configuration of sysconfig
# Summary:	Dialogs definitions
# Authors:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
module Yast
  module SysconfigDialogsInclude
    def initialize_sysconfig_dialogs(include_target)
      Yast.import "UI"

      textdomain "sysconfig"

      Yast.import "Sysconfig"

      Yast.import "Popup"
      Yast.import "Label"

      Yast.include include_target, "sysconfig/helps.rb"
      Yast.include include_target, "sysconfig/routines.rb"
    end

    # Display search dialog
    # @return [Hash] Search option values selected in the dialog
    def display_search_dialog
      UI.OpenDialog(
        Opt(:decorated),
        VBox(
          HSpacing(60),
          # search popup window header
          Heading(_("Search for a Configuration Variable")),
          VSpacing(0.5),
          HBox(
            VSpacing(10),
            HSpacing(2),
            VBox(
              VSpacing(1),
              # text entry label
              TextEntry(Id(:search_entry), _("&Search for:")),
              VSpacing(1),
              # check box label
              Left(CheckBox(Id(:ignore), _("&Case Sensitive Search"), false)),
              # check box label
              Left(CheckBox(Id(:nkey), _("Search &Variable Name"), true)),
              # check box label
              Left(CheckBox(Id(:ndescr), _("Search &description"), true)),
              # check box label
              Left(CheckBox(Id(:nvalue), _("Search &value"), false)),
              VSpacing(1)
            ),
            HSpacing(2)
          ),
          VSpacing(0.5),
          ButtonBox(
            # push button label
            PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
            # push button label
            PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton)
          )
        )
      )

      UI.SetFocus(Id(:search_entry))

      ui = Convert.to_symbol(UI.UserInput)

      while ui != :ok && ui != :cancel
        ui = Convert.to_symbol(UI.UserInput)
      end

      ret = {}

      if ui == :ok
        ret = Builtins.add(
          ret,
          "search",
          Convert.to_string(UI.QueryWidget(Id(:search_entry), :Value))
        )
        ret = Builtins.add(
          ret,
          "insensitive",
          !Convert.to_boolean(UI.QueryWidget(Id(:ignore), :Value))
        )
        ret = Builtins.add(
          ret,
          "varname",
          Convert.to_boolean(UI.QueryWidget(Id(:nkey), :Value))
        )
        ret = Builtins.add(
          ret,
          "value",
          Convert.to_boolean(UI.QueryWidget(Id(:nvalue), :Value))
        )
        ret = Builtins.add(
          ret,
          "description",
          Convert.to_boolean(UI.QueryWidget(Id(:ndescr), :Value))
        )
      end

      UI.CloseDialog
      deep_copy(ret)
    end

    # Display dialog with selected variables
    # @param [String] header Heading in the dialog
    # @param [String] label Label in the dialog
    # @param [Array] table_content Table content list
    # @param [String] ok_label OK button label
    # @param [String] cancel_label Cancel button label
    # @param [String] checkboxlabel Optional check box widget is displayed when size of checkboxlabel is greater than zero
    # @param [Boolean] checkboxvalue Check box value
    # @return [Hash] Selected variable, checkbox value (nil if it wasn't used), user input values
    def display_variables_dialog(header, label, table_content, ok_label, cancel_label, checkboxlabel, checkboxvalue)
      table_content = deep_copy(table_content)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          VSpacing(17),
          VBox(
            HSpacing(70),
            #heading of popup
            Heading(header),
            label == "" ? Empty() : Label(label),
            VSpacing(0.5),
            # table column header
            Table(
              Id(:table),
              Header(
                _("Name"),
                _("NEW VALUE"),
                _("Old Value"),
                _("File"),
                _("Description")
              ),
              table_content
            ),
            Ops.greater_than(Builtins.size(checkboxlabel), 0) ?
              CheckBox(Id(:chbox), checkboxlabel, checkboxvalue) :
              Empty(),
            VSpacing(0.5),
            ButtonBox(
              # push button label
              PushButton(Id(:action), Opt(:default, :key_F10), ok_label),
              # push button label
              PushButton(Id(:cancel), Opt(:key_F9), cancel_label)
            )
          )
        )
      )

      ret = Convert.to_symbol(UI.UserInput)
      selected = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))
      box = nil

      if Ops.greater_than(Builtins.size(checkboxlabel), 0)
        box = Convert.to_boolean(UI.QueryWidget(Id(:chbox), :Value))
      end

      UI.CloseDialog

      { "ui" => ret, "selected" => selected, "checkbox" => box }
    end


    # Display dialog for new variable. This dialog is used at autoinstalation config mode
    # only - some packages may not be available at configure time, but they will be present
    # at installation, so it is possible to change them even if they are not displayed.
    # @return [Hash] Map with keys "ui" (`ok or `cancel - user input), "name" (name of
    # the new variable), "file" (location of variable) and "value" (value to write)
    def add_new_variable
      UI.OpenDialog(
        Opt(:decorated),
        VBox(
          HBox(
            # text entry label
            TextEntry(Id(:name), _("&Variable Name"), ""),
            # text entry label
            TextEntry(Id(:value), _("V&alue"), "")
          ),
          VSpacing(1),
          HBox(
            # text entry label
            TextEntry(Id(:file), _("&File Name"), "")
          ),
          VSpacing(1),
          ButtonBox(
            PushButton(Id(:ok), Opt(:key_F10), Label.OKButton),
            PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton)
          )
        )
      )

      ui = nil

      name = ""
      file = ""

      while ui != :ok && ui != :cancel
        ui = Convert.to_symbol(UI.UserInput)

        name = Convert.to_string(UI.QueryWidget(Id(:name), :Value))
        file = Convert.to_string(UI.QueryWidget(Id(:file), :Value))

        if ui == :ok
          if name == ""
            # warning popup message - variable name is empty
            Popup.Warning(_("Missing variable name value."))
            ui = nil
          elsif Ops.less_or_equal(Builtins.size(file), 1)
            # warning popup message - file name is empty
            Popup.Warning(_("Missing file name value."))
            ui = nil
          elsif Builtins.substring(file, 0, 1) != "/"
            # warning popup message - file name is required with absolute path
            Popup.Warning(_("Missing absolute path in file name."))
            ui = nil
          end
        end
      end

      value = Convert.to_string(UI.QueryWidget(Id(:value), :Value))

      UI.CloseDialog

      { "ui" => ui, "name" => name, "value" => value, "file" => file }
    end
  end
end
