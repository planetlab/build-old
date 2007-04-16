# we do not use TAG directly anymore
# this because we want the rpm's releases to reflect the date even when a tag is used

CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs

# this one is special : the boot script (in our case nightly-build.sh) extracts 
# build from the trunk/HEAD. Then the various modules may need to extract build again,
# typically when then use mkfedora, and for that purpose they use the following tag.
build-TAG :=			planetlab-4_0-branch

# the build's logic is sometimes confusing. Whether a package mentions a single or multiple modules, 
# the variable used is different. 
# Look for xxx-ambiguous-xxx below
# We define both just in case (as of now only the first one is used)

# xxx-ambiguous-xxx
linux-2.6-TAG :=		planetlab-4_0-branch
kernel-i686-TAG :=		planetlab-4_0-branch
# we dont use this yet
kernel-x86_64-TAG :=		planetlab-4_0-branch
kernel-i586-TAG :=		planetlab-4_0-branch
# end
vnet-TAG :=			planetlab-4_0-branch
madwifi-ng-TAG := 		planetlab-4_0-branch
wireless-tools-SVNPATH :=	svn+ssh://build@svn.one-lab.org/svn/wireless-tools/tags/29pre14
ivtv-TAG := 			planetlab-4_0-branch
util-vserver-TAG := 		planetlab-4_0-branch
PlanetLabAccounts-TAG := 	planetlab-4_0-branch
NodeUpdate-TAG := 		planetlab-4_0-branch
PlanetLabConf-TAG := 		planetlab-4_0-branch
ipod-TAG := 			planetlab-4_0-branch
sudo-TAG := 			planetlab-4_0-branch
pycurl-TAG := 			planetlab-4_0-branch
BootServerRequest-TAG := 	planetlab-4_0-branch
PlanetLabID-TAG := 		planetlab-4_0-branch
NodeManager-TAG := 		planetlab-4_0-branch
pl_sshd-TAG := 			planetlab-4_0-branch
libhttpd++-TAG := 		planetlab-4_0-branch
proper-TAG := 			planetlab-4_0-branch
mysql-TAG := 			planetlab-4_0-branch
ulogd-TAG := 			planetlab-4_0-branch
netflow-TAG := 			planetlab-4_0-branch
pl_mom-TAG := 			planetlab-4_0-branch
iptables-TAG := 		planetlab-4_0-branch
iproute2-TAG := 		planetlab-4_0-branch
kexec-tools-TAG := 		planetlab-4_0-branch
util-python-TAG := 		planetlab-4_0-branch
# xxx-ambiguous-xxx
PLCAPI-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/new_plc_api/trunk
new_plc_api-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/new_plc_api/trunk
# end
vserver-reference-TAG := 	planetlab-4_0-branch
bootmanager-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/bootmanager/trunk
bootcd-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/bootcd/trunk
# xxx-ambiguous-xxx
plcwww-SVNPATH := 		svn+ssh://build@svn.one-lab.org/svn/new_plc_www/trunk
new_plc_www-SVNPATH := 		svn+ssh://build@svn.one-lab.org/svn/new_plc_www/trunk
# end
myplc-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/myplc/trunk
plc/scripts-TAG := 		planetlab-4_0-branch
