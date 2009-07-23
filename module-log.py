#!/usr/bin/python
# -*- mode:python; var: python-guess-indent:false; python-indent:4; -*-

import os
import sys
import re
from optparse import OptionParser

modules_map = {
    'general' : [ 'build', 'tests', ],
    'server' : ['Monitor', 'MyPLC', 'PLCAPI', 'PLCRT', 'PLCWWW', 'PLEWWW', 'www-register-wizard', 
		'PXEService', 'drupal', 'plcmdline',],
    'node': [ 'linux-2.6', 'util-vserver', 'util-vserver-pl', 'chopstix-L0', 
	      'BootCD', 'BootManager', 'BootstrapFS', 'VserverReference', 
	      'DistributedRateLimiting', 'Mom', 'PingOfDeath', 
	      'NodeManager', 'NodeManager-optin', 'NodeManager-topo', 
	      'NodeUpdate', 'CoDemux', 
	      'nodeconfig', 'pl_sshd', 
	      'libnl', 'pypcilib', 'pyplnet',],
    'wifi' : ['madwifi', 'PlanetBridge', 'hostapd',],
    'emulation': ['dummynet_image', 'ipfw', ],
    'netflow' : [ 'fprobe-ulog', 'pf2gui', 'pf2monitor', 'pf2slice', 'iproute2', 'iptables', 'silk',],
    'sfa' : [ 'sfa', 'xmlrspecs', 'pyopenssl', ],
    'vsys' : ['vsys', 'vsys-scripts', 'vsys-wrappers', 'inotify-tools'],
    'deprecated' : [ 'proper', 'libhttpd++', 'oombailout', 'ulogd', 'patchdep', 'pdelta', 
		     'sandbox', 'playground', 'infrastructure', 'util-python', 'vnetspec', 
		     ],
    }

epoch='{2007-07-01}'

class ModuleHistory:

    def __init__ (self, name, options):
	self.name=name
	self.options=options
	self.user_commits=[]
	self.user_revs={}
	self.current_rev=None
	self.current_user=None
	
    valid=re.compile('\Ar[0-9]+ \|')
    tagging=re.compile('\ATagging|\ASetting tag')

    @staticmethod
    def sort ( (u1,c1), (u2,c2) ): return c2-c1

    def record(self,user,rev):
	try:
	    self.user_revs[user].append(rev)
	except:
	    self.user_revs[user] = [rev]
	self.current_rev=rev
	self.current_user=user

    def ignore(self):
	if (not self.current_user) or (not self.current_rev): return
	user_list=self.user_revs[self.current_user]
	if len(user_list) >= 1 and user_list[-1] == self.current_rev:
	    user_list.pop()

    def scan (self):
	cmd =  "svn log -r %s:%s http://svn.planet-lab.org/svn/%s " % (self.options.fromv,self.options.tov,self.name)
	if self.options.verbose:
	    print 'running',cmd
	f = os.popen(cmd)
	for line in f:
	    if not self.valid.match(line): 
		# mostly ignore commit body, except for ignoring the current commit if -i is set
		if self.options.ignore_tags and self.tagging.match(line):
		    # roll back these changes
		    self.ignore()
		continue
	    fields = line.split('|')
	    fields = [field.strip() for field in fields]
	    [rev,user,ctime,size] = fields[:4]
	    self.record(user,rev)
	# translate into a list of tuples
	user_commits = [ (user,len(revs)) for (user,revs) in self.user_revs.items() ]
	user_commits.sort(self.sort)
	self.user_commits=user_commits

    def show(self):
	if len(self.user_commits) ==0: return
	print '%s [%s-%s]'%(self.name,self.options.fromv,self.options.tov),
	if self.options.ignore_tags:
	    print ' - Ignored tag commits'
	else:
	    print ''
	for (u,c) in self.user_commits:
	    print "\t",u,c

class Aggregate:

    def __init__ (self,options):
	# key=user, value=commits
	self.options=options
	self.user_commits_dict={}
	self.user_commits=[]

    def merge (self, modulehistory):
	for (u,c) in modulehistory.user_commits:
	    try:
		self.user_commits_dict[u] += c
	    except:
		self.user_commits_dict[u] = c

    def sort (self):
	user_commits = [ (u,c) for (u,c) in self.user_commits_dict.items() ]
	user_commits.sort(ModuleHistory.sort)
	self.user_commits=user_commits
	
    def show(self):
	print 'Overall',
	if self.options.ignore_tags:
	    print ' - Ignored tag commits'
	else:
	    print ''
	for (u,c) in self.user_commits:
	    print "\t",u,c

class Modules:
    
    def __init__ (self,map):
	self.map=map

    def categories(self):
	return self.map.keys()

    def all_modules(self,categories=None):
	if not categories: categories=self.categories()
	elif not isinstance(categories,list): categories=[categories]
	result=[]
	for category in categories:
	    result += self.map[category]
	return result

    def locate (self,keywords):
	result=[]
	for kw in keywords:
	    if self.map.has_key(kw):
		result += self.map[kw]
	    else:
		result += [kw]
	return result

    def list(self,scope):
	for (cat,mod_list) in self.map.items():
	    for mod in mod_list:
		if mod in scope:
		    print cat,mod

def main ():
    usage="%prog [module_or_category ...]"
    parser = OptionParser(usage=usage)
    parser.add_option("-f", "--from", action = "store", dest='fromv',
		      default = epoch, help = "The revision to start from, default %s"%epoch)
    parser.add_option("-t", "--to", action = "store", dest='tov',
		      default = 'HEAD', help = "The revision to end with, default HEAD")
    parser.add_option("-n","--no-aggregate", action='store_false',dest='aggregate',default=True,
		      help='Do not aggregate over modules')
    parser.add_option("-v","--verbose", action='store_true',dest='verbose',default=False,
		      help='Run in verbose/debug mode')
    parser.add_option("-i","--ignore-tags",action='store_true',dest='ignore_tags',
		      help='ignore commits related to tagging')
    parser.add_option("-l","--list",action='store_true',dest='list_modules',
		      help='list available modules and categories')
    # pass this to the invoked shell if any
    (options, args) = parser.parse_args()

    map=Modules(modules_map)
    if not args:
	modules=map.all_modules()
    else:
	modules=map.locate(args)

    if options.list_modules:
	map.list(modules)
	return

    if len(modules) <=1:
	options.aggregate=False

    aggregate = Aggregate(options)
    for module in modules:
	history=ModuleHistory(module,options)
	history.scan()
	history.show()
	aggregate.merge(history)

    if options.aggregate:
	aggregate.sort()
	aggregate.show()

if __name__ == '__main__':
    main()
