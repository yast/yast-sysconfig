require_relative 'test_helper'

include TestHelpers

describe "Change variables in config files" do
  before do
    initialize_sysconfig
    load_sample_file(:postfix)
  end

  after do
    sweep_sample_file(:postfix)
  end

  it "should save the changed variable value" do
    var_name = "POSTFIX_MYHOSTNAME"
    original_value = get_config_value(var_name, :postfix)
    new_value = "suse.cz"
    sysconfig.Read
    sysconfig.set_value(get_sysconfig_varid(var_name), new_value, false, false)
    sysconfig.Modified.must_equal true
    sysconfig.instance_variable_get(:@modified_variables).keys.grep(/#{var_name}/).wont_be_nil
    sysconfig.Summary.must_match(/#{var_name}.*#{new_value}/)
    sysconfig.Write.must_equal true
  end
end
