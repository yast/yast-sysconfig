# Copyright (c) 2015 SUSE Linux.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

# Set the paths
SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")
ENV["Y2DIR"] = SRC_PATH

require "yast"
require "yast/rspec"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  # for coverage we need to load all ruby files
  Dir["#{SRC_PATH}/modules/**/*.rb"].each { |f| require_relative f }

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

# Current value of the variable in the sysconfig object
def var_value(var, sysconfig)
  sysconfig.get_description(var)['value'].to_s
end

# Returns a clean Sysconfig object to make sure that potentially
# problematic operations like .Read don't pollute other examples
def new_sysconfig(configfiles = [])
  clear_sysconfig_cache
  ymodule = Yast::SysconfigClass.new
  ymodule.main
  ymodule.configfiles = configfiles
  ymodule
end

# Sad but true, this is needed to prevent different instances of
# Yast::SysconfigClass to interfere with each other
def clear_sysconfig_cache
  file = Yast::SCR.Read(path(".target.tmpdir")) + "/treedef.ycp"
  File.delete(file) if File.exist?(file)
  Yast::SCR.UnregisterAgent(path(".sysconfig.network.template"))
  Yast::SCR.UnregisterAgent(path(".syseditor"))
end

# Structure of an autoyast entry for the sysconfig module
def autoyast_entry(name, value, path)
  {
    'sysconfig_key'   => name,
    'sysconfig_value' => value,
    'sysconfig_path'  => path
  }
end
