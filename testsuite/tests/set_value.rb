# encoding: utf-8

# Sysconfig module - testsuite
#
# set_value() tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class SetValueClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Dump("Testing data type validation")

      # initialize variable
      Testsuite.Test(lambda do
        Sysconfig.Set(
          [
            {
              "sysconfig_key"   => "VARIABLE",
              "sysconfig_path"  => "/etc/sysconfig/test",
              "sysconfig_value" => "yes"
            }
          ]
        )
      end, [
        {},
        {},
        {}
      ], nil)

      # variable with metadata
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: yesno\n# Comment with metadata"
            }
          }
        }
      }

      Testsuite.Dump("Test yesno type")
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "no", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "yes", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "123", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "yesno",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test boolean type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: boolean\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "true",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "false",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "234", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test integer type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "123", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "0234x",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "x0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "02-34",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test integer(0:100) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer(0:100)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "12", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "100", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-1", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "101", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "-2301",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test integer(-10:10) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer(-10:10)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test integer(0:) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer(0:)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test integer(-10:) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer(-10:)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test integer(10:) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: integer(10:)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test string type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: string\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test string(0,10) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: string(0,10)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test list(0,10) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: list(0,10)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "5", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2123",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "ewre",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "3.1415927",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test list(\"a, bc\",a,b,,c,\\\") type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: list(\"a, bc\",a,b,,c,\\\")\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "a", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "a,b,",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "a, bc",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "\"a, bc\"",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "\"", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "11", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test ip type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: ip\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "10.20.30.40",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "234.234234.234.23",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "::1", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2001:780:101:1400:230:84ff:fe0e:2376",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test ip4 type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: ip4\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "10.20.30.40",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "234.234234.234.23",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "::1", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2001:780:101:1400:230:84ff:fe0e:2376",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)

      Testsuite.Dump("Test ip6 type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: ip6\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "-10", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "10.20.30.40",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "234.234234.234.23",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "::1", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "2001:780:101:1400:230:84ff:fe0e:2376",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test regexp(abc) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: regexp(abc)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "abc", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "10abcasd20",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "abcabc",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "abbc",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Test regexp(^0[0-7]*$) type")
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Type: regexp(^0[0-7]*$)\n# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "02", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "023", false, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "0897",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "vxb003",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)



      Testsuite.Dump("Testing value setting")

      # get current value (should be 023 frou previous tests)
      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)
      # force wrong value
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "0897", true, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      # get current value
      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)


      Testsuite.Dump("Testing list of changed values")

      # set original value => no change
      Testsuite.Test(lambda do
        Sysconfig.set_value("VARIABLE$/etc/sysconfig/test", "yes", true, false)
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.Modified }, [@READ, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.get_modified }, [@READ, {}, {}], nil)

      # set new value
      Testsuite.Test(lambda do
        Sysconfig.set_value(
          "VARIABLE$/etc/sysconfig/test",
          "0777",
          false,
          false
        )
      end, [
        @READ,
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.Modified }, [@READ, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.get_modified }, [@READ, {}, {}], nil)

      nil
    end
  end
end

Yast::SetValueClient.new.main
