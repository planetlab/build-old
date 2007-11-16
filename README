Copyright (c) 2003  The Trustees of Princeton University (Trustees).

$Id$

Here are some general guidelines for writing spec files.

* RPM does not allow you to use dashes in version or release
  numbers. Use dots, or nothing.

* Most versions of RPM poorly handle version and release numbers that
  do not begin with a number. Start your version and release number with
  at least one number. Append as many minor numbers as you want, but
  leave alphabetic characters at the end of the string.

* Always define BuildRoot based in %{_tmppath}.

* In the %install step, always install files based in $RPM_BUILD_ROOT.

* Don't be overly restrictive with Requires or BuildRequires tags. RPM
  is already pretty smart about analyzing your package for necessary
  dependencies. Usually, you only need to specify Requires tags to make
  sure a set of packages get installed in the right order (if there is
  one). Otherwise, it's likely your users will end up in awful
  situations requiring manual bootstrap.

Here are some specific guidelines for writing spec files for this setup.

* Write your spec file as you would normally. It should be an
  operational spec file on its own.

* Explicitly %define %{name}, %{version}, %{release}, or don't use
  them. You should do this anyway to support older versions of RPM. This
  Makefile does not implicitly define these variables (based on the
  Name:, Version:, and Release: tags) as RPM does.

* Run cvsps(1) manually on your repository, and synchronize the PatchSet
  numbers with any Patch: tags in your spec file that you would like
  explicitly named.

* This Makefile assumes that the build directory (as specified by the -n
  option to %setup, or the RPM default %{name}-%{version}) is the
  basename of the Source file (i.e. without .tar[.gz|.bz2]).

* Add %{?date:.%{date}} to your %{release} tag. When executed, this
  Makefile will define the variable to be the current date in YYYY.MM.DD
  form. This will help automated nightly upgrades. Tagged releases will
  not define this variable.

* Unless you have a very good reason not to, use the following tags:

Vendor: PlanetLab
Packager: PlanetLab Central <support@planet-lab.org>
Distribution: PlanetLab 2.0
URL: http://www.planet-lab.org
