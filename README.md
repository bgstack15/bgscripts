### Overview
bgscripts is a collection of scripts that you might find useful.
It contains scripts that help you on the command line and also in a gui.
For the description of the package itself, view usr/share/bgscripts/docs/README.txt.

### Building
The recommended way to build an rpm is:

    thisver=1.3-3
    mkdir ~/rpmbuild
    pushd ~/rpmbuild; mkdir -p SOURCES RPMS SPECS BUILD BUILDROOT; popd
    mkdir -p ~/rpmbuild/SOURCES/bgscripts-${thisver}
    cd ~/rpmbuild/SOURCES
    git clone https://github.com/bgstack15/bgscripts bgscripts-${thisver}
    cd bgscripts-${thisver}
    usr/share/bgscripts/inc/pack rpm
The generated rpm will be in ~/rpmbuild/RPMS/noarch

The recommended way to build a deb is:

    thisver=1.3-3
    mkdir ~/deb
    cd ~/deb
    git clone https://github.com/bgstack15/bgscripts bgscripts-${thisver}
    cd bgscripts-${thisver}
    usr/share/bgscripts/inc/pack deb
The generated deb will be in ~/deb
