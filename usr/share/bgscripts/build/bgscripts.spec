%define devtty "/dev/null"
Summary:	   bgscripts gui components
Name:		   bgscripts
Version:	   1.3
Release:	   6
License:	   CC BY-SA 4.0
Group:      Applications/System
Source:     bgscripts.tgz
URL:        https://bgstack15.wordpress.com/
#Distribution:
#Vendor:
Packager:   B Stack <bgstack15@gmail.com>
Requires:   %{name}-core >= %{version}-%{release}
Buildarch:	noarch
Provides:	application(rdp.desktop)
Provides:	mimehandler(application/x-rdp)

%package core
Summary:       bgscripts core components
#Requires(pre): /usr/bin/python3
Requires:   	bash-completion
BuildRequires: systemd
Obsoletes:     %{name} < 1.1-31

%description core
bgscripts-core is is the cli components of the bgscripts suite.
Bgscripts provides helpful scripts that sysadmins could find useful.
The most important ones include:
bup ctee dli lecho newscript updateval framework dnskeepalive

Also included is "bp" which is a symlink to bgscripts.bashrc

%global _python_bytecompile_errors_terminate_build 0

%description
Not a valid package. Please ignore.

%prep
%setup

%build
# rpm build 2018-02-23
exit 0

%install
# rpm install 2018-02-23
rm -rf %{buildroot}
rsync -a . %{buildroot}/ --exclude='**/.*.swp' --exclude='**/.git'

# Solve the readme problem
find %{buildroot} -maxdepth 1 -name 'README.md' -exec rm -f {} \; 2>%{devtty} || :

exit 0

%clean
rm -rf %{buildroot}

%post
# rpm post 2018-02-23
exit 0

%preun
# rpm preun 2018-02-23
exit 0

%postun
# rpm postun 2018-02-23
exit 0

%post core
# rpm core post 2018-02-23
# References:
#    https://fedoraproject.org/wiki/Packaging:Scriptlets
#    https://fedoraproject.org/wiki/Changes/systemd_file_triggers
#    https://superuser.com/questions/1017959/how-to-know-if-i-am-using-systemd-on-my-linux
#    rpmrebuild -e ntp
{
if test "$1" -ge 1 ;
then
   # Initial installation
   :

fi
} 1>%{devtty} 2>&1

# Prepare the python symlinks
%{_datadir}/%{name}/py/switchpyver.sh 1>%{devtty} 2>&1 ||:

exit 0

%preun core
# rpm core preun 2018-02-23
{
if test "$1" -eq 0 ;
then
   # Total uninstall
   :

fi
} 1>%{devtty} 2>&1

exit 0

%postun core
# rpm core postun 2018-02-23
{
if test "$1" -ge 1 ;
then
   # Package upgrade, not uninstall
   :
fi
} 1>%{devtty} 2>&1

exit 0

%files core
%dir /usr/share/bgscripts
%dir /usr/share/bgscripts/bashrc.d
%dir /usr/share/bgscripts/build
%dir /usr/share/bgscripts/py
%dir /usr/share/bgscripts/work
%verify(link) /usr/bin/beep
%verify(link) /usr/bin/bp
%verify(link) /usr/bin/bup
%verify(link) /usr/bin/ctee
%verify(link) /usr/bin/dli
%verify(link) /usr/bin/fl
%verify(link) /usr/bin/lecho
%verify(link) /usr/bin/newscript
%verify(link) /usr/bin/plecho
%verify(link) /usr/bin/send
%verify(link) /usr/bin/title
%verify(link) /usr/bin/toucher
%verify(link) /usr/bin/updateval
/usr/share/bgscripts/bashrc.d/centos.bashrc
/usr/share/bgscripts/bashrc.d/debian.bashrc
/usr/share/bgscripts/bashrc.d/devuan.bashrc
/usr/share/bgscripts/bashrc.d/fedora.bashrc
/usr/share/bgscripts/bashrc.d/GENERIC.bashrc
/usr/share/bgscripts/bashrc.d/korora.bashrc
/usr/share/bgscripts/bashrc.d/ol.bashrc
/usr/share/bgscripts/bashrc.d/rhel.bashrc
/usr/share/bgscripts/bashrc.d/ubuntu.bashrc
/usr/share/bgscripts/beep.sh
/usr/share/bgscripts/bgscripts.bashrc
/usr/share/bgscripts/build/bgscripts.spec
%doc %attr(444, -, -) /usr/share/bgscripts/build/files-for-versioning.txt
/usr/share/bgscripts/build/get-files-core
/usr/share/bgscripts/build/pack
/usr/share/bgscripts/bup.sh
/usr/share/bgscripts/ctee.sh
/usr/share/bgscripts/doc
/usr/share/bgscripts/enumerate-users.sh
/usr/share/bgscripts/fl.sh
/usr/share/bgscripts/framework.sh
/usr/share/bgscripts/ftemplate.sh
/usr/share/bgscripts/lecho.sh
/usr/share/bgscripts/newscript.sh
/usr/share/bgscripts/plecho.sh
/usr/share/bgscripts/py/bgs.py
/usr/share/bgscripts/py/dli.py
/usr/share/bgscripts/py/modconf.py
/usr/share/bgscripts/py/pwhashgen.py
/usr/share/bgscripts/py/scrub.py
/usr/share/bgscripts/py/switchpyver.sh
/usr/share/bgscripts/py/updateval.py
/usr/share/bgscripts/py/uvlib.py
/usr/share/bgscripts/py/uvlib.py2
/usr/share/bgscripts/py/uvlib.py3
/usr/share/bgscripts/send.sh
/usr/share/bgscripts/sizer.sh
/usr/share/bgscripts/title.sh
/usr/share/bgscripts/toucher.sh
/usr/share/bgscripts/work/cladu.sh
/usr/share/bgscripts/work/list-active-repos.sh
/usr/share/bgscripts/work/list-vnc-sessions.sh
/usr/share/bgscripts/work/sslscanner.sh
/usr/share/bgscripts/work/userinfo.sh
%doc %attr(444, -, -) /usr/share/doc/bgscripts/BGSCRIPTS-BASHRC.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/FRAMEWORK.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/README.md
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-PYTHON.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-SHELL.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/version.txt

%changelog
* Thu Apr 19 2018 B Stack <bgstack15@gmail.com> 1.3-6
- Update content. See doc/README.txt.

%files core
%dir /usr/share/bgscripts
%dir /usr/share/bgscripts/bashrc.d
%dir /usr/share/bgscripts/build
%dir /usr/share/bgscripts/py
%dir /usr/share/bgscripts/work
%verify(link) /usr/bin/beep
%verify(link) /usr/bin/bp
%verify(link) /usr/bin/bup
%verify(link) /usr/bin/ctee
%verify(link) /usr/bin/dli
%verify(link) /usr/bin/fl
%verify(link) /usr/bin/lecho
%verify(link) /usr/bin/newscript
%verify(link) /usr/bin/plecho
%verify(link) /usr/bin/send
%verify(link) /usr/bin/title
%verify(link) /usr/bin/toucher
%verify(link) /usr/bin/updateval
/usr/share/bgscripts/bashrc.d/centos.bashrc
/usr/share/bgscripts/bashrc.d/debian.bashrc
/usr/share/bgscripts/bashrc.d/devuan.bashrc
/usr/share/bgscripts/bashrc.d/fedora.bashrc
/usr/share/bgscripts/bashrc.d/GENERIC.bashrc
/usr/share/bgscripts/bashrc.d/korora.bashrc
/usr/share/bgscripts/bashrc.d/ol.bashrc
/usr/share/bgscripts/bashrc.d/rhel.bashrc
/usr/share/bgscripts/bashrc.d/ubuntu.bashrc
/usr/share/bgscripts/beep.sh
/usr/share/bgscripts/bgscripts.bashrc
/usr/share/bgscripts/build/bgscripts.spec
%doc %attr(444, -, -) /usr/share/bgscripts/build/files-for-versioning.txt
/usr/share/bgscripts/build/get-files-core
/usr/share/bgscripts/build/pack
/usr/share/bgscripts/bup.sh
/usr/share/bgscripts/ctee.sh
/usr/share/bgscripts/doc
/usr/share/bgscripts/enumerate-users.sh
/usr/share/bgscripts/fl.sh
/usr/share/bgscripts/framework.sh
/usr/share/bgscripts/ftemplate.sh
/usr/share/bgscripts/lecho.sh
/usr/share/bgscripts/newscript.sh
/usr/share/bgscripts/plecho.sh
/usr/share/bgscripts/py/bgs.py
/usr/share/bgscripts/py/dli.py
/usr/share/bgscripts/py/modconf.py
/usr/share/bgscripts/py/pwhashgen.py
/usr/share/bgscripts/py/scrub.py
/usr/share/bgscripts/py/switchpyver.sh
/usr/share/bgscripts/py/updateval.py
/usr/share/bgscripts/py/uvlib.py
/usr/share/bgscripts/py/uvlib.py2
/usr/share/bgscripts/py/uvlib.py3
/usr/share/bgscripts/send.sh
/usr/share/bgscripts/sizer.sh
/usr/share/bgscripts/title.sh
/usr/share/bgscripts/toucher.sh
/usr/share/bgscripts/work/allow-group.sh
/usr/share/bgscripts/work/cladu.sh
/usr/share/bgscripts/work/list-active-repos.sh
/usr/share/bgscripts/work/list-vnc-sessions.sh
/usr/share/bgscripts/work/sslscanner.sh
/usr/share/bgscripts/work/userinfo.sh
%doc %attr(444, -, -) /usr/share/doc/bgscripts/BGSCRIPTS-BASHRC.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/FRAMEWORK.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/README.md
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-PYTHON.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-SHELL.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/version.txt

%changelog
* Thu Apr 19 2018 B Stack <bgstack15@gmail.com> 1.3-6
- Update content. See doc/README.txt.
