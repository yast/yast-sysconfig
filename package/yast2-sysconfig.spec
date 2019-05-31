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

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           yast2-sysconfig
Summary:        YaST2 - Sysconfig Editor
Version:        4.1.2
Release:        0
Url:            https://github.com/yast/yast-sysconfig
Group:          System/YaST
License:        GPL-2.0-or-later

Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  perl-XML-Writer update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
# path_matching (RSpec argument matcher)
BuildRequires:  yast2-ruby-bindings >= 3.1.31
# For tests
BuildRequires: ruby

Requires:       perl
# Yast2::Systemd::Service
Requires:       yast2 >= 4.1.3
Requires:       yast2-ruby-bindings >= 1.0.0

Provides:       y2c_rc_config yast2-config-rcconfig yast2-config-sysconfig
Provides:       yast2-trans-sysconfig yast2-trans-rcconfig y2t_rc_config

Obsoletes:      y2c_rc_config yast2-config-rcconfig yast2-config-sysconfig
Obsoletes:      yast2-trans-sysconfig yast2-trans-rcconfig y2t_rc_config
Obsoletes:      yast2-sysconfig-devel-doc

BuildArch:      noarch

%description
A graphical /etc/sysconfig/* editor with integrated search and context
information.

%prep
%setup -q

%build
%yast_build

%install
%yast_install
%yast_metainfo

%files
%{yast_yncludedir}
%{yast_clientdir}
%{yast_clientdir}
%{yast_moduledir}
%{yast_desktopdir}
%{yast_metainfodir}
%{yast_ybindir}
%{yast_ydatadir}
%{yast_ydatadir}
%{yast_schemadir}
%{yast_icondir}
%license COPYING
%doc %{yast_docdir}
