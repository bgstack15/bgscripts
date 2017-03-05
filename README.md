### Overview
bgscripts is a collection of scripts that you might find useful.
It contains scripts that help you on the command line and also in a gui.
For the description of the package itself, view usr/share/bgscripts/docs/README.txt.

### Building
The recommended way to build an rpm is:

    mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/RPMS ~/rpmbuild/SPECS ~/rpmbuild/BUILD ~/rpmbuild/BUILDROOT
    mkdir -p ~/rpmbuild/SOURCES/bgscripts-1.1-30/
    cd ~/rpmbuild/SOURCES/bgscripts-1.1-30
    git init
    git pull https://github.com/bgstack15/bgscripts
    usr/share/bgscripts/inc/pack rpm

The generated rpm will be in ~/rpmbuild/RPMS/noarch
