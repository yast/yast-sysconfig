#!/usr/bin/env rspec

require_relative 'test_helper'

Yast.import "Sysconfig"

describe Yast::Sysconfig do
  subject(:sysconfig) do
    new_sysconfig
  end

  describe ".Import" do
    let(:entry_path) { "/etc/sysconfig/network/config" }
    let(:profile) { [autoyast_entry(var, value, entry_path)] }

    before do
      sysconfig.Import(profile)
    end

    context "with a correct profile" do
      let(:var) { "FIREWALL" }
      let(:value) { "no" }

      it "schedules the value change" do
        expect(sysconfig.Summary).to match /#{var}="#{value}"/
        expect(sysconfig.modified("#{var}$#{entry_path}")).to eq true
      end

      it "sets the Modified flag" do
        expect(sysconfig.Modified).to eq true
      end
    end

    context "with a old style profile" do
      let(:var) { "FIREWALL" }
      let(:value) { "no" }
      let(:entry_path) { "network/cfg" }

      it "turns the relative path into absolute" do
        expect(sysconfig.modified("#{var}$#{entry_path}")).to eq false
        expect(sysconfig.modified("#{var}$/etc/sysconfig/#{entry_path}")).to eq true
      end
    end

    context "with a profile with errors" do
      let(:var) { "FIREBALL" }
      let(:value) { "abcde" }

      it "schedules the value change" do
        expect(sysconfig.Summary).to match /#{var}="#{value}"/
        expect(sysconfig.modified("#{var}$#{entry_path}")).to eq true
      end

      it "sets the Modified flag" do
        expect(sysconfig.Modified).to eq true
      end
    end

    context "with numeric random values" do
      let(:var) { rand(8888) }
      let(:value) { rand(8888) }
      let(:entry_path) { rand(8888) }

      it "schedules an invalid value change" do
        expect(sysconfig.Summary).to match /nil="nil"/
        expect(sysconfig.modified("nil$/etc/sysconfig/nil")).to eq true
      end

      it "sets the Modified flag" do
        expect(sysconfig.Modified).to eq true
      end
    end
  end

  describe ".Export" do
    let(:entry_path) { "#{DATA_PATH}/sysconfig/network/config" }

    before do
      sysconfig.configfiles = [entry_path]
      sysconfig.Read
    end

    context "with no modified values" do
      it "returns an empty array" do
        expect(sysconfig.Export).to eq []
      end
    end

    context "with a correctly modified value" do
      let(:var) { "GLOBAL_POST_UP_EXEC" }
      let(:value) { "no" }

      it "returns the corresponding entry" do
        sysconfig.set_value("#{var}$#{entry_path}", value, false, false)
        expect(sysconfig.Export).to eq [autoyast_entry(var, value, entry_path)]
      end
    end

    context "with invalid imported values" do
      let(:var) { "GLOBAL_POST_UP_EXEC" }
      let(:value) { "NoWayThisIsCorrectValue" }

      it "returns an identical entry" do
        sysconfig.Import([autoyast_entry(var, value, entry_path)])
        expect(sysconfig.Export).to eq [autoyast_entry(var, value, entry_path)]
      end
    end

    context "with numeric random imported values" do
      let(:var) { rand(8888) }
      let(:value) { rand(8888) }

      it "returns an invalid entry" do
        sysconfig.Import([autoyast_entry(var, value, entry_path)])
        expect(sysconfig.Export).to eq [autoyast_entry("nil", nil, entry_path)]
      end
    end
  end
end
