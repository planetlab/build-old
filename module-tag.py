#!/usr/bin/env python

subversion_id = "$Id: TestMain.py 7635 2008-01-04 09:46:06Z thierry $"

import sys, os, os.path
import re
import time
from glob import glob
from optparse import OptionParser

def prompt (question,default=True):
    if default:
        question += " [y]/n ? "
    else:
        question += " y/[n] ? "
    try:
        answer=raw_input(question)
        if not answer:
            return default
        elif answer[0] in [ 'y','Y']:
            return True
        elif answer[0] in [ 'n','N']:
            return False
        else:
            return prompt(question,default)
    except KeyboardInterrupt:
        print "Aborted"
        return False
    except:
        raise

class Command:
    def __init__ (self,command,options):
        self.command=command
        self.options=options
        self.tmp="/tmp/command-%d"%os.getpid()

    def run (self):
        if self.options.verbose:
            print '+',self.command
            sys.stdout.flush()
        return os.system(self.command)

    def run_silent (self):
        if self.options.verbose:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        retcod=os.system(self.command + " &> " + self.tmp)
        if retcod != 0:
            print "FAILED ! -- output quoted below "
            os.system("cat " + self.tmp)
            print "FAILED ! -- end of quoted output"
        elif self.options.verbose:
            print "OK"
        os.unlink(self.tmp)
        return retcod

    def run_fatal(self):
        if self.run_silent() !=0:
            raise Exception,"Command %s failed"%self.command

    # returns stdout, like bash's $(mycommand)
    def output_of (self):
        tmp="/tmp/status-%d"%os.getpid()
        if self.options.debug:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        os.system(self.command + " &> " + tmp)
        result=file(tmp).read()
        os.unlink(tmp)
        if self.options.debug:
            print '+',self.command,'Done',
        return result

class Svnpath:
    def __init__(self,path,options):
        self.path=path
        self.options=options

    def url_exists (self):
        if self.options.verbose:
            print 'Checking url',self.path
        return os.system("svn list %s &> /dev/null"%self.path) == 0

    def dir_needs_revert (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of()) != 0
    # turns out it's the same implem.
    def file_needs_commit (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of()) != 0

class Module:

    # where to store user's config
    config_storage="CONFIG"
    # 
    configKeys=[ ('svnpath',"Enter your toplevel svnpath (e.g. svn+ssh://thierry@svn.planet-lab.org/svn/)"),
                 ('username',"Enter your firstname and lastname for changelogs"),
                 ("email","Enter your email address for changelogs") ]
    config={}

    svn_magic_line="--This line, and those below, will be ignored--"

    def __init__ (self,name,options):
        self.name=name
        self.options=options
        self.moddir="%s/%s/%s"%(os.getenv("HOME"),options.modules,name)
        self.trunkdir="%s/trunk"%(self.moddir)
        # what to parse in a spec file
        self.varnames = ["name",options.version,options.taglevel]
        self.varmatcher=re.compile("%define\s+(\S+)\s+(\S*)\s*")


    def run (self,command):
        return Command(command,self.options).run()
    def run_fatal (self,command):
        return Command(command,self.options).run_fatal()
    def run_prompt (self,message,command):
        if not self.options.verbose:
            question=message
        else:
            question="Want to run " + command
        if prompt(question,True):
            self.run(command)            

    @staticmethod
    def init_homedir (options):
        topdir="%s/%s"%(os.getenv("HOME"),options.modules)
        if options.verbose:
            print 'Checking for',topdir
        storage="%s/%s"%(topdir,Module.config_storage)
        if not os.path.isdir (topdir):
            # prompt for login or whatever svnpath
            print "Cannot find",topdir,"let's create it"
            for (key,message) in Module.configKeys:
                Module.config[key]=raw_input(message+" : ").strip()
            Command("svn co -N %s %s"%(Module.config['svnpath'],topdir),options).run_fatal()
            # store config
            f=file(storage,"w")
            for (key,message) in Module.configKeys:
                f.write("%s=%s\n"%(key,Module.config[key]))
            f.close()
            if options.debug:
                print 'Stored',storage
                Command("cat %s"%storage,options).run()
        else:
            # read config
            f=open(storage)
            for line in f.readlines():
                (key,value)=re.compile("^(.+)=(.+)$").match(line).groups()
                Module.config[key]=value                
            f.close()
            if options.debug:
                print 'Using config'
                for (key,message) in Module.configKeys:
                    print key,'=',Module.config[key]

    def init_moddir (self):
        if self.options.verbose:
            print 'Checking for',self.moddir
        if not os.path.isdir (self.moddir):
            self.run_fatal("svn up -N %s"%self.moddir)
        if not os.path.isdir (self.moddir):
            print 'Cannot find %s - check module name'%self.moddir
            sys.exit(1)

    def init_trunkdir (self):
        if self.options.verbose:
            print 'Checking for',self.trunkdir
        if not os.path.isdir (self.trunkdir):
            self.run_fatal("svn up -N %s"%self.trunkdir)

    def revert_trunkdir (self):
        if self.options.verbose:
            print 'Checking whether',self.trunkdir,'needs being reverted'
        if Svnpath(self.trunkdir,self.options).dir_needs_revert():
            self.run_fatal("svn revert -R %s"%self.trunkdir)

    def update_trunkdir (self):
        if self.options.skip_update:
            return
        if self.options.verbose:
            print 'Updating',self.trunkdir
        self.run_fatal("svn update %s"%self.trunkdir)

    def guess_specname (self):
        attempt="%s/%s.spec"%(self.trunkdir,self.name)
        if os.path.isfile (attempt):
            return attempt
        else:
            try:
                return glob("%s/*.spec"%self.trunkdir)[0]
            except:
                print 'Cannot guess specfile for module %s'%self.name
                sys.exit(1)

    def spec_dict (self):
        specfile=self.guess_specname()
        if self.options.verbose:
            print 'Parsing',specfile,
        result={}
        f=open(specfile)
        for line in f.readlines():
            if self.varmatcher.match(line):
                (var,value)=self.varmatcher.match(line).groups()
                if var in self.varnames:
                    result[var]=value
        f.close()
        if self.options.verbose:
            print 'found',len(result),'keys'
        return result

    def patch_spec_var (self, patch_dict):
        specfile=self.guess_specname()
        newspecfile=specfile+".new"
        if self.options.verbose:
            print 'Patching',specfile,'for',patch_dict.keys()
        spec=open (specfile)
        new=open(newspecfile,"w")

        for line in spec.readlines():
            if self.varmatcher.match(line):
                (var,value)=self.varmatcher.match(line).groups()
                if var in patch_dict.keys():
                    new.write('%%define %s %s\n'%(var,patch_dict[var]))
                    continue
            new.write(line)
        spec.close()
        new.close()
        os.rename(newspecfile,specfile)

    def unignored_lines (self, logfile):
        result=[]
        for logline in file(logfile).readlines():
            if logline.strip() == Module.svn_magic_line:
                break
            result += logline
        return result

    def insert_changelog (self, logfile, oldtag, newtag):
        specfile=self.guess_specname()
        newspecfile=specfile+".new"
        if self.options.verbose:
            print 'Inserting changelog from %s into %s'%(logfile,specfile)
        spec=open (specfile)
        new=open(newspecfile,"w")
        for line in spec.readlines():
            new.write(line)
            if re.compile('%changelog').match(line):
                dateformat="* %a %b %d %Y"
                datepart=time.strftime(dateformat)
                logpart="%s <%s> - %s %s"%(Module.config['username'],
                                             Module.config['email'],
                                             oldtag,newtag)
                new.write(datepart+" "+logpart+"\n")
                for logline in self.unignored_lines(logfile):
                    new.write(logline)
                new.write("\n")
        spec.close()
        new.close()
        os.rename(newspecfile,specfile)
            
    def show_dict (self, spec_dict):
        if self.options.verbose:
            for (k,v) in spec_dict.iteritems():
                print k,'=',v

    def trunk_url (self):
        return "%s/%s/trunk"%(Module.config['svnpath'],self.name)
    def tag_name (self, spec_dict):
        return "%s-%s-%s"%(spec_dict['name'],spec_dict[self.options.version],spec_dict[self.options.taglevel])
    def tag_url (self, spec_dict):
        return "%s/%s/tags/%s"%(Module.config['svnpath'],self.name,self.tag_name(spec_dict))

    # locate specfile, parse it, check it and show values
    def do_version (self):
        self.init_moddir()
        self.init_trunkdir()
        self.revert_trunkdir()
        self.update_trunkdir()
        print '==============================',self.name
        #for (key,message) in Module.configKeys:
        #    print key,':',Module.config[key]
        spec_dict = self.spec_dict()
        print 'trunk url',self.trunk_url()
        print 'latest tag url',self.tag_url(spec_dict)
        print 'specfile:',self.guess_specname()
        for varname in self.varnames:
            if not spec_dict.has_key(varname):
                print 'Could not find %%define for %s'%varname
                return
            else:
                print varname+":",spec_dict[varname]

    init_warning="""WARNING
The module-init function has the following limitations
* it does not handle changelogs
* it does not scan the -tags.mk files to adopt the new tags"""
    def do_init(self):
        if self.options.verbose:
            print Module.init_warning
            if not prompt('Want to proceed anyway'):
                return

        self.init_moddir()
        self.init_trunkdir()
        self.revert_trunkdir()
        self.update_trunkdir()
        spec_dict = self.spec_dict()

        trunk_url=self.trunk_url()
        tag_name=self.tag_name(spec_dict)
        tag_url=self.tag_url(spec_dict)
        # check the tag does not exist yet
        if Svnpath(tag_url,self.options).url_exists():
            print 'Module %s already has a tag %s'%(self.name,tag_name)
            return

        if self.options.message:
            svnopt='--message "%s"'%self.options.message
        else:
            svnopt='--editor-cmd=%s'%self.options.editor
        self.run_prompt("Create initial tag",
                        "svn copy %s %s %s"%(svnopt,trunk_url,tag_url))

    def do_diff (self):
        self.init_moddir()
        self.init_trunkdir()
        self.revert_trunkdir()
        self.update_trunkdir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)

        trunk_url=self.trunk_url()
        tag_url=self.tag_url(spec_dict)
        for url in [ trunk_url, tag_url ] :
            if not Svnpath(url,self.options).url_exists():
                print 'Could not find svn URL %s'%url
                sys.exit(1)

        self.run("svn diff %s %s"%(tag_url,trunk_url))

    def patch_tags_files (self, tagsfile, oldname, newname):
        newtagsfile=tagsfile+".new"
        if self.options.verbose:
            print 'Replacing %s into %s in %s'%(oldname,newname,tagsfile)
        tags=open (tagsfile)
        new=open(newtagsfile,"w")
        matcher=re.compile("^(.*)%s(.*)"%oldname)
        for line in tags.readlines():
            if not matcher.match(line):
                new.write(line)
            else:
                (begin,end)=matcher.match(line).groups()
                new.write(begin+newname+end+"\n")
        tags.close()
        new.close()
        os.rename(newtagsfile,tagsfile)

    def do_tag (self):
        self.init_moddir()
        self.init_trunkdir()
        self.revert_trunkdir()
        self.update_trunkdir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # parse specfile, check that the old tag exists and the new one does not
        trunk_url=self.trunk_url()
        old_tag_name = self.tag_name(spec_dict)
        old_tag_url=self.tag_url(spec_dict)
        # increment taglevel
        new_taglevel = str ( int (spec_dict[self.options.taglevel]) + 1)
        spec_dict[self.options.taglevel] = new_taglevel
        new_tag_name = self.tag_name(spec_dict)
        new_tag_url=self.tag_url(spec_dict)
        for url in [ trunk_url, old_tag_url ] :
            if not Svnpath(url,self.options).url_exists():
                print 'Could not find svn URL %s'%url
                sys.exit(1)
        if Svnpath(new_tag_url,self.options).url_exists():
            print 'New tag\'s svn URL %s already exists ! '%url
            sys.exit(1)

        # side effect in trunk's specfile
        self.patch_spec_var({self.options.taglevel:new_taglevel})

        # prepare changelog file 
        # we use the standard subversion magic string (see svn_magic_line)
        # so we can provide useful information, such as version numbers and diff
        # in the same file
        changelog="/tmp/%s-%d.txt"%(self.name,os.getpid())
        file(changelog,"w").write("""
%s
module %s
old tag %s
new tag %s
"""%(Module.svn_magic_line,self.name,old_tag_url,new_tag_url))

        if not self.options.verbose or prompt('Want to run diff',True):
            self.run("(echo 'DIFF========='; svn diff %s %s) >> %s"%(old_tag_url,trunk_url,changelog))
        # edit it        
        self.run("%s %s"%(self.options.editor,changelog))
        # insert changelog in spec
        if self.options.changelog:
            self.insert_changelog (changelog,old_tag_name,new_tag_name)

        ## update build
        build = Module(self.options.build,self.options)
        build.init_moddir()
        build.init_trunkdir()
        build.revert_trunkdir()
        build.update_trunkdir()
        
        for tagsfile in glob(build.trunkdir+"/*-tags.mk"):
            if prompt("Want to check %s"%tagsfile):
                self.patch_tags_files(tagsfile,old_tag_name,new_tag_name)

        paths=""
        paths += self.trunkdir + " "
        paths += build.trunkdir + " "
        self.run_prompt("Check","svn diff " + paths)
        self.run_prompt("Commit","svn commit --file %s %s"%(changelog,paths))
        self.run_prompt("Create tag","svn copy --file %s %s %s"%(changelog,trunk_url,new_tag_url))

        if self.options.debug:
            print 'Preserving',changelog
        else:
            os.unlink(changelog)
            
usage="""Usage: %prog options module1 [ .. modulen ]
Purpose:
  manage subversion tags and specfile
  requires the specfile to define name, version and taglevel
Available functions:
  module-diff : show difference between trunk and latest tag
  module-tag  : increment taglevel in specfile, insert changelog in specfile,
                create new tag and and adopt it in build/*-tags.mk
  module-init : create initial tag
  module-version : only check specfile and print out details"""

def main():
    all_modules=os.path.dirname(sys.argv[0])+"/modules.list"

    parser=OptionParser(usage=usage,version=subversion_id)
    parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                      help="Runs all modules as found in %s"%all_modules)
    parser.add_option("-e","--editor", action="store", dest="editor", default="emacs",
                      help="Specify editor")
    parser.add_option("-m","--message", action="store", dest="message", default=None,
                      help="Specify log message")
    parser.add_option("-u","--no-update",action="store_true",dest="skip_update",default=False,
                      help="Skips svn updates")
    parser.add_option("-c","--no-changelog", action="store_false", dest="changelog", default=True,
                      help="Does not update changelog section in specfile when tagging")
    parser.add_option("-M","--modules", action="store", dest="modules", default="modules",
                      help="Name for topdir - defaults to modules")
    parser.add_option("-B","--build", action="store", dest="build", default="build",
                      help="Set module name for build")
    parser.add_option("-T","--taglevel",action="store",dest="taglevel",default="taglevel",
                      help="Specify an alternate spec variable for taglevel")
    parser.add_option("-V","--version-string",action="store",dest="version",default="version",
                      help="Specify an alternate spec variable for version")
    parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=False, 
                      help="Run in verbose mode")
    parser.add_option("-d","--debug", action="store_true", dest="debug", default=False, 
                      help="Debug mode - mostly more verbose")
    (options, args) = parser.parse_args()
    if options.debug: options.verbose=True

    if len(args) == 0:
        if options.all_modules:
            args=Command("grep -v '#' %s"%all_modules,options).output_of().split()
        else:
            parser.print_help()
            sys.exit(1)
    Module.init_homedir(options)
    for modname in args:
        module=Module(modname,options)
        if sys.argv[0].find("diff") >= 0:
            module.do_diff()
        elif sys.argv[0].find("tag") >= 0:
            module.do_tag()
        elif sys.argv[0].find("init") >= 0:
            module.do_init()
        elif sys.argv[0].find("version") >= 0:
            module.do_version()
        else:
            print "Unsupported command",sys.argv[0]
            parser.print_help()
            sys.exit(1)

# basically, we exit if anything goes wrong
if __name__ == "__main__" :
    main()
