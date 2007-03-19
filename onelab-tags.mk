# we do not use TAG directly anymore
# this because we want the rpm's releases to reflect the date even when a tag is used
 

CVSROOT := :pserver:anon@cvs.planet-lab.org:/cvs

# this one is special : the boot script (in our case nightly-build.sh) extracts 
# build from the trunk/HEAD. Then the various modules may need to extract build again,
# typically when then use mkfedora, and for that purpose they use the following tag.
build-TAG :=			planetlab-4_0-rc2

linux-2.6-TAG :=		planetlab-4_0-rc2
vnet-TAG :=			planetlab-4_0-rc2
madwifi-ng-TAG := 		planetlab-4_0-rc2
wireless-tools-SVNPATH :=	svn+ssh://build@svn.one-lab.org/svn/wireless-tools/tags/29pre14
ivtv-TAG := 			planetlab-4_0-rc2
util-vserver-TAG := 		planetlab-4_0-rc2
PlanetLabAccounts-TAG := 	planetlab-4_0-rc2
NodeUpdate-TAG := 		planetlab-4_0-rc2
PlanetLabConf-TAG := 		planetlab-4_0-rc2
ipod-TAG := 			planetlab-4_0-rc2
sudo-TAG := 			planetlab-4_0-rc2
pycurl-TAG := 			planetlab-4_0-rc2
BootServerRequest-TAG := 	planetlab-4_0-rc2
PlanetLabID-TAG := 		planetlab-4_0-rc2
NodeManager-TAG := 		planetlab-4_0-rc2
pl_sshd-TAG := 			planetlab-4_0-rc2
libhttpd++-TAG := 		planetlab-4_0-rc2
proper-TAG := 			planetlab-4_0-rc2
mysql-TAG := 			planetlab-4_0-rc2
ulogd-TAG := 			planetlab-4_0-rc2
netflow-TAG := 			planetlab-4_0-rc2
pl_mom-TAG := 			planetlab-4_0-rc2
iptables-TAG := 		planetlab-4_0-rc2
iproute2-TAG := 		planetlab-4_0-rc2
kexec-tools-TAG := 		planetlab-4_0-rc2
util-python-TAG := 		planetlab-4_0-rc2
# the build's logic is sometimes confusing. Whether a package mentions a single or multiple modules, 
# the variable used is different. We define both just in case (as of now only the first one is used)
PLCAPI-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/new_plc_api/trunk
new_plc_api-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/new_plc_api/trunk
vserver-reference-TAG := 	planetlab-4_0-rc2
bootmanager-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/bootmanager/trunk
bootcd-SVNPATH :=		svn+ssh://build@svn.one-lab.org/svn/bootcd/trunk
myplc-TAG := 			planetlab-4_0-rc2
new_plc_www-TAG := 		planetlab-4_0-rc2
plc/scripts-TAG := 		planetlab-4_0-rc2
