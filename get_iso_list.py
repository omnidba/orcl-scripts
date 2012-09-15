#!/usr/bin/env python
#
#
#
# jerry.wang@delphix.com

import os
import os.path
import subprocess

LSLTR = '/usr/gnu/bin/ls -lth '
HEAD5 = '| /usr/gnu/bin/head -n 5 | cut -d" " -f5-8'
NIGHTLY_BLD_PATH = '/nas/engineering/nightly_build/'

def get_iso_path(version):
    if version == '2.6.1.0':
        iso_path = os.path.join(NIGHTLY_BLD_PATH, 'delphix_2.6.1.0', 'engr_builds', 'delphix_2.6.1.0*.iso')
    
    if version == '2.7.0.0':
        iso_path = os.path.join(NIGHTLY_BLD_PATH, 'delphix_2.7.0.0', 'engr_builds', 'delphix_2.7.0.0*.iso')
        
    return iso_path

def get_iso_list(path):
    output = subprocess.Popen([LSLTR + path + HEAD5], shell=True, stdout=subprocess.PIPE).communicate()[0]
    
    return output

def test():
    print "Latest Five 2.6.1.0 ISO Images:"
    list_2610 = get_iso_list(get_iso_path('2.6.1.0'))
    print list_2610
    
    print "Latest Five 2.7.0.0 ISO Images:"
    list_2700 = get_iso_list(get_iso_path('2.7.0.0'))
    print list_2700

if __name__ == '__main__':
    test()
