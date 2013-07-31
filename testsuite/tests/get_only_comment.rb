# encoding: utf-8

# Sysconfig module - testsuite
#
# get_only_comment tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class GetOnlyCommentClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      # Note: Testsuite::Dump is used instead of Testsuite::Test, because it supports multiline
      # output (Testsuite::Test dumps only first line)

      @input = nil
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = ""
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = "# sdfa  "
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = "### gfh "
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = "# dsfds"
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = "# adsf \n# sdfwer\n"
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))
      Testsuite.Dump("---")

      @input = "\n\n#134\n   \n#34763\n  ##Path"
      Testsuite.Dump(Builtins.sformat("Input: %1", @input))
      Testsuite.Dump("Output:")
      Testsuite.Dump(Sysconfig.get_only_comment(@input))

      nil
    end
  end
end

Yast::GetOnlyCommentClient.new.main
