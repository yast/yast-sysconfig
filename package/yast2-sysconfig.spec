#
# spec file for package yast2-sysconfig
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-sysconfig
Version:        4.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0+
BuildRequires:	perl-XML-Writer update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
# path_matching (RSpec argument matcher)
BuildRequires:  yast2-ruby-bindings >= 3.1.31
Requires:	perl
Requires:	yast2 >= 2.21.22

# For tests
BuildRequires: ruby

BuildArchitectures:	noarch

Provides:	y2c_rc_config yast2-config-rcconfig yast2-config-sysconfig
Obsoletes:	y2c_rc_config yast2-config-rcconfig yast2-config-sysconfig
Provides:	yast2-trans-sysconfig yast2-trans-rcconfig y2t_rc_config
Obsoletes:	yast2-trans-sysconfig yast2-trans-rcconfig y2t_rc_config
Obsoletes:	yast2-sysconfig-devel-doc

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Sysconfig Editor

%description
A graphical /etc/sysconfig/* editor with integrated search and context
information.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/sysconfig
%{yast_yncludedir}/sysconfig/*
%{yast_clientdir}/sysconfig.rb
%{yast_clientdir}/sysconfig_*.rb
%{yast_moduledir}/Sysconfig.rb
%{yast_desktopdir}/sysconfig.desktop
%{yast_ybindir}/parse_configs.pl
%{yast_ydatadir}/sysedit.agent
%{yast_ydatadir}/descriptions
%{yast_schemadir}/autoyast/rnc/sysconfig.rnc
%dir %{yast_docdir}
%doc %{yast_docdir}/COPYING
%doc %{yast_docdir}/metadata.txt
