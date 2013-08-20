require_relative 'spec_helper'
require 'yast/rake/test'

describe 'rake.config.console' do
  it "import the Sysconfig yast module" do
#   Yast.constants.must_include :Sysconfig
    [1].must_include 3, "3 must be included in the array"
  end
end
