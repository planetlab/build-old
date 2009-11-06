We've tried to isolate the distro-dependent configurations from the code

Most of the .pgks files are optional to define a new distro:
missing files are searched in the planetlab distro

========== build environment
./build/<pldistro>.mk
	that defines the contents of the build -- see Makefile
./build/<pldistro>-tags.mk
	that defines the svn locations of the various modules
./build/<pldistro>-install.mk
	optional make file to define the install target

========== kernel config
./Linux-2.6/configs/kernel-2.6.<n>-<arch>-<pldistro>.config
	(subject to change location in the future)

========== various system images
./build/config.<pldistro>/devel.pkgs
	set of packages required for building
./build/config.<pldistro>/bootcd.pkgs
	contents of the bootcd image
./build/config.<pldistro>/bootstrapfs.pkgs
	the standard contents of the node root 
	used to generate yumgroups.xml
./build/config.<pldistro>/bootstrapfs.pkgs
	specification for the contents of the core for the node
	software
        this results in a tarball (tar.bz2) 
./build/config.<pldistro>/bootstrapfs-*.pkgs
	each of these files results in an extension tarball
./build/config.<pldistro>/myplc.pkgs
	contents of the myplc image
./build/config.<pldistro>/vserver.pkgs
	the contents of the standard vserver reference image
./build/config.<pldistro>/vserver-*.pkgs
	all *.pkgs files here - produce additional vserver images
./build/config.<pldistro>/vtest.pkgs
	used to create test vservers for myplc-native

=== extensions
as of this writing extensions are managed as follows:
- at node installation, the tarball produced from bootstrapfs.pkgs is
downloaded and untared to produce the core node setup
- then we attempt to install an extension corresponding to each of the
nodegroups that the node is part of
- the first method is to try and download a tarball named after the
extension. such tarballs are produced by the build from a .pkgs file,
see above
- if that fails, then the extension install is attempted through a
 yum groupinstall  extension<nodegroup>

