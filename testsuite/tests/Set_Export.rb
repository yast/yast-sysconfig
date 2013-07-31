# encoding: utf-8

# Sysconfig module - testsuite
#
# Set() and Export() tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class SetExportClient < Client
    def main
      Yast.import "Testsuite"

      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Test(lambda { Sysconfig.Set(nil) }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.Export }, [{}, {}, {}], nil)

      Testsuite.Test(lambda { Sysconfig.Set([]) }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.Export }, [{}, {}, {}], nil)

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
      Testsuite.Test(lambda { Sysconfig.Export }, [{}, {}, {}], nil)

      nil
    end
  end
end

Yast::SetExportClient.new.main
