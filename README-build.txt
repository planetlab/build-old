Notes on using this build

The PlanetLab builds has the concept of a 'distribution' that allows
advanced user to customize the contents of the build.  If you're not
an advanced user, please just use the regular 'planetlab'
distribution.  

If you want to take advantage of a custom distribution, see
README-pldistros.txt for further details. Please feel free to contact
devel@planet-lab.org, as all this is not precisely foolproof :)

=====
* install a vserver-enabled kernel and util-vserver on your build box
* create a local fedora mirror - see vbuild-fedora-mirror.sh
* create a vserver - see vbuild-init-vserver.sh
* enter the vserver and svn export this build module into /build 
* cd /build and run
# make stage1=true PLDISTRO=<yourdistro>
# make help
# make

=== automated builds
* the nightly build script wraps all this in a rather complicated way
it is not intended to be used as is without a few manual tweaks on your
build and test hosts
basically it
** recreates a fresh build vserver named after the arguments
** enters this to perform the actual build
** pushes the results to a web location so the tests can pull the
right myplc rpm
** invokes a runtest on a separate machine
** manages logs - that's the trickiest part, so the root context and
the vserver add their logs on the same file
 
=== manual builds
* always run the stage1 make prior to anything else
* if you clean or patch a spec file you need to run the stage1 again
* see make help for how to do things incrementally

* typically if you want to test a change without commiting first, you
need to:
** make package-codebase
** patch CODEBASE/module/
** make package

if further changes are needed, then do
** make package-clean-tarball package-clean-build package-clean-rpm
so the codebase remains intact, patch it again and run
** make package
