#!/usr/bin/env python3
# File: /usr/share/bgscripts/py/pwhashgen.py
# Author: bgstack15@gmail.com
# Startdate: 2017-11-06
# Title: Python Script that Generates Password Hashes for /etc/shadow
# Purpose: See title.
# History:
# Usage: ./pwhashgen.py 'plaintextpw'
#    Or ./pwhashgen.py
#    and let it prompt you for a new password
# Reference: https://www.shellhacks.com/linux-generate-password-hash/
# Improve: Make work with python3 and python2
# Document: below this line
from __future__ import print_function
import crypt, getpass, sys;

pwhashgenpyversion="2017-11-11a"

if len(sys.argv) >= 2:
   thisraw=str(sys.argv[1]);
else:
   thisraw=getpass.getpass(prompt='New password: ')
   #sys.exit(1)
print(crypt.crypt(thisraw,crypt.mksalt(crypt.METHOD_SHA512)))
