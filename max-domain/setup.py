#!/usr/bin/python
# -*- coding: UTF-8 -*-
# 
# This script is inspired by the debian package python-chardet
import os
import glob
from distutils.core import setup

data_files = []

def get_debian_version():
    f=open('debian/changelog', 'r')
    line=f.readline()
    f.close()
    version=line.split()[1].replace('(','').replace(')','')
    return version


def get_images(ipath):
    images = []
    for afile in glob.glob('%s/*'%(ipath) ):
        if os.path.isfile(afile):
            images.append(afile)
    return images
        
data_files.append(('share/max-domain/images', get_images("images") ))

data_files.append(('share/max-domain', ['max-domain-main.ui'] ))

data_files.append(('share/applications', ['max-domain.desktop'] ))

data_files.append(('/etc/X11/Xsession.d', ['80_configure_domain_session'] ))

data_files.append(('share/gnome/shutdown', ['99domain_logout.sh'] ))

data_files.append(('share/max-domain', ['script_logout.sh'] ))


setup(name='MAX-DOMAIN',
      description = 'Join MAX to AD domain',
      version=get_debian_version(),
      author = 'Mario Izquierdo',
      author_email = 'mariodebian@gmail.com',
      url = 'http://max.educa.madrid.org',
      license = 'GPLv2',
      platforms = ['linux'],
      keywords = ['ldap', 'domain', 'samba'],
      scripts=['max-domain', 'max-control'],
      data_files=data_files
      )

