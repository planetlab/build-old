#!/bin/bash
#
# Generates XML manifest of packages for
# http://www.planet-lab.org/Software/download.php
#
# Mark Huang <mlhuang@cs.princeton.edu>
# Copyright (C) 2004 The Trustees of Princeton University
#
# $Id: packages.sh,v 1.2 2004/10/27 04:47:02 mlhuang Exp $
#

xml_escape_pcdata() {
    # & to &amp;
    # " to \"
    # ' to &apos;
    # < to &lt;
    # > to &gt;
    sed \
	-e 's/\&/\&amp;/g' | sed \
	-e 's/"/\&quot;/g' \
	-e "s/'/\&apos;/g" \
	-e 's/</\&lt;/g' \
	-e 's/>/\&gt;/g'
}

xml_escape_cdata() {
    # & to &amp;
    # \ to \\
    # " to \"
    # ' to &apos;
    # < to &lt;
    # > to &gt;
    sed \
	-e 's/\&/\&amp;/g' \
	-e 's/\\/\\\\/g' | sed \
	-e 's/"/\\"/g' \
	-e "s/'/\&apos;/g" \
	-e 's/</\&lt;/g' \
	-e 's/>/\&gt;/g'
}

# All supported tags
TAGS=$(rpm --querytags)

cat <<EOF
<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<!-- \$Id: packages.sh,v 1.2 2004/10/27 04:47:02 mlhuang Exp $ -->
<!-- Generated at $(date) in $(cd ${1-.} && pwd -P) on $HOSTNAME by $USER -->
<!DOCTYPE PACKAGES [
  <!ELEMENT PACKAGES (PACKAGE)*>
  <!ELEMENT PACKAGE (#PCDATA)>
  <!ATTLIST PACKAGE
EOF

# List each tag as an attribute
QUERYFORMAT=
for tag in $TAGS ; do

cat <<EOF
  $tag CDATA #REQUIRED
EOF

    # Build up QUERYFORMAT for later use
    QUERYFORMAT="$QUERYFORMAT  $tag=@QUOTE@%{$tag}@QUOTE@\n"

done

cat <<EOF
  >
]>
<PACKAGES>
EOF

# For every RPM in the current directory
RPMS=$(find ${1-.} -name '*.rpm')
for rpm in $RPMS ; do

cat <<EOF
  <PACKAGE
EOF

    # Print the tags (@QUOTE@ prevents escaping of syntax)
    rpmquery --queryformat "$QUERYFORMAT" -p $rpm | xml_escape_cdata | sed -e 's/@QUOTE@/"/g'

# Print the name of the RPM
cat <<EOF
  >
  $(basename $rpm | xml_escape_pcdata)
  </PACKAGE>
EOF

done

cat <<EOF
</PACKAGES>
EOF
