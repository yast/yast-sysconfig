# encoding: utf-8

# Sysconfig module - testsuite
#
# parse_metadata tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class ParseMetadataClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Test(lambda { Sysconfig.parse_metadata(nil) }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.parse_metadata("") }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.parse_metadata("    ") }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.parse_metadata("## Type: abc") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.parse_metadata("## Type: abc\n## Default: x")
      end, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.parse_metadata("## Type: abc\n\n##Default:x\n\n ")
      end, [
        {},
        {},
        {}
      ], nil)
      # multiline
      Testsuite.Test(lambda do
        Sysconfig.parse_metadata(
          "## Command: echo sdmvf,vm \\\n" +
            "## sdgfsdg sdf sf sf sdf \n" +
            "## Config:x, asdf\n" +
            "\n" +
            " "
        )
      end, [
        {},
        {},
        {}
      ], nil)

      nil
    end
  end
end

Yast::ParseMetadataClient.new.main
