require_relative 'test_helper'

include TestHelpers

describe "Import and export of autoyast configuration" do
  before do
    initialize_sysconfig
  end

  it "can import correctly defined configuration values" do
    load_sample :network_config do
      var_name  = 'FIREWALL'
      var_value = 'no'
      profile_values = [{
        'sysconfig_key'   => var_name,
        'sysconfig_value' => var_value,
        'sysconfig_path'  => sample_path
      }]
      sysconfig.Import(profile_values)
      sysconfig.Modified.must_equal true
      sysconfig.Export.wont_be_empty
    end
  end

  it "can import incorrectly defined config values" do
    load_sample :network_config do
      var_name  = 'FIREBALL'
      var_value = 'DONT TOUCH THIS'
      profile_values = [{
        'sysconfig_key'   => var_name,
        'sysconfig_value' => var_value,
        'sysconfig_path'  => sample_path
      }]
      sysconfig.Import(profile_values)
      sysconfig.Modified.must_equal true
      sysconfig.Export.wont_be_empty
      sysconfig.Export.first['sysconfig_key'].wont_be_empty
      sysconfig.Export.first['sysconfig_key'].must_equal(var_name)
      sysconfig.Export.first['sysconfig_value'].wont_be_empty
      sysconfig.Export.first['sysconfig_value'].must_equal(var_value)
      sysconfig.Export.first['sysconfig_path'].wont_be_empty
      sysconfig.Export.first['sysconfig_path'].must_equal(sample_path)
    end
  end

  it "accepts totally random defined variable names and values" do
    load_sample :network_config do
      profile_values = [{
        'not_expected_key'   => rand(88888),
        'not_expected_value' => rand(88888),
        'not_expected_path'  => rand(88888)
      }]
      sysconfig.Import(profile_values).must_equal true
      sysconfig.Modified.must_equal true
      sysconfig.Export.wont_be_empty
      sysconfig.Export.first['sysconfig_key'].must_be_empty
      sysconfig.Export.first['sysconfig_value'].must_be_empty
      sysconfig.Export.first['sysconfig_path'].wont_be_empty # default value is set
    end
  end
end
