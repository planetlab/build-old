#lst files syntax:
# comments start with #

# to define packages on all fcdistros
package: p1 p2 p3 p4
# to add  packages for say f9
package+f9: p5 p6
# to exclude packages
package-f9: p2 p3

# same for groups, except that you need to replace any white-space in
#  the groupname with +++, like in
group: X+++Window+++System
group: GNOME+++Desktop+++Environment
