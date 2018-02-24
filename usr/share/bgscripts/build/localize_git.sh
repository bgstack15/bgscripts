#!/bin/sh
# This file is no longer used. It is used after a ./pack scrub (which calls scrub.py) to bring back the git information to this working location after scrubbing it. As of bgscripts-1.2-3 I am no longer scrubbing information out.
\cp -pRf /home/work/bgscripts.clean/.git /home/bgstack15/rpmbuild/SOURCES/bgscripts-1.2-3
