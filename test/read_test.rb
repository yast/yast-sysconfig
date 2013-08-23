require_relative 'test_helper'

include TestHelpers

describe "When we want to view or edit config files" do
  before do
    initialize_sysconfig
  end

  it "will load all given files" do
    sysconfig.configfiles.must_be_empty
    load_sample_file(:all)
    sysconfig.Read.must_equal(true)
    sysconfig.configfiles.all? {|f| sample_files.index(f) }.must_equal(true)
    sysconfig.Modified.must_equal false
    sweep_sample_file(:all)
  end

  it "will load the content of the expected config variable" do
    load_sample :postfix do
      var_name = 'POSTFIX_SMTP_AUTH'
      sysconfig.Read
      var_value = get_value(var_name)
      var_value.wont_be_empty
      get_config_metadata(var_name,:postfix)['Type'].must_match /#{var_value}/
    end
  end
end
