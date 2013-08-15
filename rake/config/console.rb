module Yast::Rake::Config
  module Console
    def proc
      Proc.new do
        require 'yast'
        ::Yast.add_module_path(rake.config.root.join('src', 'modules').to_path)
        ::Yast.import 'Sysconfig'
      end
    end
  end

  register Console
end
