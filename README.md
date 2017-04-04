### Overview
bgscripts is a collection of scripts that you might find useful.
It contains scripts that help you on the command line and also in a gui.
For the description of the package itself, view usr/share/bgscripts/docs/README.txt.

### Building
The recommended way to build an rpm is:

    pushd ~/rpmbuild; mkdir -p SOURCES RPMS SPECS BUILD BUILDROOT; popd
    mkdir -p ~/rpmbuild/SOURCES/bgscripts-1.2-7/
    cd ~/rpmbuild/SOURCES/bgscripts-1.2-7
    git clone https://github.com/bgstack15/bgscripts
    usr/share/bgscripts/inc/pack rpm

The generated rpm will be in ~/rpmbuild/RPMS/noarch
