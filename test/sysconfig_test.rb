#!/usr/bin/env rspec

require_relative 'test_helper'
require "yast2/systemd/service"

Yast.import "Sysconfig"

describe Yast::Sysconfig do
  subject(:sysconfig) do
    new_sysconfig(configfiles)
  end
  let(:configfiles) { ["#{DATA_PATH}/sysconfig/*"] }

  describe ".Read" do
    let(:configfiles) do
      [
        "#{DATA_PATH}/sysconfig/*",
        "#{DATA_PATH}/sysconfig/network/*"
      ]
    end

    it "returns true on success" do
      expect(sysconfig.Read).to eq true
    end

    it "leaves the Modified flag untouched" do
      sysconfig.Read
      expect(sysconfig.Modified).to eq false
    end

    it "reads the content of all the files" do
      sysconfig.Read

      postfix_auth = sysconfig.get_description("POSTFIX_SMTP_AUTH$#{DATA_PATH}/sysconfig/postfix")
      expect(postfix_auth["location"]).to eq "Network/Mail/Postfix"
      expect(postfix_auth["Type"]).to eq "yesno"

      yast_shell = sysconfig.get_description("WANTED_SHELL$#{DATA_PATH}/sysconfig/yast2")
      expect(yast_shell["Default"]).to eq "auto"
      expect(yast_shell["value"]).to eq "qt"

      pre_down = sysconfig.get_description("GLOBAL_PRE_DOWN_EXEC$#{DATA_PATH}/sysconfig/network/config")
      expect(pre_down["comment"]).to start_with " sometimes we want some script"

      write_hostname = sysconfig.get_description("WRITE_HOSTNAME_TO_HOSTS$#{DATA_PATH}/sysconfig/network/dhcp")
      expect(write_hostname["ServiceRestart"]).to eq "yast2"
    end
  end

  describe ".set_value" do
    let(:configfiles) { ["#{DATA_PATH}/sysconfig/*"] }

    before { sysconfig.Read }

    context "with default behavior" do
      let(:force) { false }
      let(:force_change) { false }

      context "with an existing variable" do
        let(:var) { "USE_SNAPPER" }
        let(:var_id) { "USE_SNAPPER$#{DATA_PATH}/sysconfig/yast2" }
        let(:read_value) { "no" }
        let(:another_value) { "yes" }
        let(:invalid_value) { "Not today, thanks" }

        it "does not change the current stored value" do
          sysconfig.set_value(var_id, another_value, force, force_change)
          expect(var_value(var_id, sysconfig)).to eq read_value
        end

        it "returns :ok for valid values" do
          res = sysconfig.set_value(var_id, read_value, force, force_change)
          expect(res).to eq :ok
          res = sysconfig.set_value(var_id, another_value, force, force_change)
          expect(res).to eq :ok
        end

        it "does not schedule the modification if the value does not change" do
          sysconfig.set_value(var_id, read_value, force, force_change)
          expect(sysconfig.Modified).to eq false
          expect(sysconfig.Summary).to_not match /#{var}/
          expect(sysconfig.modified(var_id)).to eq false
        end

        it "schedules the modification if the new value is different" do
          sysconfig.set_value(var_id, another_value, force, force_change)
          expect(sysconfig.Modified).to eq true
          expect(sysconfig.Summary).to match /#{var}="#{another_value}"/
          expect(sysconfig.modified(var_id)).to eq true
        end

        it "removes the scheduled modification if the original value is restored" do
          sysconfig.set_value(var_id, another_value, force, force_change)
          sysconfig.set_value(var_id, read_value, force, force_change)
          expect(sysconfig.Modified).to eq false
          expect(sysconfig.Summary).to_not match /#{var}/
          expect(sysconfig.modified(var_id)).to eq false
        end

        it "returns :not_valid for invalid values" do
          res = sysconfig.set_value(var_id, invalid_value, force, force_change)
          expect(res).to eq :not_valid
        end

        it "does not schedule the modification if the value is invalid" do
          sysconfig.set_value(var_id, invalid_value, force, force_change)
          expect(sysconfig.Modified).to eq false
          expect(sysconfig.Summary).to_not match /#{var}/
          expect(sysconfig.modified(var_id)).to eq false
        end
      end

      # The old (minitest) test suite 'ensured' that unknown variables were
      # ignored. But the current implementation actually schedule the
      # modification, so the test suite was totally ineffective.
      # I don't know if the expected behaviour is the one that is actually
      # implemented (reflected in this test suite) or the one that the old
      # testsuite was trying to ensure with no success.
      context "with an unknown variable" do
        let(:var) { "GMAIL_LISTEN" }
        let(:var_id) { "GMAIL_LISTEN$#{DATA_PATH}/sysconfig/postfix" }
        let(:value) { "yeees" }

        it "returns :ok" do
          res = sysconfig.set_value(var_id, value, force, force_change)
          expect(res).to eq :ok
        end

        it "schedules the modification" do
          sysconfig.set_value(var_id, value, force, force_change)
          expect(sysconfig.Modified).to eq true
          expect(sysconfig.Summary).to match /#{var}="#{value}"/
          expect(sysconfig.modified(var_id)).to eq true
        end
      end
    end
  end

  describe ".Write" do
    let(:postfix_file) { "#{DATA_PATH}/sysconfig/postfix" }
    let(:configfiles) { [postfix_file] }

    # No after-save action
    let(:myhostname_var) { "POSTFIX_MYHOSTNAME" }
    let(:myhostname_var_id) { "#{myhostname_var}$#{postfix_file}" }
    let(:myhostname_value) { "suse.cz" }

    # ServiceRestart
    let(:nullclient_var) { "POSTFIX_NULLCLIENT" }
    let(:nullclient_var_id) { "#{nullclient_var}$#{postfix_file}" }
    let(:nullclient_value) { "yes" }

    # Command
    let(:listen_var) { "POSTFIX_LISTEN" }
    let(:listen_var_id) { "#{listen_var}$#{postfix_file}" }
    let(:listen_value) { "eth0" }

    # ServiceReload
    let(:nodns_var) { "POSTFIX_NODNS" }
    let(:nodns_var_id) { "#{nodns_var}$#{postfix_file}" }
    let(:nodns_value) { "yes" }

    before { sysconfig.Read }

    it "writes all the modified values" do
      # This methods are private
      # Mocking them is not very robust, but is clear and simple
      allow(sysconfig).to receive(:exec_action)
      allow(sysconfig).to receive(:service_active?).and_return true

      expect(Yast::SCR).to receive(:Write)
        .with(path(".syseditor.value.#{postfix_file}.#{myhostname_var}"), myhostname_value)
      expect(Yast::SCR).to receive(:Write)
        .with(path(".syseditor.value.#{postfix_file}.#{nullclient_var}"), nullclient_value)
      # Flush
      expect(Yast::SCR).to receive(:Write).with(path(".syseditor"), nil)

      sysconfig.set_value(myhostname_var_id, myhostname_value, false, false)
      sysconfig.set_value(nullclient_var_id, nullclient_value, false, false)
      sysconfig.Write
    end

    it "restarts associated services" do
      allow(Yast::SCR).to receive(:Write).with(path_matching(/^\.syseditor/), anything)

      service = double("postfix_service")
      allow(Yast2::Systemd::Service).to receive(:find).with("postfix").and_return service
      expect(service).to receive(:active?).and_return true
      expect(service).to receive(:restart)

      sysconfig.set_value(nullclient_var_id, nullclient_value, false, false)
      sysconfig.Write
    end

    it "reloads associated services" do
      allow(Yast::SCR).to receive(:Write).with(path_matching(/^\.syseditor/), anything)

      service = double("postfix_service")
      allow(Yast2::Systemd::Service).to receive(:find).with("postfix").and_return service
      expect(service).to receive(:active?).and_return true
      expect(service).to receive(:reload)

      sysconfig.set_value(nodns_var_id, nodns_value, false, false)
      sysconfig.Write
    end

    it "runs associated commands" do
      allow(Yast::SCR).to receive(:Write).with(path_matching(/^\.syseditor/), anything)
      expect(Yast::SCR).to receive(:Execute)
        .with(path(".target.bash_output"), /echo example command/)
        .and_return({"exit" => 0, "stdout" => "", "stderr" => ""})

      sysconfig.set_value(listen_var_id, listen_value, false, false)
      sysconfig.Write
    end
  end

  describe ".remove_whitespaces" do
    it "returns nil if nil is passed" do
      expect(sysconfig.remove_whitespaces(nil)).to eq nil
    end

    it "returns empty string for string containing only whitespaces" do
      ["", "     ", "\t"].each do |v|
        expect(sysconfig.remove_whitespaces(v)).to eq ""
      end
    end

    it "returns stripped string for others" do
      ["var", "  var", "var\t", "\tvar   "].each do |v|
        expect(sysconfig.remove_whitespaces(v)).to eq "var"
      end
    end
  end
end
