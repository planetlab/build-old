#lst files syntax:
# comments start with #

# to define packages on all fcdistros
package: p1 p2 p3 p4
# to add  packages for say fc6
package+fc6: p5 p6
# to exclude packages
package-fc6: p2 p3

# same for groups
# NOTE: white spaces are not supported any more for group names
# plc_config_devel.xml used to mention standard group names with
# spaces, but we do not use them anymore 
