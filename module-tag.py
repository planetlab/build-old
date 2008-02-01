#!/usr/bin/python -u

subversion_id = "$Id$"

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
    def output_of (self,with_stderr=False):
        tmp="/tmp/status-%d"%os.getpid()
        if self.options.debug:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        command=self.command
        if with_stderr:
            command += " &> "
        else:
            command += " > "
        command += tmp
        os.system(command)
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
        return len(Command(command,self.options).output_of(True)) != 0
    # turns out it's the same implem.
    def file_needs_commit (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of(True)) != 0

class Module:

    # where to store user's config
    config_storage="CONFIG"
    # 
    configKeys=[ ('svnpath',"Enter your toplevel svnpath (e.g. svn+ssh://thierry@svn.planet-lab.org/svn/)"),
                 ('username',"Enter your firstname and lastname for changelogs"),
                 ("email","Enter your email address for changelogs") ]
    config={}

    svn_magic_line="--This line, and those below, will be ignored--"
    
    redirectors=[ ('module_name_varname','name'),
                  ('module_version_varname','version'),
                  ('module_taglevel_varname','taglevel'), ]

    def __init__ (self,name,options):
        self.name=name
        self.options=options
        self.moddir="%s/%s"%(options.workdir,name)
        self.trunkdir="%s/trunk"%(self.moddir)
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
        topdir=options.workdir
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
        if self.options.fast_checks:
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

    def parse_spec (self, specfile, varnames):
        if self.options.debug:
            print 'parse_spec',specfile,
        result={}
        f=open(specfile)
        for line in f.readlines():
            if self.varmatcher.match(line):
                (var,value)=self.varmatcher.match(line).groups()
                if var in varnames:
                    result[var]=value
        f.close()
        if self.options.verbose:
            print 'found',len(result),'keys'
        if self.options.debug:
            for (k,v) in result.iteritems():
                print k,'=',v
        return result
                
    # stores in self.module_name_varname the rpm variable to be used for the module's name
    # and the list of these names in self.varnames
    def spec_dict (self):
        specfile=self.guess_specname()
        redirector_keys = [ varname for (varname,default) in Module.redirectors]
        redirect_dict = self.parse_spec(specfile,redirector_keys)
        if self.options.debug:
            print '1st pass parsing done, redirect_dict=',redirect_dict
        varnames=[]
        for (varname,default) in Module.redirectors:
            if redirect_dict.has_key(varname):
                setattr(self,varname,redirect_dict[varname])
                varnames += [redirect_dict[varname]]
            else:
                setattr(self,varname,default)
                varnames += [ default ] 
        self.varnames = varnames
        result = self.parse_spec (specfile,self.varnames)
        if self.options.debug:
            print '2st pass parsing done, varnames=',varnames,'result=',result
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
        exclude="Tagging module %s"%self.name
        for logline in file(logfile).readlines():
            if logline.strip() == Module.svn_magic_line:
                break
            if logline.find(exclude) < 0:
                result += [ logline ]
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
                    new.write("- " + logline)
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
        return "%s-%s-%s"%(spec_dict[self.module_name_varname],
                           spec_dict[self.module_version_varname],
                           spec_dict[self.module_taglevel_varname])
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
* it does not scan the -tags*.mk files to adopt the new tags"""
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
        if not self.options.fast_checks and Svnpath(tag_url,self.options).url_exists():
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
        diff_output = Command("svn diff %s %s"%(tag_url,trunk_url),self.options).output_of()
        if self.options.list:
            if diff_output:
                print self.name
        else:
            if not self.options.only or diff_output:
                print 'x'*40,'module',self.name
                print 'x'*20,'<',tag_url
                print 'x'*20,'>',trunk_url
                print diff_output

    def patch_tags_file (self, tagsfile, oldname, newname):
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
        # parse specfile
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # side effects
        trunk_url=self.trunk_url()
        old_tag_name = self.tag_name(spec_dict)
        old_tag_url=self.tag_url(spec_dict)
        if (self.options.new_version):
            # new version set on command line
            spec_dict[self.module_version_varname] = self.options.new_version
            spec_dict[self.module_taglevel_varname] = 0
        else:
            # increment taglevel
            new_taglevel = str ( int (spec_dict[self.module_taglevel_varname]) + 1)
            spec_dict[self.module_taglevel_varname] = new_taglevel

        # sanity check
        new_tag_name = self.tag_name(spec_dict)
        new_tag_url=self.tag_url(spec_dict)
        for url in [ trunk_url, old_tag_url ] :
            if not self.options.fast_checks and not Svnpath(url,self.options).url_exists():
                print 'Could not find svn URL %s'%url
                sys.exit(1)
        if not self.options.fast_checks and Svnpath(new_tag_url,self.options).url_exists():
            print 'New tag\'s svn URL %s already exists ! '%url
            sys.exit(1)

        # checking for diffs
        diff_output=Command("svn diff %s %s"%(old_tag_url,trunk_url),
                            self.options).output_of()
        if len(diff_output) == 0:
            if not prompt ("No difference in trunk for module %s, want to tag anyway"%self.name,False):
                return

        # side effect in trunk's specfile
        self.patch_spec_var(spec_dict)

        # prepare changelog file 
        # we use the standard subversion magic string (see svn_magic_line)
        # so we can provide useful information, such as version numbers and diff
        # in the same file
        changelog="/tmp/%s-%d.txt"%(self.name,os.getpid())
        file(changelog,"w").write("""Tagging module %s  -- from %s to %s

%s
Please write a changelog for this new tag in the section above
"""%(self.name,old_tag_name,new_tag_name,Module.svn_magic_line))

        if not self.options.verbose or prompt('Want to see diffs while writing changelog',True):
            file(changelog,"a").write('DIFF=========\n' + diff_output)
        
        if self.options.debug:
            prompt('Proceed ?')

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
        
        for tagsfile in glob(build.trunkdir+"/*-tags*.mk"):
            if prompt("Want to adopt new tag in %s"%tagsfile):
                self.patch_tags_file(tagsfile,old_tag_name,new_tag_name)

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
  OR alternatively redirection variables like module_version_varname
"""
functions={ 
    'diff' : "show difference between trunk and latest tag",
    'tag'  : """increment taglevel in specfile, insert changelog in specfile,
                create new tag and and adopt it in build/*-tags*.mk""",
    'init' : "create initial tag",
    'version' : "only check specfile and print out details"}

def main():

    if sys.argv[0].find("diff") >= 0:
        mode = "diff"
    elif sys.argv[0].find("tag") >= 0:
        mode = "tag"
    elif sys.argv[0].find("init") >= 0:
        mode = "init"
    elif sys.argv[0].find("version") >= 0:
        mode = "version"
    else:
        print "Unsupported command",sys.argv[0]
        sys.exit(1)

    global usage
    usage += "module-%s.py : %s"%(mode,functions[mode])
    all_modules=os.path.dirname(sys.argv[0])+"/modules.list"

    parser=OptionParser(usage=usage,version=subversion_id)
    parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                      help="run on all modules as found in %s"%all_modules)
    parser.add_option("-f","--fast-checks",action="store_true",dest="fast_checks",default=False,
                      help="skip safety checks, such as svn updates -- use with care")
    if mode == "tag" :
        parser.add_option("-s","--set-version",action="store",dest="new_version",default=None,
                          help="set new version and reset taglevel to 0")
    if mode == "tag" :
        parser.add_option("-c","--no-changelog", action="store_false", dest="changelog", default=True,
                          help="do not update changelog section in specfile when tagging")
    if mode == "tag" or mode == "init" :
        parser.add_option("-e","--editor", action="store", dest="editor", default="emacs",
                          help="specify editor")
    if mode == "init" :
        parser.add_option("-m","--message", action="store", dest="message", default=None,
                          help="specify log message")
    if mode == "diff" :
        parser.add_option("-o","--only", action="store_true", dest="only", default=False,
                          help="report diff only for modules that exhibit differences")
    if mode == "diff" :
        parser.add_option("-l","--list", action="store_true", dest="list", default=False,
                          help="just list modules that exhibit differences")
    parser.add_option("-w","--workdir", action="store", dest="workdir", 
                      default="%s/%s"%(os.getenv("HOME"),"modules"),
                      help="name for workdir - defaults to ~/modules")
    parser.add_option("-B","--build", action="store", dest="build", default="build",
                      help="set module name for build, defaults to build")
    parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=False, 
                      help="run in verbose mode")
    parser.add_option("-d","--debug", action="store_true", dest="debug", default=False, 
                      help="debug mode - mostly more verbose")
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
