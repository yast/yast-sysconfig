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

  attr_reader :sysconfig, :context

  FILES_DIR = Pathname.new(File.join 'files')
  TMP_DIR   = Pathname.new(File.expand_path('../tmp', __FILE__))

  # If needed extend this map as required
  # Every file listed here should exist in the directory FILES_DIR
  # Otherwise exception will be raised while loading the file to TMP_DIR during tests
  FILES = {
    :yast2          => 'yast2',
    :postfix        => 'postfix',
    :network_dhcp   => 'network/dhcp',
    :network_config => 'network/config'
  }

  # Create the sysconfig object
  # Useful for before{} block in test examples
  # FIXME Reinitializing in a test example causes segfaulting once you have
  # called sysconfig.Read
  def initialize_sysconfig
    @sysconfig = Yast::SysconfigClass.new
    sysconfig.main
    sysconfig.configfiles = []
    sysconfig
  end

  # Loads the specific file from the FILES hash, use the symbol name
  # instad of the path, it's easier to write and to understand
  def load_sample context
    @context = context
    load_sample_file(context)
    yield
    sweep_sample_file(context)
  end

  # Proxy to sysconfig to get the value of some configuration variable
  def get_value config_variable
    get_config_value(config_variable, self.context)
  end

  # Proxy to sysconfig.set_value to make it shorter
  def set_value variable_name, variable_value
    sysconfig.set_value(get_sysconfig_varid(variable_name), variable_value, false, false)
  end

  def modified_var? variable_name
    sysconfig.instance_variable_get(:@modified_variables).keys.grep(/#{variable_name}/) != nil
  end

  # Get all files stored in files/ dir mapped to tmp/ dir
  def sample_files
    FILES.values.map {|f| TMP_DIR.join(f).to_s }
  end

  # Get the tmp path to the named file
  def sample_path name=nil
    return TMP_DIR.join(FILES[context]).to_s unless name
    TMP_DIR.join(FILES[name]).to_s
  end

  # This ugly method is needed when calling #set_value on sysconfig
  def get_sysconfig_varid config_variable
    ( sysconfig.get_all_names[config_variable] || [] ).first
  end

  def get_config_value variable_name, config_context=nil
    sysconfig.get_description("#{variable_name}$#{sample_path(config_context || context)}")['value'].to_s
  end

  def get_config_metadata variable_name, config_context
    sysconfig.get_description("#{variable_name}$#{sample_path(config_context)}")
  end

  # Use you want to work with a single sample file or with all of them
  # It makes a copy of the sample file from files/ dir in the tmp/ dir
  # Do not forget to call #sweep_sample_file after that!
  def load_sample_file file_name
    case file_name
    when :all
      FILES.each do |name, path|
        origin_file_path = FILES_DIR.join(path).to_s
        temp_file_path   = TMP_DIR.join(path).to_s
        fail "Test file '#{origin_file_path} does not exist" unless File.exists?(origin_file_path)
        mkdir_p File.dirname(temp_file_path)
        cp origin_file_path, temp_file_path
        fail "Test file '#{name}' not found in path '#{temp_file_path}'" unless File.exists?(temp_file_path)
        sysconfig.configfiles << temp_file_path
      end
    else
      temp_file_path = TMP_DIR.join(FILES[file_name]).to_s
      mkdir_p File.dirname(temp_file_path)
      cp FILES_DIR.join(FILES[file_name]), temp_file_path
      sysconfig.configfiles << temp_file_path
    end
  end

  # Removes the sample file from the tmp/ dir
  def sweep_sample_file file_name
    case file_name
    when :all
      rm_rf Dir.glob "#{TMP_DIR}/*"
    else
      rm_rf TMP_DIR.join(FILES[file_name])
    end
  end

end

