# encoding: utf-8

# Sysconfig module - testsuite
#
# remove_whitespaces tests
#
# testedfiles: Sysconfig.ycp
#
# $Id$
#
module Yast
  class RemoveWhitespacesClient < Client
    def main
      Yast.import "Testsuite"
      Yast.import "Pkg" # override packamanager
      Yast.import "Sysconfig"

      Testsuite.Test(lambda { Sysconfig.remove_whitespaces(nil) }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("") }, [{}, {}, {}], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("    ") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("  var") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("  var  ") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("v  a  r") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("va r ") }, [
        {},
        {},
        {}
      ], nil)
      Testsuite.Test(lambda { Sysconfig.remove_whitespaces("var") }, [{}, {}, {}], nil)

      nil
    end
  end
end

Yast::RemoveWhitespacesClient.new.main
