require_relative 'test_helper'

include TestHelpers

describe "Change variables in config files" do
  before do
    initialize_sysconfig
  end

  it "should save the changed postfix variable value" do
    load_sample :postfix do
      var_name = "POSTFIX_MYHOSTNAME"
      original_value = get_value(var_name)
      new_value = "suse.cz"
      sysconfig.Read
      set_value(var_name, new_value)
      sysconfig.Modified.must_equal true
      modified_var?(var_name).wont_equal false
      sysconfig.Summary.must_match(/#{var_name}.*#{new_value}/)
      sysconfig.stub(:StartCommand, :success) { sysconfig.Write.must_equal true }
      sysconfig.Read
      get_value(var_name).must_equal(new_value)
    end
  end

  it "should not change configuration due to incorrect variable value" do
    load_sample :yast2 do
      var_name = 'USE_SNAPPER'
      new_value = 'Not at weekends, baby'
      sysconfig.Read
      original_value = get_value(var_name)
      set_value(var_name, new_value)
      sysconfig.Modified.must_equal false
      sysconfig.Summary.wont_match(/#{var_name}.*#{new_value}/)
      sysconfig.stub(:StartCommand, :success) { sysconfig.Write.must_equal true }
      sysconfig.Read
      get_value(var_name).must_equal(original_value)
    end
  end

  it "should set hostname for dhcp client to yes" do
    load_sample :network_dhcp do
      variable_name = 'DHCLIENT_SET_HOSTNAME'
      original_value = get_value(variable_name)
      new_value = 'no'
      sysconfig.Read
      set_value(variable_name, new_value)
      sysconfig.Modified.must_equal true
      modified_var?(variable_name).wont_equal false
      sysconfig.Summary.must_match(/#{variable_name}.*#{new_value}/)
      sysconfig.stub(:StartCommand, :success) { sysconfig.Write.must_equal true }
      sysconfig.Read
      get_value(variable_name).must_equal(new_value)
    end
  end
end
