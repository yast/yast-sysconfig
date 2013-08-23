require_relative 'test_helper'

include TestHelpers

describe "Import and export of autoyast configuration" do
  before do
    initialize_sysconfig
  end

  it "accepts configuration values" do
    var_name  = 'FIREWALL'
    var_value = 'no'
    load_sample :network_config do
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
end
