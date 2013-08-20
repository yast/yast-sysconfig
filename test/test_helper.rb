require 'minitest/autorun'
require 'minitest/spec'
require 'yast'

# Use `require_relative "spec_helper"` on top of your spec files to be able to
# run them separately with command `ruby spec/some_spec.rb`
# Use `rake spec` to run the whole testsuite.

Yast.add_module_path File.expand_path('../../src/modules/', __FILE__)
Yast.import 'Sysconfig'
