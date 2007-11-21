we've tried to isolate the distro-dependent configurations from the code
the places where these distro-dependent config files lie are

./build/groups/<pldistro>.xml 
	that is used as the yumgroups.xml 
./build/<pldistro>.mk
	that defines the contents of the build
./build/<pldistro>-tags.mk
	that defines the svn locations of the various modules
./build/<pldistro>-install.mk
	optional make file to define the install target
./build/<pldistro>-devel.lst
	set of packages required for building

./bootcd/<pldistro>-bootcd.lst
./bootstrapfs/<pldistro>-base.lst
./bootstrapfs/<pldistro>-filesystems
	all *.lst files here - produce tar.bz2 images
./myplc/<pldistro>-plc.lst
./vserver/<pldistro>-vserver.lst
./vserver/<pldistro>-vservers
	all *.lst files here - produce vserver images
