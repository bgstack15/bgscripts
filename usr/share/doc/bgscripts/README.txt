File: usr/share/bgscripts/docs/README.txt
Package: bgscripts
Author: bgstack15
Startdate: 2016-05-31
Title: Readme file for bgscripts
Purpose: All packages should come with a readme
Usage: Read it.
Reference: README.txt
Improve:
Document: Below this line

### WELCOME
The bgscripts and bgscripts-core packages are designed to bring the bgstack15 working environment to a server. Many scripts (shell and python3) are provided, as well as a complete bashrc.

To use the bgscripts.bashrc in your terminal, use this command:
. bp

### OTHER README FILES
For descriptions of each individual script in this package, please read /usr/share/doc/bgscripts/SCRIPTS.txt.

For the description of the framework.sh library and associate files, read /usr/share/doc/bgscripts/FRAMEWORK.txt.

For notes on the bgscripts.bashrc and its sub-files, read /usr/share/doc/bgscripts/BGSCRIPTS-BASHRC.txt.

### OS-SPECIFIC NOTES
On Ubuntu, the mailutils package provides sendmail, which send.sh needs to operate properly.

### REFERENCE
Ftemplate config file removing comments
https://groups.google.com/forum/#!topic/comp.unix.shell/9IgFkVkOe5o
http://sed.sourceforge.net/grabbag/scripts/remccoms3.sed

function isflag: Count occurrences of char in string
http://stackoverflow.com/questions/16679369/count-occurrences-of-char-in-string-using-bash

function fisnum: Test variable is number
http://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash

function isvalidip: Test string for valid IP address
http://stackoverflow.com/questions/4890789/regex-for-an-ip-address/30023010#30023010

considered systemd timer:
   https://unix.stackexchange.com/questions/198444/run-script-every-30-min-with-systemd
   https://unix.stackexchange.com/questions/303926/run-while-true-in-systemd-script

command: rpm --showrc

https://superuser.com/questions/1017959/how-to-know-if-i-am-using-systemd-on-my-linux

Terminal title https://bgstack15.wordpress.com/2017/05/29/edit-terminal-title-from-the-command-line/

Beep in terminal https://askubuntu.com/questions/19906/beep-in-shell-script-not-working
https://unix.stackexchange.com/questions/71064/automate-modprobe-command-at-boot-time-on-fedora#71069

### CHANGELOG
bgscripts 1.1-9
bgscripts.bashrc includes ls --color=auto for all ls aliases.
framework had its thisos, thisflavor, and thisflavorversion values updated

bgscripts 1.1-9 2016-07-14
fixed stderr redirection at end of bgscripts.bashrc

2016-02-26 Updated framework.sh to parse flagged arguments without a space!

2016-05-25
function isvalidip: Returns exit value 0 if the argument is a valid IPv4 address.
http://www.regextester.com/22

https://blog.serverdensity.com/how-to-create-a-debian-deb-package/

2016-08-03
bgscripts 1.1-10
Adding FreeBSD compatibility of the scripts
converting files to work in /bin/sh to be completely portable
Added notes for how to make a FreeBSD port. I was unable to get the port creation to work. I don't know how to  use a Makefile.

2016-08-15 bgscripts 1.1-11
Reorganized how the debian package info is stored and manipulated during building

2016-08-17 bgscripts 1.1-12
Fixed an August 3 problem where /usr/bin/bp and other files in that directory were actual files instead of symlinks to ../bgscripts
Changed /usr/bin/{symlinks} to point to ../bgscripts/{filename}.sh instead of /usr/bgscripts
## Use these commands:

cd ~/rpmbuild/SOURCES/bgscripts-1.1-12/usr/bin
for word in beep bup fl lecho newscript plecho send treesize; do echo $word; ln -sf ../bgscripts/${word}.sh ${word}; done; ln -sf ../bgscripts/bgscripts.bashrc bp

2016-09-14 bgscripts 1.1-13
Added updateval.sh
Added FreeBSD ls flag "-F" which shows filetype with a symbol after the filename
Updated web-hosted package deployment instructions to use ~/ instead of /opt/ and also to use proper symlinks

2016-09-29 bgscripts 1.1-14
Includes scrub.py which removes private data and replaces it with sample data for publication on public sites like github.
Updated the instructions for deploying from web-hosted master.tgz to work on AIX (non-GNU tar)
Added "ccat" function using highlight -O ansi

2016-10-12 bgscripts 1.1-15
Updated scrub.py
Fixed "unalias ll" in bgscripts.bashrc. Some systems apparently already alias that, and the alias was being called before the function ll.
Rewrote updateval in python3

2016-10-19 bgscripts-1.1-16
Updated updateval.py to include "--stanza" option
Updated packaging.txt to exclude .git directory for rpm and dpkg

2016-10-24 bgscripts-1.1-17
Updating updateval.py to work with stanza() types

2016-11-16 bgscripts-1.1-18
Adding scrub.py
Updated scrub.py to have a conf file entry of filetypes to ignore
Added dependency of python3 to the package

2016-11-30 bgscripts-1.1-19
Fixed the wc -l check on the OS version files so it does not throw errors/alerts
Added unqualified mirror hostname to the no_proxy list
Updated spec file a little

2016-11-30 bgscripts-1.1-20
Added debug option to scrub.py
Added "--noglobalprofile" and "--noclear" to bgscripts.bashrc

2016-12-01 bgscripts-1.1-22
Fixed dependecy for python3/python34/python35
Fixed bgscripts.bashrc fcheck command

2016-12-08 bgscripts-1.1-23
Added dli.py which provides 'dnf list installed' caching and search
Added to bgscripts.bashrc the variables: thisos, thisflavor
Added bashrc.d functionality for oses and flavors
Added update-repo and autocomplete for rhel and debian bashrc.d files

2016-12-13 bgscripts-1.1-24
Fixed the yum/dnf update-repo command
Added cdmnt bash completion
Added rdp.sh and associated desktop file and mimetype (*.rdp)
Disabled the initial cd /mnt/scripts

2016-12-15 bgscripts-1.1-25
Added the application-x-rdp icon for the mimetype
Fixed the %postun icon removal
Used the easily generated png files from the svg for icons:
# time for num in 16 24 32 48 64; do inkscape -w ${num} -e Numix-application-x-rdp-${num}.png Numix-application-x-rdp-scalable.svg; done

2017-01-02 bgscripts-1.1-26
Updated proxy exclusion settings to exclude the DMZ servers
Updated the proxy settings to be a lookup to a separate file
Added to bgscripts.bashrc options "nodeps", "noflavor", "noos"

2017-01-04 bgscripts-1.1-27
Updated ./pack to have a --help option
Updated the "Deploy scalable application icons" to match the irfan one, going to different themes if they exist
Copy in the irfan generate-icons.sh script and adapted for apps and mimes
Added to ./pack the "scrub" option
Updated ./pack to calculate package and version number.

  New scheme for installing icons:
  1. apps
    a. default, per theme
      i. scalable (svg)
      ii. size (png)
    b. custom (any size which get the svgs)
  2. mimetypes
    a. default, per theme
      i. scalable
      ii. sized
    b. custom

2017-01-10 bgscripts-1.1-28
Shortened the deprecated docs/packaging.txt file
Moved the whole package contents to /usr/share/bgscripts to be FHS 3.0-compliant.
 * Wrapper scripts have been placed for everything except framework in the old location, /usr/bgscripts. These will be removed in a future version. They send an email to author to indicate which scripts are still pointing to these old locations, so they can be fixed.
Fixed how the command line parameters are parsed in bgscripts.bashrc so it works on CentOS 5 and CentOS 6 as well.

2017-01-17 bgscripts-1.1-29
Fixed the symlink /usr/bin/rdp to point to the new location.
Fixed bgscripts.bashrc to point to new location for thisos and thisflavor dependency checks, and also the altproxy checks.
Fixed rpm spec and deb control scripts to use the new location.
Updated the ./pack script to support a changelog in the spec file.

2017-01-19 bgscripts-1.1-30
Added weak dependencies/recommends for packages zenity and freerdp for the rdp.sh application.
Added deb recommends mailutils for the send.sh application.
Changed default options of rdp.sh to include /cert-tofu
Added README.md to the root directory for github visitors.
Modified rdp.sh to accept /etc/bgscripts/rdp.conf and ~/.config/bgscripts/rdp.conf config files.

* Wed Jan 25 2017 B Stack <bgstack15@gmail.com> 1.1-31
- Removed the old /usr/bgscripts location.
- Added to the sudoers.d file the env_keep proxy settings.
- Removed the /README.md file from the package.
- Added the update-desktop-database command to the %postun
- Fixed "thisuser/thistheme" this nomenclature for loops in scriptlets.
- Fixed From: field in send.sh.
- Fixed rdp.sh debug and error messages to be more helpful and specific.
- Separated bgscripts-core from bgscripts. This was to simplify the scriptlets for cli-only systems that don't need rdp or icons or anything of that sort.

2017-01-30 B Stack <bgstack15@gmail.com> 1.1-32
- Added changelog.sh which converts rpm to deb changelogs and back
- Moved the package content changelog to README.txt and left the rpm changelog to be the rpm components changelog only, per Fedora specifications.
- Rearranged files-for-versioning.txt to be in order: first generic, then package-specific items.
- Rearranged scrub.txt to be in a more logical order.

2017-02-02 B Stack <bgstack15@gmail.com> 1.1-33
- Added %config for rdp.conf.
- Added a few comments to rdp.conf.
- Removed "Provides: bgscripts" form core subpackage (rpm spec).
- Added file selection dialog to rdp.

2017-03-04 B Stack <bgstack15@gmail.com> 1.2-1
- Removed all AIX support
- Refactored to remove all example.com references

2017-03-04 B Stack <bgstack15@gmail.com> 1.2-2
- Removed the old proxy files
- Added cifs-keepalive.sh and its example cron file

2017-03-05 B Stack <bgstack15@gmail.com> 1.2-3
- Added comments to scrub.txt and localize_git.sh to indicate that they are now obsolete.

2017-03-11 B Stack <bgstack15@gmail.com> 1.2-4
- Added sshp function to bashrc.bgscripts
- Rewrote treesize.sh to just use the equivalent du -xBM | sort -n command and issue a warning about its impending deletion.
- Fixed up framework.sh with many small fixes

2017-03-16 B Stack <bgstack15@gmail.com> 1.2-5
- Updated package requirements and dependencies for the right subpackages.
- Updated description of which scripts are the most important.
- Rearranged rpm and deb requirements and recommendations
- Added ctee.sh
- Removed treesize.sh

2017-03-18 B Stack <bgstack15@gmail.com> 1.2-6
- Trimmed ctee.sh to smallest it can be.

2017-03-24 B Stack <bgstack15@gmail.com> 1.2-7
- Added autoresize.sh
- Redesigned package to put bgscripts-gui elements in /usr/share/bgscripts/gui/

2017-04-03 B Stack <bgstack15@gmail.com> 1.2-8
- Fixed rdp symlink in /usr/bin/
- Fixed resize.sh to be executable
- Fixed virt-what check to depend on any output instead of exit code
- Replaced cifs-keepalive with shares.sh which does remounting and keepalive.

2017-04-20 B Stack <bgstack15@gmail.com> 1.2-9
- Rewrote send.sh to be more modular for future send mechanisms
- Added htmlize function to bgscripts.bashrc
- Fixed pack file to mkdir; cd instead of mkdir cd
- Modified shares.sh to not show error "host is down." when bouncing a network share.
- Fixed packaging.txt for tarball-based deployments
- Added bounce.sh, which takes dynamic input and cycles its status. Currently supports network cards and network shares.
- Added bash autocompletion support for bounce.
- Added dnskeepalive script and service.
- Fixed bp where when you call it without sourcing it, it will not throw the cryptic error and will instead warn you to source it.
- Rearranged ftemplate.sh "REACT TO OPERATING SYSTEM TYPE"
- Framework changes:
-  Added fistruthy.
-  Cleaned up fwhich.
- RPM scriptlets:
-  Added systemd scriptlet functions for adding/removing dnskeepalive.
- Adjusted get-files to include rdp symlink and conf
- Adjusted get-files-core to include /etc/bgscripts directory for proper cleanup

2017-04-30 B Stack <bgstack15@gmail.com> 1.2-10
- Updated resize.sh to work on Lubuntu as well, by refreshing all active monitors.
- Resumed maintenance of deb package after skipping them for a few months (last testing around version 1.1-30):
-  Updated deb maintainer scripts.
-  Adjusted get-files scripts for deb.
-  Confirmed deb conffiles.
- Removed bashisms from rdp.sh and one lingering one from ftemplate.sh.
- Updated rdp:
-  Adjusted default rdp.conf settings.
-  Adjusted to use framework thisosflavor instead of using own logic.

2017-05-24 B Stack <bgstack15@gmail.com> 1.2-11
- Updated bounce.sh to have better autocompletion based on flags -m -n -s.
- Fixed send.sh htmlize.
- Fixed rdp to use ~/.config/bgscripts/.credentials file.
- Enhanced get-files package helper scripts by having them change directories on their own.
- Added toucher script, which does touch chown chmod restorecon.
- Added new SIMPLECONF features to framework:
-  simpleconf uses get_conf() and is the hierarchy of precedence, and UNIX philosophy of using environment variables.
-   SIMPLECONF follows a simple hierarchy of precedence, with first being used:
-   1. parameters and flags
-   2. environment
-   3. config file
-   4. default user config: ~/.config/script/script.conf
-   5. default config: /etc/script/script.conf
-  define_if_new() function which can be helpful in simpleconf
- Added host-bup.sh which bups the config files on a host based on its config file.

2017-06-08 B Stack <bgstack15@gmail.com> 1.2-12
- Update ftemplate/framework
-  Included "c" | "conf" for conffile.
-  Updated help text to include conffile.
- Moved host-bup.conf to example directory.
- Fixed package so it actually does desktop-file-install of resize if spice-vdagent is present.
- Fixed package so it uses %{_presetdir}.
- Added bgscripts-version.txt file.
- Fixed newscript to use $( which vi ) and also for chmod.
- Fixed get-files so it includes the cd debdir stuff
- Adjusted package so it only deploys systemd stuff if systemd is present. Need to test!

2017-06-12 B Stack <bgstack15@gmail.com> 1.2-13
- Fixed updateval.py
- Added devuan.bashrc symlink to debian.bashrc

2017-06-28 B Stack <bgstack15@gmail.com> 1.2-14
- Updated rdp.sh to include devuan in the screen size calculations
- Added title.sh which adjusts the title of the terminal window
- Updated bgscripts.bashrc to include permtitle() function

2017-07-11 B Stack <bgstack15@gmail.com> 1.2-15
- Updated rpm spec and deb scripts to reload systemd daemons.
- Updated rpm spec to make dnskeepalive installation/replacment work even on upgrades.
- Updated bounce.sh to include any network card as seen by ip -o link show
- Fixed rpm spec /etc/sudoers.d/ file permissions

2017-07-19 B Stack <bgstack15@gmail.com> 1.2-16
