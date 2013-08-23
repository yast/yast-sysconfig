require_relative 'test_helper'

include TestHelpers

describe "When we want to view or edit config files" do
  before do
    initialize_sysconfig
    load_sample_file(:all)
  end

  after do
    sweep_sample_file(:all)
  end

  it "will load the content of the files" do
    sysconfig.instance_variable_get(:@variable_locations).must_be_empty
    success = sysconfig.Read
    success.must_equal true
    paths = sysconfig.instance_variable_get(:@variable_locations).keys.map do |vars|
      vars.split('$').last
    end.uniq
    paths.all? {|p| sample_files.index(p) }.must_equal(true)
    sysconfig.Modified.must_equal false
  end
end
