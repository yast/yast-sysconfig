require 'minitest/autorun'
require 'minitest/spec'
require 'pathname'
require 'fileutils'

# Use `require_relative "spec_helper"` on top of your spec files to be able to
# run them separately with command `ruby spec/some_spec.rb`
# Use `rake spec` to run the whole testsuite.

ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)

require 'yast'

Yast.import 'Sysconfig'

# This allows to run all test files with a single call
# `ruby test/test_helper.rb`
if __FILE__ == $0
  $LOAD_PATH.unshift('test')
  Dir.glob('./test/**/*_test.rb') { |f| require f }
end

module TestHelpers
  include FileUtils

  attr_reader :sysconfig

  FILES_DIR = Pathname.new(File.join 'files')
  TMP_DIR   = Pathname.new(File.expand_path('../tmp', __FILE__))

  FILES = {
    :yast2          => 'yast2',
    :postfix        => 'postfix',
    :network_dhcp   => 'network/dhcp',
    :network_config => 'network/config'
  }

  def initialize_sysconfig
    @sysconfig = Yast::SysconfigClass.new
    sysconfig.main
    sysconfig.configfiles = []
    sysconfig
  end

  def samples
    FILES.values.map {|f| TMP_DIR.join(f).to_s }
  end

  def file_path name
    TMP_DIR.join(FILES[name]).to_path
  end

  def get_config_value config_variable_name, config_name
    sysconfig.get_description("#{config_variable_name}'$'#{file_path(config_name)}")['value'].to_s
  end

  def get_sysconfig_varid config_variable
    sysconfig.get_all_names[config_variable].first
  end

  def load_sample_file file_name
    case file_name
    when :all
      FILES.each do |name, path|
        origin_file_path = FILES_DIR.join(path)
        temp_file_path   = TMP_DIR.join(path)
        fail "Test file '#{origin_file_path} does not exist" unless File.exists?(origin_file_path)
        mkdir_p File.dirname(temp_file_path)
        cp origin_file_path, temp_file_path
        fail "Test file '#{name}' not found in path '#{temp_file_path}'" unless File.exists?(temp_file_path)
        sysconfig.configfiles << temp_file_path
      end
    else
      temp_file_path = TMP_DIR.join FILES[file_name]
      mkdir_p File.dirname(temp_file_path)
      cp FILES_DIR.join(FILES[file_name]), temp_file_path
      sysconfig.configfiles << temp_file_path
    end
  end

  def sweep_sample_file file_name
    case file_name
    when :all
      rm_rf Dir.glob "#{TMP_DIR}/*"
    else
      rm_rf TMP_DIR.join(FILES[file_name])
    end
  end

end

