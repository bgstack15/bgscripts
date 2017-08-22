# ref: http://www.rpm.org/max-rpm/s1-rpm-build-creating-spec-file.html
Summary:	bgscripts gui components
Name:		bgscripts
Version:	1.2
Release:	17
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
# rpm post 2017-06-08
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

} 1>/dev/null 2>&1

# Deploy desktop files
{

   # rdp application
   desktop-file-install --rebuild-mime-info-cache %{_datarootdir}/%{name}/gui/rdp.desktop

   # resize utility
   if { which virt-what && test -n "$( virt-what )"; } || test -f /usr/bin/spice-vdagent;
   then
      desktop-file-install %{_datarootdir}/%{name}/gui/resize.desktop
   fi

} 1>/dev/null 2>&1

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
} 1>/dev/null 2>&1
done
exit 0

%preun
# rpm preun 2017-03-24
if test "$1" = "0";
then
{
   # total uninstall

   # Remove mimetype definitions
   for user in root ${SUDO_USER} Bgirton bgirton bgirton-local;
   do
      getent passwd "${user}" && which xdg-mime && {
         su "${user}" -c "xdg-mime uninstall %{_datarootdir}/%{name}/gui/x-rdp.xml &"
      }
   done
} 1>/dev/null 2>&1
fi
exit 0

%postun
# rpm postun 2017-03-24
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
} 1>/dev/null 2>&1
fi
exit 0

%post core
# post core 2017-07-11
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
      systemctl daemon-reload &
   fi
   systemctl --no-reload preset dnskeepalive.service || :
fi
} 1>/dev/null 2>&1

%preun core
# preun core 2017-06-08
{
if test "$1" -eq 0;
then
   # Package removal, not upgrade
   systemctl --no-reload disable --now dnskeepalive.service || :
   rm -f %{_unitdir}/dnskeepalive.service || :
   rm -f %{_presetdir}/80-dnskeepalive.preset || :
fi
} 1>/dev/null 2>&1

%postun core
# postun core 2017-04-29
if test "$1" -ge 1;
then
   # Package upgrade, not uninstall
   systemctl try-restart dnskeepalive.service 1>/dev/null 2>&1 || :
fi

%files
%dir /usr/share/bgscripts/gui
%dir /usr/share/bgscripts/gui/icons
%dir /usr/share/bgscripts/gui/icons/apps
%dir /usr/share/bgscripts/gui/icons/mimetypes
%config %attr(666, -, -) /etc/bgscripts/rdp.conf
%verify(link) /usr/bin/rdp
/usr/share/bgscripts/build/get-files
/usr/share/bgscripts/gui/resize.desktop
/usr/share/bgscripts/gui/x-rdp.xml
/usr/share/bgscripts/gui/resize.sh
/usr/share/bgscripts/gui/icons/generate-icons.sh
/usr/share/bgscripts/gui/icons/apps/rdp-square-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle.svg
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-square.svg
/usr/share/bgscripts/gui/icons/apps/rdp-clear-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-24.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-circle-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-48.png
/usr/share/bgscripts/gui/icons/apps/rdp-square-32.png
/usr/share/bgscripts/gui/icons/apps/rdp-Lubuntu.svg
/usr/share/bgscripts/gui/icons/apps/rdp-circle-64.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear.svg
/usr/share/bgscripts/gui/icons/apps/rdp-square-16.png
/usr/share/bgscripts/gui/icons/apps/rdp-clear-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-32.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-24.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-16.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Lubuntu-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor-64.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-Numix-48.png
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-hicolor.svg
/usr/share/bgscripts/gui/icons/mimetypes/application-x-rdp-elementary-xfce-64.png
/usr/share/bgscripts/gui/rdp.sh
/usr/share/bgscripts/gui/rdp.desktop

%files core
%dir /etc/bgscripts
%dir /usr/share/bgscripts
%dir /usr/share/bgscripts/build
%dir /usr/share/bgscripts/build/debian-bgscripts
%dir /usr/share/bgscripts/build/testing
%dir /usr/share/bgscripts/build/testing/debian
%dir /usr/share/bgscripts/build/debian-bgscripts-core
%dir /usr/share/bgscripts/inc
%dir /usr/share/bgscripts/inc/systemd
%dir /usr/share/bgscripts/bashrc.d
%dir /usr/share/bgscripts/examples
%attr(440, root, root) /etc/sudoers.d/10_bgstack15
%config %attr(666, -, -) /etc/bgscripts/dnskeepalive.conf
/etc/sysconfig/dnskeepalive
%verify(link) /usr/bin/title
%verify(link) /usr/bin/bounce
%verify(link) /usr/bin/shares
%verify(link) /usr/bin/beep
%verify(link) /usr/bin/lecho
%verify(link) /usr/bin/ctee
%verify(link) /usr/bin/send
%verify(link) /usr/bin/newscript
%verify(link) /usr/bin/dnskeepalive
%verify(link) /usr/bin/toucher
%verify(link) /usr/bin/plecho
%verify(link) /usr/bin/bup
%verify(link) /usr/bin/bp
%verify(link) /usr/bin/fl
%verify(link) /usr/bin/updateval
%verify(link) /usr/bin/dli
%doc %attr(444, -, -) /usr/share/doc/bgscripts/version.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/BGSCRIPTS-BASHRC.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/packaging.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/SCRIPTS.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/FRAMEWORK.txt
%doc %attr(444, -, -) /usr/share/doc/bgscripts/README.txt
/usr/share/bgscripts/beep.sh
/usr/share/bgscripts/title.sh
/usr/share/bgscripts/ftemplate.sh
/usr/share/bgscripts/dnskeepalive.sh
/usr/share/bgscripts/build/pack
/usr/share/bgscripts/build/localize_git.sh
/usr/share/bgscripts/build/debian-bgscripts/control
/usr/share/bgscripts/build/debian-bgscripts/prerm
/usr/share/bgscripts/build/debian-bgscripts/postinst
/usr/share/bgscripts/build/debian-bgscripts/preinst
/usr/share/bgscripts/build/debian-bgscripts/conffiles
/usr/share/bgscripts/build/debian-bgscripts/changelog
/usr/share/bgscripts/build/debian-bgscripts/rules
/usr/share/bgscripts/build/debian-bgscripts/md5sums
/usr/share/bgscripts/build/debian-bgscripts/postrm
/usr/share/bgscripts/build/debian-bgscripts/compat
%doc %attr(444, -, -) /usr/share/bgscripts/build/files-for-versioning.txt
/usr/share/bgscripts/build/testing/debian/control
%doc %attr(444, -, -) /usr/share/bgscripts/build/testing/debian/debian.txt
/usr/share/bgscripts/build/bgscripts.spec
%doc %attr(444, -, -) /usr/share/bgscripts/build/scrub.txt
/usr/share/bgscripts/build/get-files-core
/usr/share/bgscripts/build/debian-bgscripts-core/control
/usr/share/bgscripts/build/debian-bgscripts-core/prerm
/usr/share/bgscripts/build/debian-bgscripts-core/postinst
/usr/share/bgscripts/build/debian-bgscripts-core/preinst
/usr/share/bgscripts/build/debian-bgscripts-core/conffiles
/usr/share/bgscripts/build/debian-bgscripts-core/changelog
/usr/share/bgscripts/build/debian-bgscripts-core/rules
/usr/share/bgscripts/build/debian-bgscripts-core/md5sums
/usr/share/bgscripts/build/debian-bgscripts-core/postrm
/usr/share/bgscripts/build/debian-bgscripts-core/compat
/usr/share/bgscripts/plecho.sh
/usr/share/bgscripts/lecho.sh
/usr/share/bgscripts/inc/systemd/dnskeepalive.service
/usr/share/bgscripts/inc/systemd/80-dnskeepalive.preset
/usr/share/bgscripts/scrub.py
/usr/share/bgscripts/scrub.pyc
/usr/share/bgscripts/scrub.pyo
/usr/share/bgscripts/bgscripts.bashrc
/usr/share/bgscripts/send.sh
/usr/share/bgscripts/bashrc.d/fedora.bashrc
/usr/share/bgscripts/bashrc.d/devuan.bashrc
/usr/share/bgscripts/bashrc.d/korora.bashrc
/usr/share/bgscripts/bashrc.d/rhel.bashrc
/usr/share/bgscripts/bashrc.d/debian.bashrc
/usr/share/bgscripts/bashrc.d/ubuntu.bashrc
/usr/share/bgscripts/bashrc.d/centos.bashrc
/usr/share/bgscripts/updateval.sh
/usr/share/bgscripts/dli.py
/usr/share/bgscripts/dli.pyc
/usr/share/bgscripts/dli.pyo
%config %attr(666, -, -) /usr/share/bgscripts/examples/host-bup.conf.example
/usr/share/bgscripts/examples/shares-keepalive.cron
/usr/share/bgscripts/fl.sh
/usr/share/bgscripts/changelog.sh
/usr/share/bgscripts/framework.sh
/usr/share/bgscripts/newscript.sh
/usr/share/bgscripts/updateval.py
/usr/share/bgscripts/updateval.pyc
/usr/share/bgscripts/updateval.pyo
/usr/share/bgscripts/doc
/usr/share/bgscripts/ctee.sh
/usr/share/bgscripts/shares.sh
/usr/share/bgscripts/bounce.sh
/usr/share/bgscripts/bup.sh
/usr/share/bgscripts/host-bup.sh
/usr/share/bgscripts/orig-send.sh
/usr/share/bgscripts/toucher.sh

%changelog
* Tue Aug 22 2017 B Stack <bgstack15@gmail.com> 1.2-17
- Updated content. See doc/README.txt.

* Fri Jul 21 2017 B Stack <bgstack15@gmail.com> 1.2-16
- Updated content. See doc/README.txt.

* Tue Jul 11 2017 B Stack <bgstack15@gmail.com> 1.2-15
- Fix /etc/sudoers.d/ files to be chmod 0440
- Updated content. See docs/README.txt.

* Wed Jun 28 2017 B Stack <bgstack15@gmail.com> 1.2-14
- Updated content. See docs/README.txt.

* Mon Jun 12 2017 B Stack <bgstack15@gmail.com> 1.2-13
- Updated content. See docs/README.txt.

* Thu Jun  8 2017 B Stack <bgstack15@gmail.com> 1.2-12
- Updated content. See docs/README.txt.

* Wed May  3 2017 B Stack <bgstack15@gmail.com> 1.2-11
- Updated content. See docs/README.txt.

* Sat Apr 29 2017 B Stack <bgstack15@gmail.com> 1.2-10
- Updated content. See docs/README.txt.

* Thu Apr 20 2017 B Stack <bgstack15@gmail.com> 1.2-9
- Updated content. See docs/README.txt.
- Rearranged rdp symlink and conf to main package.
- Added systemd tasks for dnskeepalive, a new feature.

* Mon Apr  3 2017 B Stack <bgstack15@gmail.com> 1.2-8
- Updated content. See docs/README.txt

* Fri Mar 24 2017 B Stack <bgstack15@gmail.com> 1.2-7
- Redesigned package to put bgscripts-gui elements in /usr/share/bgscripts/gui/
- Updated content. See docs/README.txt

* Sat Mar 18 2017 B Stack <bgstack15@gmail.com> 1.2-6
- Updated content. See docs/README.txt

* Thu Mar 16 2017 B Stack <bgstack15@gmail.com> 1.2-5
- Updated package requirements and dependencies for the right subpackages.
- Updated description of which scripts are the most important.
- Updated content. See docs/README.txt

* Sat Mar 11 2017 B Stack <bgstack15@gmail.com> 1.2-4
- Updated content. See docs/README.txt

* Sat Mar  4 2017 B Stack <bgstack15@gmail.com> 1.2-2
- Updated content. See docs/README.txt

* Sat Mar  4 2017 B Stack <bgstack15@gmail.com> 1.2-1
- Removed all example.com elements

* Thu Feb  2 2017 B Stack <bgstack15@gmail.com> 1.1-33
- Added %config for rdp.conf
- Removed "Provides: bgscripts" from core subpackage.

* Mon Jan 30 2017 B Stack <bgstack15@gmail.com> 1.1-32
- Fixed summary for the package and sub-package. 
- Fixed long descriptions of the package and sub-package.

* Wed Jan 25 2017 B Stack <bgstack15@gmail.com> 1.1-31
- Removed the old /usr/bgscripts location.
- Added to the sudoers.d file the env_keep proxy settings.
- Removed the /README.md file from the package.
- Added the update-desktop-database command to the %postun
- Fixed "thisuser/thistheme" this nomenclature for loops in scriptlets.
- Fixed From: field in send.sh.
- Fixed rdp.sh debug and error messages to be more helpful and specific.
- Separated bgscripts-core from bgscripts. This was to simplify the scriptlets for cli-only systems that don't need rdp or icons or anything of that sort.

* Thu Jan 19 2017 B Stack <bgstack15@gmail.com> 1.1-30
- Added weak dependencies/recommends for packages zenity and freerdp for the rdp.sh application.
- Added deb recommends mailutils for the send.sh application.
- Changed default options of rdp.sh to include /cert-tofu
- Added README.md to the root directory for github visitors.
- Modified rdp.sh to accept /etc/bgscripts/rdp.conf and ~/.config/bgscripts/rdp.conf config files.

* Tue Jan 17 2017 B Stack <bgstack15@gmail.com> 1.1-29
- Fixed the symlink /usr/bin/rdp to point to the new location.
- Fixed bgscripts.bashrc to point to new location for thisos and thisflavor dependency checks, and also the altproxy checks.
- Fixed rpm spec and deb control scripts to use the new location.
- Updated the ./pack script to support a changelog in the spec file.
