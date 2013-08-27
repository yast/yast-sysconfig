require_relative 'test_helper'

include TestHelpers

describe "Autoyast configuration" do
  describe "How the profile import works" do

    before do
      initialize_sysconfig
    end

    it "succeeds with correctly defined values" do
      load_sample :network_config do
        sysconfig.Import(autoyast_profile(:name => 'FIREWALL', :value => 'no'))
        sysconfig.Modified.must_equal true
      end
    end

    it "succeeds with incorrectly defined values" do
      load_sample :network_config do
        sysconfig.Import(autoyast_profile(:name => 'FIREBALL', :value => 'abcdefgh'))
        sysconfig.Modified.must_equal true
      end
    end

    it "succeeds even with totally random defined variable names and values" do
      load_sample :network_config do
        profile_values = [{
          'not_expected_key'   => rand(88888),
          'not_expected_value' => rand(88888),
          'not_expected_path'  => rand(88888)
        }]
        sysconfig.Import(profile_values).must_equal true
        sysconfig.Modified.must_equal true
      end
    end
  end

  describe "When exporting autoyast profile" do
    before do
      initialize_sysconfig
    end

    it "succeeds with correctly defined values" do
      load_sample :network_config do
        var_name  = 'NOZEROCONF'
        var_value = 'yes'
        sysconfig.Import(autoyast_profile(:name => var_name, :value => var_value))
        sysconfig.Modified.must_equal true
        sysconfig.Export.wont_be_empty
        sysconfig.Export.first['sysconfig_key'].wont_be_empty
        sysconfig.Export.first['sysconfig_value'].wont_be_empty
        sysconfig.Export.first['sysconfig_path'].wont_be_empty
        sysconfig.Export.first['sysconfig_path'].must_equal(sample_path)
        sysconfig.Export.first['sysconfig_key'].must_equal(var_name)
        sysconfig.Export.first['sysconfig_value'].must_equal(var_value)
      end
    end

    it "succeeds with incorrectly defined values" do
      load_sample :network_config do
        var_name  = 'DEBUG'
        var_value = 'NOWAYTHISCORRECTVALUE'
        sysconfig.Import(autoyast_profile(:name => var_name, :value => var_value))
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

    it "succeeds even with totally random defined variable names and values" do
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
        sysconfig.Export.first['not_expected_key'].must_be_nil
        sysconfig.Export.first['sysconfig_value'].must_be_empty
        sysconfig.Export.first['not_expected_value'].must_be_nil
        sysconfig.Export.first['sysconfig_path'].wont_be_empty # default value is set
        sysconfig.Export.first['not_expected_path'].must_be_nil
      end
    end
  end
end
