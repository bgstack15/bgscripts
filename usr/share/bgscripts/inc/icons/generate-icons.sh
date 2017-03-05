#!/bin/sh
# File: generate-icons.sh
# Version: 2017-01-04a for bgscripts
# Reference:
# get integer from bc http://stackoverflow.com/questions/2965411/bash-script-specify-bc-output-number-format#18547844
# element of progress bar http://stackoverflow.com/questions/3211891/creating-string-of-repeated-characters-in-shell-script#5915913
# progress bar http://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script#238094
export DISPLAY=:0
workdir=$( pwd )

# Check directory to make sure it is correct.
echo "${workdir}" | grep -qiE "\/rpmbuild\/.*\/inc\/icons" 1>/dev/null 2>&1 || { echo "Not in rpmbuild directory. Aborted."; exit 1; }

# Clear old png files
find "${workdir}" -name "*.png" -exec rm -f {} \; 1>/dev/null 2>&1
maxfiles="$( find . -name "*.svg" | wc -l )"
progressbarsize=12
count=0

shopt -s globstar
#for file in *.svg;
find . -name "*.svg" | sed -e 's/^\.\///;' | while read file;
do
   printf "%-80s" "Processing $file"
   thisname="${file%%.*}"
   for num in 16 24 32 48 64;
   do
      len="$( printf "%0.0f\n" "$( echo "(${count}/${maxfiles})*${progressbarsize}" | bc -lq )" )"
      printf "[%-${progressbarsize}s] generating %-50s" "$( printf '%*s' "${len}" | tr ' ' "#" )" "${thisname}-${num}.png"
      inkscape -w ${num} -e "${thisname}-${num}.png" "${thisname}.svg" 1>/dev/null 2>&1 && printf "\r"
   done
   count=$(( count + 1 ))
done

# final progress bar
len="$( printf "%0.0f\n" "$( echo "(${count}/${maxfiles})*${progressbarsize}" | bc -lq )" )"
printf "[%-${progressbarsize}s] %-50s\n" "$( printf '%*s' "${len}" | tr ' ' "#" )" "generated all images."
