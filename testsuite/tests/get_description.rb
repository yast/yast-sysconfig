# encoding: utf-8

# Sysconfig module - testsuite
#
# get_description() tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class GetDescriptionClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Test(lambda do
        Sysconfig.Set(
          [
            {
              "sysconfig_key"   => "VARIABLE",
              "sysconfig_path"  => "/etc/sysconfig/test",
              "sysconfig_value" => "no"
            }
          ]
        )
      end, [
        {},
        {},
        {}
      ], nil)


      # test non-existing variable
      Testsuite.Test(lambda { Sysconfig.get_description("nonexisting$variable") }, [
        {},
        {},
        {}
      ], nil)

      # test variable without metadata
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "# Only comment, no metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)


      # test variable with metadata
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Path: Test\n" +
                "## Description: help\n" +
                "## Type: yesno\n" +
                "# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)


      # test multiple keywods in metadata
      @READ = {
        "syseditor" => {
          "value"         => {
            "/etc/sysconfig/test" => { "VARIABLE" => "yes" }
          },
          "value_comment" => {
            "/etc/sysconfig/test" => {
              "VARIABLE" => "## Path: Test\n" +
                "## Description: help\n" +
                "## Type: yesno\n" +
                "##Path: Second path definition\n" +
                "# Comment with metadata"
            }
          }
        }
      }
      Testsuite.Test(lambda do
        Sysconfig.get_description("VARIABLE$/etc/sysconfig/test")
      end, [
        @READ,
        {},
        {}
      ], nil)

      nil
    end
  end
end

Yast::GetDescriptionClient.new.main
