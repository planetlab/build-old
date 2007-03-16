> # we do not use TAG directly anymore
> # this because we want the rpm's releases to reflect the date even when a tag is used
> # our build script defines $(COMMON_TAG) that the various components are free to use or not
> 
# $(COMMON_TAG) set from the build script

build-tag :=			$(COMMON_TAG)
linux-2.6-TAG :=		$(COMMON_TAG)
vnet-TAG :=			$(COMMON_TAG)
madwifi-ng-TAG := 		$(COMMON_TAG)
wireless-tools-TAG :=		29pre14
ivtv-TAG := 			$(COMMON_TAG)
util-vserver-TAG := 		$(COMMON_TAG)
PlanetLabAccounts-TAG := 	$(COMMON_TAG)
NodeUpdate-TAG := 		$(COMMON_TAG)
PlanetLabConf-TAG := 		$(COMMON_TAG)
ipod-TAG := 			$(COMMON_TAG)
sudo-TAG := 			$(COMMON_TAG)
pycurl-TAG := 			$(COMMON_TAG)
BootServerRequest-TAG := 	$(COMMON_TAG)
PlanetLabID-TAG := 		$(COMMON_TAG)
NodeManager-TAG := 		$(COMMON_TAG)
pl_sshd-TAG := 			$(COMMON_TAG)
libhttpd++-TAG := 		$(COMMON_TAG)
proper-TAG := 			$(COMMON_TAG)
mysql-TAG := 			$(COMMON_TAG)
ulogd-TAG := 			$(COMMON_TAG)
netflow-TAG := 			$(COMMON_TAG)
pl_mom-TAG := 			$(COMMON_TAG)
iptables-TAG := 		$(COMMON_TAG)
iproute2-TAG := 		$(COMMON_TAG)
kexec-tools-TAG := 		$(COMMON_TAG)
util-python-TAG := 		$(COMMON_TAG)
new_plc_api-TAG :=		trunk
vserver-reference-TAG := 	$(COMMON_TAG)
bootmanager-TAG :=		trunk
bootcd-TAG :=			trunk
myplc-TAG := 			$(COMMON_TAG)
new_plc_www-TAG := 		$(COMMON_TAG)
plc/scripts-TAG := 		$(COMMON_TAG)
