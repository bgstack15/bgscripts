# ref: http://www.rpm.org/max-rpm/s1-rpm-build-creating-spec-file.html
Summary:	bgscripts gui components
Name:		bgscripts
Version:	1.3
Release:	3
License:	CC BY-SA 4.0
Group:		Applications/System
Source:		bgscripts.tgz
URL:		https://bgstack15.wordpress.com/
#Distribution:
#Vendor:
Packager:	B Stack <bgstack15@gmail.com>
Requires:	%{name}-core >= %{version}-%{release}
Recommends:	freerdp, zenity
Buildarch:	noarch
Provides:	application(rdp.desktop)
Provides:	mimehandler(application/x-rdp)

%package core
Summary:	bgscripts core components
Requires(pre):	/usr/bin/python3
Requires:	bash-completion
BuildRequires:	systemd
Obsoletes:	%{name} < 1.1-31
Recommends:	%{name}, expect

%description core
bgscripts-core is is the cli components of the bgscripts suite.
Bgscripts provides helpful scripts that sysadmins could find useful.
The most important ones include:
bup ctee dli lecho newscript updateval framework dnskeepalive

Also included is "bp" which is a symlink to bgscripts.bashrc

%global _python_bytecompile_errors_terminate_build 0

%description
bgscripts is the gui components of the bgscripts suite, including rdp.sh.

%prep
%setup

%build

%install
rm -rf %{buildroot}
rsync -a . %{buildroot}/ --exclude='**/.*.swp' --exclude='**/.git'

%clean
rm -rf %{buildroot}

%post
# rpm post 2017-09-16
# Deploy icons
which xdg-icon-resource 1>/dev/null 2>&1 && {

   # Deploy default application icons
   for theme in hicolor locolor Numix-Circle Lubuntu;
   do
      shape=square
      case "${theme}" in Numix-Circle) shape=circle;; Lubuntu) shape=Lubuntu;; esac

      # Deploy scalable application icons
      cp -p %{_datarootdir}/%{name}/gui/icons/apps/rdp-${shape}.svg %{_datarootdir}/icons/${theme}/scalable/apps/rdp.svg

      # Deploy size application icons
      for size in 16 24 32 48 64;
      do
         xdg-icon-resource install --context apps --size "${size}" --theme "${theme}" --novendor --noupdate %{_datarootdir}/%{name}/gui/icons/apps/rdp-${shape}-${size}.png rdp &
      done
   done

   # Deploy custom application icons
   # custom: Numix-Circle apps 48 uses svg
   cp -p %{_datarootdir}/%{name}/gui/icons/apps/rdp-circle.svg %{_datarootdir}/icons/Numix-Circle/48/apps/rdp.svg
   ## custom: Lubuntu has a different directory structure and may not work in the normal way.
   #for size in 16 24 32 48 64; do cp -p "%{_datarootdir}/%{name}/gui/icons/apps/rdp-Lubuntu-${size}.png" "${_datarootdir}/icons/Lubuntu/apps/${size}/rdp.png"; done

   # Deploy default mimetype icons
   for theme in hicolor Numix Lubuntu elementary-xfce;
   do

      # Deploy scalable mimetype icons
      cp -p %{_datarootdir}/%{name}/gui/icons/mimetypes/application-x-rdp-${theme}.svg %{_datarootdir}/icons/${theme}/scalable/mimetypes/application-x-rdp.svg

      # Deploy size mimetype icons
      for size in 16 24 32 48 64;
      do
         xdg-icon-resource install --context mimetypes --size "${size}" --theme "${theme}" --novendor --noupdate %{_datarootdir}/%{name}/gui/icons/mimetypes/application-x-rdp-${theme}-${size}.png application-x-rdp &
      done

   done

   # Deploy custom mimetype icons
   # custom: Numix
   cp -p %{_datarootdir}/%{name}/gui/icons/mimetypes/application-x-rdp-Numix.svg %{_datarootdir}/icons/Numix/48/mimetypes/application-x-rdp.svg

   # Update icon caches
   xdg-icon-resource forceupdate &
   for word in hicolor locolor Numix-Circle Numix Lubuntu elementary-xfce;
   do
      touch --no-create %{_datarootdir}/icons/${word}
      gtk-update-icon-cache %{_datarootdir}/icons/${word} &
   done

} 1>/dev/null 2>&1 &

# Deploy desktop files
{

   # rdp application
   desktop-file-install --rebuild-mime-info-cache %{_datarootdir}/%{name}/gui/rdp.desktop

   # resize utility
   if { which virt-what && test -n "$( virt-what )"; } || test -f /usr/bin/spice-vdagent;
   then
      desktop-file-install %{_datarootdir}/%{name}/gui/resize.desktop
   fi

} 1>/dev/null 2>&1 &

# Add mimetype and set default application
for user in root ${SUDO_USER} Bgirton bgirton bgirton-local;
do
{
   ! getent passwd "${user}" && continue
   while read line;
   do
      which xdg-mime && {
         su "${user}" -c "xdg-mime install %{_datarootdir}/%{name}/gui/x-rdp.xml &"
         su "${user}" -c "xdg-mime default rdp.desktop ${line} &"
      }
      which gio && {
         su "${user}" -c "gio mime ${line} rdp.desktop &"
      }
      which update-mime-database && {
         case "${user}" in
            root) update-mime-database %{_datarootdir}/mime & ;;
            *) su "${user}" -c "update-mime-database ~${user}/.local/share/mime &";;
         esac
      }
   done <<'EOW'
application/x-rdp
EOW
} 1>/dev/null 2>&1 &
done

# deploy systemd files
{
if test "$1" -ge 1;
then
   # Initial installation

   if test "$( ps --no-headers -o comm 1 )" = "systemd";
   then
      install -m 0644 -o root -p -t "%{_unitdir}" "%{_datarootdir}/%{name}/inc/systemd/monitor-resize.service" || :
      install -m 0644 -o root -p -t "%{_presetdir}" "%{_datarootdir}/%{name}/inc/systemd/80-monitor-resize.preset" || :
      __thisfunction() {
         systemctl daemon-reload; systemctl --no-reload preset monitor-resize.service;
      }
      __thisfunction &
   fi

fi
} 1>/dev/null 2>&1 &
exit 0

%preun
# rpm preun 2017-09-16
{
if test "$1" = "0";
then
   # total uninstall

   # Remove mimetype definitions
   for user in root ${SUDO_USER} Bgirton bgirton bgirton-local;
   do
      getent passwd "${user}" && which xdg-mime && {
         su "${user}" -c "xdg-mime uninstall %{_datarootdir}/%{name}/gui/x-rdp.xml &"
      }
   done

   # remove systemd files
   systemctl --no-reload disable --now monitor-resize.service || :
   rm -f %{_unitdir}/monitor-resize.service || :
   rm -f %{_presetdir}/80-monitor-resize.preset || :

fi
} 1>/dev/null 2>&1 &
exit 0

%postun
# rpm postun 2017-09-16
if test "$1" = "0";
then
{
   # total uninstall

   # Remove desktop files
   rm -f %{_datarootdir}/applications/rdp.desktop %{_datarootdir}/applications/resize.desktop
   which update-desktop-database && update-desktop-database -q %{_datarootdir}/applications &
   
   # Remove icons
   which xdg-icon-resource && {

      # Remove default application icons
      for theme in hicolor locolor Numix-Circle Lubuntu;
      do

         # Remove scalable application icons
         rm -f %{_datarootdir}/icons/${theme}/scalable/apps/rdp.svg

         # Remove size application icons
         for size in 16 24 32 48 64;
         do
            xdg-icon-resource uninstall --context apps --size "${size}" --theme "${theme}" --noupdate rdp &
         done

      done

      # Remove custom application icons
      # custom: Numix-Circle apps 48 uses svg
      rm -f %{_datarootdir}/icons/Numix-Circle/48/apps/rdp.svg
      # custom: Lubuntu
      #for size in 16 24 32 48 64; do rm -f "%{_datarootdir}/icons/Lubuntu/apps/${size}/rdp.png"; done

      # Remove default mimetype icons
      for theme in hicolor Numix Lubuntu elementary-xfce;
      do

         # Remove scalable mimetype icons
         rm -f %{_datarootdir}/icons/${theme}/scalable/mimetypes/application-x-rdp.svg

         # Remove size mimetype icons
         for size in 16 24 32 48 64;
         do
            xdg-icon-resource uninstall --context mimetypes --size "${size}" --theme "${theme}" --noupdate application-x-rdp &
         done

      done

      # Remove custom mimetype icons
      # custom: Numix
      rm -f %{_datarootdir}/icons/Numix/48/mimetypes/application-x-rdp.svg

      # Update icon caches
      xdg-icon-resource forceupdate &
      for word in hicolor locolor Numix-Circle Numix Lubuntu elementary-xfce;
      do
         touch --no-create %{_datarootdir}/icons/${word}
         gtk-update-icon-cache %{_datarootdir}/icons/${word} &
      done

   }
} 1>/dev/null 2>&1 &
fi

{
if test "$1" -ge 1;
then
   # Package upgrade, not uninstall
   systemctl try-restart monitor-resize.service || :
fi
} 1>/dev/null 2>&1
exit 0

%post core
# rpm core post 2018-01-28
# References:
#    https://fedoraproject.org/wiki/Packaging:Scriptlets
#    https://fedoraproject.org/wiki/Changes/systemd_file_triggers
#    https://superuser.com/questions/1017959/how-to-know-if-i-am-using-systemd-on-my-linux
#    rpmrebuild -e ntp
{
if test "$1" -ge 1;
then
   # Initial installation
   if test "$( ps --no-headers -o comm 1 )" = "systemd";
   then
      install -m 0644 -o root -p -t "%{_unitdir}" "%{_datarootdir}/%{name}/inc/systemd/dnskeepalive.service" || :
      install -m 0644 -o root -p -t "%{_presetdir}" "%{_datarootdir}/%{name}/inc/systemd/80-dnskeepalive.preset" || :
      __thisfunction() {
         systemctl daemon-reload; systemctl --no-reload preset dnskeepalive.service;
      }
      __thisfunction &
   fi

fi
} 1>/dev/null 2>&1

# Prepare the python symlinks
%{_datarootdir}/%{name}/py/switchpyver.sh 1>/dev/null 2>&1 ||:

exit 0

%preun core
# rpm core preun 2017-06-08
{
if test "$1" -eq 0;
then
   # total uninstall

   # remove systemd files
   systemctl --no-reload disable --now dnskeepalive.service || :
   rm -f %{_unitdir}/dnskeepalive.service || :
   rm -f %{_presetdir}/80-dnskeepalive.preset || :

fi
} 1>/dev/null 2>&1
exit 0

%postun core
# rpm core postun 2017-09-16
{
if test "$1" -ge 1;
then
   # Package upgrade, not uninstall
   systemctl try-restart dnskeepalive.service || :
fi
} 1>/dev/null 2>&1
exit 0

%files
%dir /usr/share/bgscripts/gui
%dir /usr/share/bgscripts/gui/icons
%dir /usr/share/bgscripts/gui/icons/apps
%dir /usr/share/bgscripts/gui/icons/mimetypes
%config %attr(666, -, -) /etc/bgscripts/rdp.conf
%config %attr(666, -, -) /etc/bgscripts/monitor-resize.conf
/usr/share/bgscripts/inc/systemd/80-monitor-resize.preset
/usr/share/bgscripts/inc/systemd/monitor-resize.service
/usr/share/bgscripts/build/get-files
/usr/share/bgscripts/gui/screensize.sh
/usr/share/bgscripts/gui/rdp.desktop
/usr/share/bgscripts/gui/resize.sh
/usr/share/bgscripts/gui/icons/generate-icons.sh
/usr/share/bgscripts/gui/icons/apps/rdp-square-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear.svg
/usr/share/bgscripts/gui/icons/apps/rdp-circle-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-square.svg
/usr/share/bgscripts/gui/icons/apps/rdp-square-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu.svg
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-32.png
/usr/share/bgscripts/gui/monitor-resize.sh
/usr/share/bgscripts/gui/x-rdp.xml
/usr/share/bgscripts/gui/rdp.sh
/usr/share/bgscripts/gui/hwset.sh
/usr/share/bgscripts/gui/resize.desktop
/usr/share/bgscripts/gui/mp4tomp3.sh
%verify(link) /usr/bin/rdp

%files core
%dir /etc/bgscripts
%dir /usr/share/bgscripts
%dir /usr/share/bgscripts/examples
%dir /usr/share/bgscripts/inc
%dir /usr/share/bgscripts/inc/systemd
%dir /usr/share/bgscripts/build
%dir /usr/share/bgscripts/build/testing
%dir /usr/share/bgscripts/build/testing/debian
%dir /usr/share/bgscripts/build/debian-bgscripts-core
%dir /usr/share/bgscripts/build/debian-bgscripts
%dir /usr/share/bgscripts/bashrc.d
%dir /usr/share/bgscripts/work
%dir /usr/share/bgscripts/py
%dir /usr/share/bgscripts/py/__pycache__
%attr(440, root, root) /etc/sudoers.d/10_bgstack15
%config %attr(666, -, -) /etc/bgscripts/dnskeepalive.conf
/etc/sysconfig/dnskeepalive
/usr/share/bgscripts/host-bup.sh
/usr/share/bgscripts/newscript.sh
/usr/share/bgscripts/beep.sh
/usr/share/bgscripts/examples/shares-keepalive.cron
%config %attr(666, -, -) /usr/share/bgscripts/examples/host-bup.conf.example
/usr/share/bgscripts/sizer.sh
/usr/share/bgscripts/inc/systemd/80-dnskeepalive.preset
/usr/share/bgscripts/inc/systemd/dnskeepalive.service
/usr/share/bgscripts/changelog.sh
/usr/share/bgscripts/build/testing/debian/control
%doc %attr(444, -, -) /usr/share/bgscripts/build/testing/debian/debian.txt
/usr/share/bgscripts/build/localize_git.sh
/usr/share/bgscripts/build/pack
%doc %attr(444, -, -) /usr/share/bgscripts/build/files-for-versioning.txt
/usr/share/bgscripts/build/bgscripts.spec
/usr/share/bgscripts/build/get-files-core
/usr/share/bgscripts/build/debian-bgscripts-core/rules
/usr/share/bgscripts/build/debian-bgscripts-core/compat
/usr/share/bgscripts/build/debian-bgscripts-core/conffiles
/usr/share/bgscripts/build/debian-bgscripts-core/control
/usr/share/bgscripts/build/debian-bgscripts-core/changelog
/usr/share/bgscripts/build/debian-bgscripts-core/postrm
/usr/share/bgscripts/build/debian-bgscripts-core/md5sums
/usr/share/bgscripts/build/debian-bgscripts-core/postinst
/usr/share/bgscripts/build/debian-bgscripts-core/preinst
/usr/share/bgscripts/build/debian-bgscripts-core/prerm
/usr/share/bgscripts/build/debian-bgscripts/rules
/usr/share/bgscripts/build/debian-bgscripts/compat
/usr/share/bgscripts/build/debian-bgscripts/conffiles
/usr/share/bgscripts/build/debian-bgscripts/control
/usr/share/bgscripts/build/debian-bgscripts/changelog
/usr/share/bgscripts/build/debian-bgscripts/postrm
/usr/share/bgscripts/build/debian-bgscripts/md5sums
/usr/share/bgscripts/build/debian-bgscripts/postinst
/usr/share/bgscripts/build/debian-bgscripts/preinst
/usr/share/bgscripts/build/debian-bgscripts/prerm
%doc %attr(444, -, -) /usr/share/bgscripts/build/scrub.txt
/usr/share/bgscripts/bashrc.d/debian.bashrc
/usr/share/bgscripts/bashrc.d/rhel.bashrc
/usr/share/bgscripts/bashrc.d/fedora.bashrc
/usr/share/bgscripts/bashrc.d/korora.bashrc
/usr/share/bgscripts/bashrc.d/GENERIC.bashrc
/usr/share/bgscripts/bashrc.d/centos.bashrc
/usr/share/bgscripts/bashrc.d/devuan.bashrc
/usr/share/bgscripts/bashrc.d/ubuntu.bashrc
/usr/share/bgscripts/title.sh
/usr/share/bgscripts/lecho.sh
/usr/share/bgscripts/work/list-vnc-sessions.sh
/usr/share/bgscripts/work/sslscanner.sh
/usr/share/bgscripts/work/userinfo.sh
/usr/share/bgscripts/work/list-active-repos.sh
/usr/share/bgscripts/ctee.sh
/usr/share/bgscripts/fl.sh
/usr/share/bgscripts/py/bgs.py
/usr/share/bgscripts/py/bgs.pyc
/usr/share/bgscripts/py/bgs.pyo
/usr/share/bgscripts/py/uvlib.py3
/usr/share/bgscripts/py/__pycache__/bgs.cpython-36.pyc
/usr/share/bgscripts/py/__pycache__/uvlib.cpython-36.pyc
/usr/share/bgscripts/py/dli.py
/usr/share/bgscripts/py/dli.pyc
/usr/share/bgscripts/py/dli.pyo
/usr/share/bgscripts/py/scrub.py
/usr/share/bgscripts/py/scrub.pyc
/usr/share/bgscripts/py/scrub.pyo
/usr/share/bgscripts/py/switchpyver.sh
/usr/share/bgscripts/py/uvlib.py
/usr/share/bgscripts/py/uvlib.pyc
/usr/share/bgscripts/py/uvlib.pyo
/usr/share/bgscripts/py/modconf.py
/usr/share/bgscripts/py/modconf.pyc
/usr/share/bgscripts/py/modconf.pyo
/usr/share/bgscripts/py/uvlib.py2
/usr/share/bgscripts/py/pwhashgen.py
/usr/share/bgscripts/py/pwhashgen.pyc
/usr/share/bgscripts/py/pwhashgen.pyo
/usr/share/bgscripts/py/updateval.py
/usr/share/bgscripts/py/updateval.pyc
/usr/share/bgscripts/py/updateval.pyo
/usr/share/bgscripts/bounce.sh
/usr/share/bgscripts/framework.sh
/usr/share/bgscripts/dnskeepalive.sh
/usr/share/bgscripts/toucher.sh
/usr/share/bgscripts/shares.sh
/usr/share/bgscripts/ftemplate.sh
/usr/share/bgscripts/send.sh
/usr/share/bgscripts/plecho.sh
/usr/share/bgscripts/bup.sh
/usr/share/bgscripts/bgscripts.bashrc
/usr/share/bgscripts/doc
%doc %attr(444, -, -) /usr/share/doc/bgscripts/version.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/README.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/FRAMEWORK.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-PYTHON.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS-SHELL.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/packaging.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/BGSCRIPTS-BASHRC.txt
%verify(link) /usr/bin/updateval
%verify(link) /usr/bin/toucher
%verify(link) /usr/bin/title
%verify(link) /usr/bin/fl
%verify(link) /usr/bin/lecho
%verify(link) /usr/bin/bounce
%verify(link) /usr/bin/newscript
%verify(link) /usr/bin/plecho
%verify(link) /usr/bin/dnskeepalive
%verify(link) /usr/bin/shares
%verify(link) /usr/bin/send
%verify(link) /usr/bin/bup
%verify(link) /usr/bin/beep
%verify(link) /usr/bin/bp
%verify(link) /usr/bin/ctee
%verify(link) /usr/bin/dli

%changelog
* Fri Feb 23 2018 B Stack <bgstack15@gmail.com> 1.3-3
- Update content. See doc/README.txt.
