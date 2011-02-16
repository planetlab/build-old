/*
 * Parses RPM spec file into Makefile fragment. See
 *
 * http://fedora.redhat.com/docs/drafts/rpm-guide-en/ch-programming-c.html
 *
 * Mark Huang <mlhuang@cs.princeton.edu>
 * Copyright (C) 2006 The Trustees of Princeton University
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <errno.h>
#include <rpm/rpmlib.h>
#include <rpm/rpmts.h>
#include <rpm/rpmcli.h>
#include <rpm/rpmbuild.h>
#include <rpm/rpmspec.h>

/* from f10 and up, Spec is renamed rpmSpec */
#ifndef _RPMTYPES_H
#define rpmSpec Spec
#endif

#ifndef PATH_MAX
#include <linux/limits.h>
#endif

extern size_t strnlen(const char *s, size_t maxlen);

/* the structure describing the options we take and the defaults */
static struct poptOption optionsTable[] = {
  { NULL, '\0', POPT_ARG_INCLUDE_TABLE, rpmBuildPoptTable, 0,
    "Build options with [ <specfile> | <tarball> | <source package> ]:",
    NULL },
 
  { NULL, '\0', POPT_ARG_INCLUDE_TABLE, rpmcliAllPoptTable, 0,
    "Common options for all rpm modes and executables:",
    NULL },

  POPT_AUTOALIAS
  POPT_AUTOHELP
  POPT_TABLEEND
};

/* Stolen from rpm/build/spec.c:rpmspecQuery() */
rpmSpec
rpmspecGet(rpmts ts, const char * arg)
{
  char * buildRoot = NULL;
  int recursing = 0;
  char * passPhrase = "";
  char *cookie = NULL;
  int anyarch = 1;
  int force = 1;

  if (parseSpec(ts, arg, "/", buildRoot, recursing, passPhrase,
		cookie, anyarch, force)) {
    fprintf(stderr, "query of specfile %s failed, can't parse\n", arg);
    return NULL;
  }

  return rpmtsSpec(ts);
}

int
main(int argc, char *argv[])
{
  poptContext context;
  rpmts ts = NULL;
  int ec = 0;
  rpmSpec spec;
  struct Source *source;
  Package pkg;
  const char *name, *version, *release, *arch, *unused;
  const char *package_name;

  /* BEGIN: support to pull out --target from the args list */
  int  alen, i;
  char *target = NULL;
  int args = 1;
  int tlen = strlen("--target");


  /* walk argv list looking for --target */
  while ((args+1)<argc) {
    if(strncmp(argv[args],"--target",tlen)==0){
      char **dash;

      /* get arch component of the --target option */
      dash = (char**)strchr(argv[args+1],'-');
      if (dash != NULL) *dash=NULL;

      /* copy arch component of --target option to target */
      alen = strnlen(argv[args+1],32);
      target = (char*)malloc(alen+1);
      if (target == NULL) return errno;
      strncpy(target,argv[args+1],alen);
      target[alen]='\0';

      /* change argc, argv to take out the "--target xxx" */
      for (i=args;i<argc;i++) argv[i]=argv[i+2];
      argc-=2;

      break;
    }
    args++;
  }
  argv[1]=argv[argc-2];
  argv[2]=argv[argc-1];
  argv[3]=0;
  argc=3;
  /* END: support to pull out --target from the args list */

  /* Parse common options for all rpm modes and executables */
  context = rpmcliInit(argc, argv, optionsTable);

  /* Create transaction state */
  ts = rpmtsCreate();

  /* Parse spec file. The rpmcli functions don't allow you to
   * access the Spec structure directly, so we call our own
   * version of rpmSpecQuery() directly. */
  spec = rpmspecGet(ts, argv[1]);
  package_name = argv[2];
  if (!spec) {
    ec = 1;
    goto done;
  }

  /* Print sources */
  for (source = spec->sources; source; source = source->next) {
    char fullSource[PATH_MAX];

    strncpy(fullSource, source->fullSource, sizeof(fullSource));
    printf("%s.tarballs += SOURCES/%s\n", package_name, basename(fullSource));
    /* computes the SOURCEDIR variable by removing .tar.gz or .tar.bz2 */
    { 
      char *suffixes[] = {".tar.gz",".tgz",".tar.bz2", NULL};
      char **suffix;
      char *suffix_index;
		  
      for (suffix=suffixes ; *suffix ; suffix++) {
	printf("# trying %s\n",*suffix);
	suffix_index=strstr(fullSource,*suffix);
	if (suffix_index) {
	  char sourcename[PATH_MAX];
	  size_t len = (size_t)(suffix_index-fullSource);
	  strncpy(sourcename,fullSource,len);
	  sourcename[len]='\0';
	  printf ("%s.source := SOURCES/%s\n",package_name,basename(sourcename));
	  break;
	}
      }
    }
		    
  }

  /* Get SRPM name from name of first package */ 
  pkg = spec->packages;
  name = version = release = NULL;
  (void) headerNVR(pkg->header, &name, &version, &release);
  if (name && version && release)
    printf("%s.srpm := SRPMS/%s-%s-%s.src.rpm\n",
	   package_name, name, version, release);

  /* Print non-empty packages */
  for (pkg = spec->packages; pkg != NULL; pkg = pkg->next) {
    name = version = release = arch = NULL;
    (void) headerNEVRA(pkg->header, &name, &unused, &version, &release, &arch);
    if (name && version && release && arch) {
      if (target != NULL) {
	if (strcmp(arch,target)!=0) {
	  arch=target;
	}
      }
      /* skip empty packages 
       *
       * Unfortunately, f8 + the RHEL kernel break this bit of cleverness. The following
       * line returns false for the kernel-devel package even though it is not empty thereby breaking the build.
       * Rather than unfolding the kernel package macros in the current specfile, this hack should work till f8 dies its natural death. */

      if (pkg->fileList || !strncmp(name,"kernel",sizeof("kernel")-1)) {
        /* attach (add) rpm path to package */
        printf("%s.rpms += RPMS/%s/%s-%s-%s.%s.rpm\n",
               package_name, arch, name, version, release, arch);
        /* convenience */
        printf("%s.rpmnames += %s\n",
               package_name, name);
        /* attach path to rpm name */
        printf("%s.rpm-path := RPMS/%s/%s-%s-%s.%s.rpm\n",
               name,arch, name, version, release, arch);
        /* attach package to rpm name for backward resolution - should be unique */
        printf("%s.package := %s\n",
               name,package_name);
      }
    }
  }

  /* export some macros to make */
  /* note : this relies on pl-specific conventions and might be wrong */
  { 
    char *macros[] = { "release" , "name" , "version" , "taglevel" , NULL } ;
    char **nav;
    char *macro=malloc(32);
    for (nav=macros; *nav; nav++) {
      sprintf(macro,"%%{%s}",*nav);
      char *value = rpmExpand(macro,NULL);
      printf ("%s.rpm-%s := %s\n",package_name,*nav,value);
    }
  }
  
  /* export arch */
  printf ("%s.rpm-arch := %s\n",package_name,target);

  spec = freeSpec(spec);

 done:
  ts = rpmtsFree(ts);
  context = rpmcliFini(context);
  return ec;
} 
