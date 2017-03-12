#!/bin/sh
# Filename: treesize.sh
# Location: 
# Author: bgstack15@gmail.com
# Startdate: 2015-11-20 13:43:41
# Title: 
# Purpose: 
# History: 2017-01-11 moved whole package to /usr/share/bgscripts
# Usage: 
# Reference: ftemplate.sh 2015-11-20a; framework.sh 2015-11-20a
# Improve:
treesize2version="2017-03-11a"

du -xBM "$@" | sort -n
echo "treesize.sh is deprecated and will be removed in a future version of bgscripts-core. Just use \"du -xBM | sort -n\" in the future." 1>&2
