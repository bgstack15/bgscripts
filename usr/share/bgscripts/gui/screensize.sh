#!/bin/sh
xrandr --screen 0 | awk 'BEGIN {IFS=" " } NR==1 {print $8"x"$10 }' | tr -d ','
