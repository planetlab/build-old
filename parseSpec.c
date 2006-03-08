/*
 * Parses RPM spec file into Makefile fragment. See
 *
 * http://fedora.redhat.com/docs/drafts/rpm-guide-en/ch-programming-c.html
 *
 * Mark Huang <mlhuang@cs.princeton.edu>
 * Copyright (C) 2006 The Trustees of Princeton University
 *
 * $Id: parseSpec.c,v 1.1 2006/03/08 21:19:16 mlhuang Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <rpm/rpmlib.h>
#include <rpm/rpmts.h>
#include <rpm/rpmcli.h>
#include <rpm/rpmbuild.h>
#include <rpm/rpmspec.h>

/* the structure describing the options we take and the defaults */
static struct poptOption optionsTable[] = {
	{ NULL, '\0', POPT_ARG_INCLUDE_TABLE, rpmcliAllPoptTable, 0,
	  "Common options for all rpm modes and executables:",
	  NULL },

	POPT_AUTOALIAS
	POPT_AUTOHELP
	POPT_TABLEEND
};

/* Stolen from rpm/build/spec.c:rpmspecQuery() */
Spec
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
main(int argc, char *const argv[])
{
	poptContext context;
	rpmts ts = NULL;
	QVA_t qva = &rpmQVKArgs;
	int ec = 0;
	Spec spec;
	struct Source *source;

	/* Parse common options for all rpm modes and executables */
	context = rpmcliInit(argc, argv, optionsTable);

	/* Create transaction state */
	ts = rpmtsCreate();

	/* Parse spec file. The rpmcli functions don't allow you to
	 * access the Spec structure directly, so we call our own
	 * version of rpmSpecQuery() directly. */
	spec = rpmspecGet(ts, argv[1]);
	if (spec && spec->sources) {
		for (source = spec->sources; source; source = source->next) {
			char fullSource[PATH_MAX];
			strncpy(fullSource, source->fullSource, sizeof(fullSource));
			printf("SOURCES += SOURCES/%s\n", basename(fullSource));
		}
	}
		
	/* This is what would popt would do if --specfile were
	 * specified. */
	qva->qva_source |= RPMQV_SPECFILE;
	qva->qva_sourceCount++;
	qva->qva_mode = 'q';
	qva->qva_specQuery = rpmspecQuery;

	/* Get SRPM name from name of first package */ 
	qva->qva_queryFormat = "SRPM := SRPMS/%{name}-%{version}-%{release}.src.rpm\n";
	if (spec && spec->packages)
		showQueryPackage(qva, ts, spec->packages->header);

	/* Print all packages */
	qva->qva_queryFormat = "RPMS += RPMS/%{ARCH}/%{name}-%{version}-%{release}.%{ARCH}.rpm\n";
	ec = rpmcliQuery(ts, qva, (const char **) &argv[1]);

	ts = rpmtsFree(ts);
	context = rpmcliFini(context);
	return ec;
} 
