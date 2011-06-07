#!/usr/bin/python

import sys
import os.path
import rpm

from optparse import OptionParser

def main ():
    usage="%prog [rpmbuild-options] specfile pkg-name"
    parser=OptionParser(usage=usage)
    parser.add_option('-t','--target',action='store',dest='target',default=None,
                      help='specify target arch')
    parser.add_option('-w','--whitelist-rpms',action='store',dest='whitelist',default='',
                      help='comma separated list of rpms to expose in makefile')
    parser.add_option('-1','--with',action='store',dest='with',default='',
                      help='accept but ignore --with option')
    parser.add_option('-0','--without',action='store',dest='without',default='',
                      help='accept but ignore --without option')
    parser.add_option('-d','--define',action='store',dest='define',default='',
                      help='accept but ignore --define option')
    (options,args) = parser.parse_args()

    try:
        [specfile,package_name]=args
    except:
        parser.print_help()
        sys.exit(1)

    ts=rpm.TransactionSet()
    specobj = ts.parseSpec(specfile)
    for (fullsource,_,__) in specobj.sources:
        #print '###fullsource=',fullsource
        print "%s.tarballs += SOURCES/%s" %(package_name,os.path.basename(fullsource))
        for suffix in [".tar.gz", ".tgz", ".tar.bz2", ] : 
            #print "# trying %s"%suffix
            if fullsource.endswith(suffix):
                sourcename=fullsource.replace(suffix,"")
                print "%s.source := SOURCES/%s" %(package_name,os.path.basename(sourcename))
                break

    # Get SRPM name from name of first package
    package=specobj.packages[0]
    header0=package.header
    name=header0.format('%{name}')
    version=header0.format('%{version}')
    release=header0.format('%{release}')
    print "%s.srpm := SRPMS/%s-%s-%s.src.rpm"%(package_name, name, version, release)

    target = options.target
    whitelist=options.whitelist.split(',')
    # Print non-empty packages
    for package in specobj.packages:
        header=package.header
        name=header.format('%{name}')
        version=header.format('%{version}')
        release=header.format('%{release}')
        arch=target or header.format('%{arch}')
        
        # skip dummy entries
        if not (name and version and release and arch) : continue

        whitelisted = name in whitelist

        if header.fullFilelist or whitelisted:
            # attach (add) rpm path to package
            print "%s.rpms += RPMS/%s/%s-%s-%s.%s.rpm"%\
                (package_name, arch, name, version, release, arch)
            # convenience
            print "%s.rpmnames += %s"%\
                (package_name, name);
            # attach path to rpm name
            print "%s.rpm-path := RPMS/%s/%s-%s-%s.%s.rpm"%\
                (name,arch, name, version, release, arch)
            # attach package to rpm name for backward resolution - should be unique
            print "%s.package := %s"%\
                (name,package_name)
            
    for macro in ["release" , "name" , "version" , "taglevel" , ] :
        format="%%{%s}"%macro
        try:     print "%s.rpm-%s := %s"%(package_name,macro,header0.format(format))
        except : print "# %s.rpm-%s undefined"%(package_name,macro)

    # export arch
    print "%s.rpm-arch := %s"%(package_name,target)

if __name__ == '__main__':
    main()
