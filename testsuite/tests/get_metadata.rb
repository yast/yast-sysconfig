# encoding: utf-8

# Sysconfig module - testsuite
#
# get_metadata tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class GetMetadataClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Test(lambda { Sysconfig.get_metadata(nil) }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.get_metadata("") }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.get_metadata(" ## Type: ip  ") }, [
        {},
        {},
        {}
      ], nil)

      Testsuite.Test(lambda { Sysconfig.get_metadata("## Type: ip  ") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.get_metadata("##Type: ip") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.get_metadata("## Type: sdf  \n## Default: sdf")
      end, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda do
        Sysconfig.get_metadata("\n\n## Type\n   \n##Def\n  ##Path")
      end, [
        {},
        {},
        {}
      ], nil)

      nil
    end
  end
end

Yast::GetMetadataClient.new.main
