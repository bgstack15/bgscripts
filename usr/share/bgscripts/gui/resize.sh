#!/bin/sh
# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1290586#c3
for word in $( xrandr --listactivemonitors | awk 'NR != 1 { print $NF; }'; ); do xrandr --output ${word} --auto 1>/dev/null 2>&1; done
