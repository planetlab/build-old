#!/usr/bin/python -u

subversion_id = "$Id$"

import sys, os, os.path
import re
import time
from glob import glob
from optparse import OptionParser

# e.g. other_choices = [ ('d','iff') , ('g','uess') ] - lowercase 
def prompt (question,default=True,other_choices=[],allow_outside=False):
    if not isinstance (other_choices,list):
        other_choices = [ other_choices ]
    chars = [ c for (c,rest) in other_choices ]

    choices = []
    if 'y' not in chars:
        if default is True: choices.append('[y]')
        else : choices.append('y')
    if 'n' not in chars:
        if default is False: choices.append('[n]')
        else : choices.append('n')

    for (char,choice) in other_choices:
        if default == char:
            choices.append("["+char+"]"+choice)
        else:
            choices.append("<"+char+">"+choice)
    try:
        answer=raw_input(question + " " + "/".join(choices) + " ? ")
        if not answer:
            return default
        answer=answer[0].lower()
        if answer == 'y':
            if 'y' in chars: return 'y'
            else: return True
        elif answer == 'n':
            if 'n' in chars: return 'n'
            else: return False
        elif other_choices:
            for (char,choice) in other_choices:
                if answer == char:
                    return char
            if allow_outside:
                return answer
        return prompt(question,default,other_choices)
    except:
        raise

def default_editor():
    try:
        editor = os.environ['EDITOR']
    except:
        editor = "emacs"
    return editor

### fold long lines
fold_length=132

def print_fold (line):
    while len(line) >= fold_length:
        print line[:fold_length],'\\'
        line=line[fold_length:]
    print line

class Command:
    def __init__ (self,command,options):
        self.command=command
        self.options=options
        self.tmp="/tmp/command-%d"%os.getpid()

    def run (self):
        if self.options.dry_run:
            print 'dry_run',self.command
            return 0
        if self.options.verbose and self.options.mode not in Main.silent_modes:
            print '+',self.command
            sys.stdout.flush()
        return os.system(self.command)

    def run_silent (self):
        if self.options.dry_run:
            print 'dry_run',self.command
            return 0
        if self.options.verbose:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        retcod=os.system(self.command + " &> " + self.tmp)
        if retcod != 0:
            print "FAILED ! -- out+err below (command was %s)"%self.command
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
        if self.options.dry_run:
            print 'dry_run',self.command
            return 'dry_run output'
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
            print 'Done',
        return result

class Svnpath:
    def __init__(self,path,options):
        self.path=path
        self.options=options

    def url_exists (self):
        return os.system("svn list %s &> /dev/null"%self.path) == 0

    def dir_needs_revert (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of(True)) != 0
    # turns out it's the same implem.
    def file_needs_commit (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of(True)) != 0

# support for tagged module is minimal, and is for the Build class only
class Module:

    svn_magic_line="--This line, and those below, will be ignored--"
    setting_tag_format = "Setting tag %s"
    
    redirectors=[ # ('module_name_varname','name'),
                  ('module_version_varname','version'),
                  ('module_taglevel_varname','taglevel'), ]

    # where to store user's config
    config_storage="CONFIG"
    # 
    config={}

    import commands
    configKeys=[ ('svnpath',"Enter your toplevel svnpath",
                  "svn+ssh://%s@svn.planet-lab.org/svn/"%commands.getoutput("id -un")),
                 ("build", "Enter the name of your build module","build"),
                 ('username',"Enter your firstname and lastname for changelogs",""),
                 ("email","Enter your email address for changelogs",""),
                 ]

    @staticmethod
    def prompt_config ():
        for (key,message,default) in Module.configKeys:
            Module.config[key]=""
            while not Module.config[key]:
                Module.config[key]=raw_input("%s [%s] : "%(message,default)).strip() or default


    # for parsing module spec name:branch
    matcher_branch_spec=re.compile("\A(?P<name>[\w\.-]+):(?P<branch>[\w\.-]+)\Z")
    # special form for tagged module - for Build
    matcher_tag_spec=re.compile("\A(?P<name>[\w-]+)@(?P<tagname>[\w\.-]+)\Z")
    # parsing specfiles
    matcher_rpm_define=re.compile("%(define|global)\s+(\S+)\s+(\S*)\s*")

    def __init__ (self,module_spec,options):
        # parse module spec
        attempt=Module.matcher_branch_spec.match(module_spec)
        if attempt:
            self.name=attempt.group('name')
            self.branch=attempt.group('branch')
        else:
            attempt=Module.matcher_tag_spec.match(module_spec)
            if attempt:
                self.name=attempt.group('name')
                self.tagname=attempt.group('tagname')
            else:
                self.name=module_spec

        self.options=options
        self.module_dir="%s/%s"%(options.workdir,self.name)

    def friendly_name (self):
        if hasattr(self,'branch'):
            return "%s:%s"%(self.name,self.branch)
        elif hasattr(self,'tagname'):
            return "%s@%s"%(self.name,self.tagname)
        else:
            return self.name

    def edge_dir (self):
        if hasattr(self,'branch'):
            return "%s/branches/%s"%(self.module_dir,self.branch)
        elif hasattr(self,'tagname'):
            return "%s/tags/%s"%(self.module_dir,self.tagname)
        else:
            return "%s/trunk"%(self.module_dir)

    def tags_dir (self):
        return "%s/tags"%(self.module_dir)

    def run (self,command):
        return Command(command,self.options).run()
    def run_fatal (self,command):
        return Command(command,self.options).run_fatal()
    def run_prompt (self,message,command):
        if not self.options.verbose:
            while True:
                choice=prompt(message,True,('s','how'))
                if choice is True:
                    self.run(command)
                    return
                elif choice is False:
                    return
                else:
                    print 'About to run:',command
        else:
            question=message+" - want to run " + command
            if prompt(question,True):
                self.run(command)            

    ####################
    # store and restitute html fragments
    @staticmethod 
    def html_href (url,text): return '<a href="%s">%s</a>'%(url,text)
    @staticmethod 
    def html_anchor (url,text): return '<a name="%s">%s</a>'%(url,text)
    # there must be some smarter means to do that - dirty for now
    @staticmethod
    def html_quote (text):
        return text.replace('&','&#38;').replace('<','&lt;').replace('>','&gt;')

    # only the fake error module has multiple titles
    def html_store_title (self, title):
        if not hasattr(self,'titles'): self.titles=[]
        self.titles.append(title)
    def html_store_raw (self, html):
        if not hasattr(self,'body'): self.body=''
        self.body += html
    def html_store_pre (self, text):
        if not hasattr(self,'body'): self.body=''
        self.body += '<pre>' + self.html_quote(text) + '</pre>'

    def html_print (self, txt):
        if not self.options.www:
            print txt
        else:
            if not hasattr(self,'in_list') or not self.in_list:
                self.html_store_raw('<ul>')
                self.in_list=True
            self.html_store_raw('<li>'+txt+'</li>')
    def html_print_end (self):
        if self.options.www:
            self.html_store_raw ('</ul>')

    @staticmethod
    def html_dump_header(title):
        nowdate=time.strftime("%Y-%m-%d")
        nowtime=time.strftime("%H:%M")
        print """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title> %s </title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type="text/css">
body { font-family:georgia, serif; }
h1 {font-size: large; }
p.title {font-size: x-large; }
span.error {text-weight:bold; color: red; }
</style>
</head>
<body>
<p class='title'> %s - status on %s at %s</p>
<ul>
"""%(title,title,nowdate,nowtime)

    @staticmethod
    def html_dump_middle():
        print "</ul>"

    @staticmethod
    def html_dump_footer():
        print "</body></html"

    def html_dump_toc(self):
        if hasattr(self,'titles'):
            for title in self.titles:
                print '<li>',self.html_href ('#'+self.friendly_name(),title),'</li>'

    def html_dump_body(self):
        if hasattr(self,'titles'):
            for title in self.titles:
                print '<hr /><h1>',self.html_anchor(self.friendly_name(),title),'</h1>'
        if hasattr(self,'body'):
            print self.body
            print '<p class="top">',self.html_href('#','Back to top'),'</p>'

    ####################
    @staticmethod
    def init_homedir (options):
        topdir=options.workdir
        if options.verbose and options.mode not in Main.silent_modes:
            print 'Checking for',topdir
        storage="%s/%s"%(topdir,Module.config_storage)
        # sanity check. Either the topdir exists AND we have a config/storage
        # or topdir does not exist and we create it
        # to avoid people use their own daily svn repo
        if os.path.isdir(topdir) and not os.path.isfile(storage):
            print """The directory %s exists and has no CONFIG file
If this is your regular working directory, please provide another one as the
module-* commands need a fresh working dir. Make sure that you do not use 
that for other purposes than tagging"""%topdir
            sys.exit(1)
        if not os.path.isdir (topdir):
            print "Cannot find",topdir,"let's create it"
            Module.prompt_config()
            print "Checking ...",
            Command("svn co -N %s %s"%(Module.config['svnpath'],topdir),options).run_fatal()
            Command("svn co %s/%s %s/%s"%(Module.config['svnpath'],
                                             Module.config['build'],
                                             topdir,
                                             Module.config['build']),options).run_fatal()
            print "OK"
            
            # store config
            f=file(storage,"w")
            for (key,message,default) in Module.configKeys:
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
        if options.verbose and options.mode not in Main.silent_modes:
            print '******** Using config'
            for (key,message,default) in Module.configKeys:
                print '\t',key,'=',Module.config[key]

    def init_module_dir (self):
        if self.options.verbose:
            print 'Checking for',self.module_dir
        if not os.path.isdir (self.module_dir):
            self.run_fatal("svn update -N %s"%self.module_dir)
        if not os.path.isdir (self.module_dir):
            raise Exception, 'Cannot find %s - check module name'%self.module_dir

    def init_subdir (self,fullpath, deep=False):
        if self.options.verbose:
            print 'Checking for',fullpath
        opt=""
        if not deep: opt="-N"
        if not os.path.isdir (fullpath):
            self.run_fatal("svn update %s %s"%(opt,fullpath))

    def revert_subdir (self,fullpath):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping revert of %s'%fullpath
            return
        if self.options.verbose:
            print 'Checking whether',fullpath,'needs being reverted'
        if Svnpath(fullpath,self.options).dir_needs_revert():
            self.run_fatal("svn revert -R %s"%fullpath)

    def update_subdir (self,fullpath):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping update of %s'%fullpath
            return
        if self.options.verbose:
            print 'Updating',fullpath
        self.run_fatal("svn update %s"%fullpath)

    def init_edge_dir (self):
        # if branch, edge_dir is two steps down
        if hasattr(self,'branch'):
            self.init_subdir("%s/branches"%self.module_dir,deep=False)
        elif hasattr(self,'tagname'):
            self.init_subdir("%s/tags"%self.module_dir,deep=False)
        self.init_subdir(self.edge_dir(),deep=True)

    def revert_edge_dir (self):
        self.revert_subdir(self.edge_dir())

    def update_edge_dir (self):
        self.update_subdir(self.edge_dir())

    def main_specname (self):
        attempt="%s/%s.spec"%(self.edge_dir(),self.name)
        if os.path.isfile (attempt):
            return attempt
        pattern1="%s/*.spec"%self.edge_dir()
        level1=glob(pattern1)
        if level1:
            return level1[0]
        pattern2="%s/*/*.spec"%self.edge_dir()
        level2=glob(pattern2)
        if level2:
            return level2[0]
        raise Exception, 'Cannot guess specfile for module %s -- patterns were %s or %s'%(self.name,pattern1,pattern2)

    def all_specnames (self):
        level1=glob("%s/*.spec"%self.edge_dir())
        if level1: return level1
        level2=glob("%s/*/*.spec"%self.edge_dir())
        return level2

    def parse_spec (self, specfile, varnames):
        if self.options.verbose:
            print 'Parsing',specfile,
            for var in varnames:
                print "[%s]"%var,
            print ""
        result={}
        f=open(specfile)
        for line in f.readlines():
            attempt=Module.matcher_rpm_define.match(line)
            if attempt:
                (define,var,value)=attempt.groups()
                if var in varnames:
                    result[var]=value
        f.close()
        if self.options.debug:
            print 'found',len(result),'keys'
            for (k,v) in result.iteritems():
                print k,'=',v
        return result
                
    # stores in self.module_name_varname the rpm variable to be used for the module's name
    # and the list of these names in self.varnames
    def spec_dict (self):
        specfile=self.main_specname()
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

    def patch_spec_var (self, patch_dict,define_missing=False):
        for specfile in self.all_specnames():
            # record the keys that were changed
            changed = dict ( [ (x,False) for x in patch_dict.keys() ] )
            newspecfile=specfile+".new"
            if self.options.verbose:
                print 'Patching',specfile,'for',patch_dict.keys()
            spec=open (specfile)
            new=open(newspecfile,"w")

            for line in spec.readlines():
                attempt=Module.matcher_rpm_define.match(line)
                if attempt:
                    (define,var,value)=attempt.groups()
                    if var in patch_dict.keys():
                        if self.options.debug:
                            print 'rewriting %s as %s'%(var,patch_dict[var])
                        new.write('%%%s %s %s\n'%(define,var,patch_dict[var]))
                        changed[var]=True
                        continue
                new.write(line)
            if define_missing:
                for (key,was_changed) in changed.iteritems():
                    if not was_changed:
                        if self.options.debug:
                            print 'rewriting missing %s as %s'%(key,patch_dict[key])
                        new.write('\n%%define %s %s\n'%(key,patch_dict[key]))
            spec.close()
            new.close()
            os.rename(newspecfile,specfile)

    # returns all lines until the magic line
    def unignored_lines (self, logfile):
        result=[]
        white_line_matcher = re.compile("\A\s*\Z")
        for logline in file(logfile).readlines():
            if logline.strip() == Module.svn_magic_line:
                break
            elif white_line_matcher.match(logline):
                continue
            else:
                result.append(logline.strip()+'\n')
        return result

    # creates a copy of the input with only the unignored lines
    def stripped_magic_line_filename (self, filein, fileout ,new_tag_name):
       f=file(fileout,'w')
       f.write(self.setting_tag_format%new_tag_name + '\n')
       for line in self.unignored_lines(filein):
           f.write(line)
       f.close()

    def insert_changelog (self, logfile, oldtag, newtag):
        for specfile in self.all_specnames():
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
                    logpart="%s <%s> - %s"%(Module.config['username'],
                                                 Module.config['email'],
                                                 newtag)
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

    def mod_url (self):
        return "%s/%s"%(Module.config['svnpath'],self.name)

    def edge_url (self):
        if hasattr(self,'branch'):
            return "%s/branches/%s"%(self.mod_url(),self.branch)
        elif hasattr(self,'tagname'):
            return "%s/tags/%s"%(self.mod_url(),self.tagname)
        else:
            return "%s/trunk"%(self.mod_url())

    def last_tag (self, spec_dict):
        return "%s-%s"%(spec_dict[self.module_version_varname],spec_dict[self.module_taglevel_varname])

    def tag_name (self, spec_dict):
        try:
            return "%s-%s"%(self.name,
                            self.last_tag(spec_dict))
        except KeyError,err:
            raise Exception, 'Something is wrong with module %s, cannot determine %s - exiting'%(self.name,err)

    def tag_url (self, spec_dict):
        return "%s/tags/%s"%(self.mod_url(),self.tag_name(spec_dict))

    def check_svnpath_exists (self, url, message):
        if self.options.fast_checks:
            return
        if self.options.verbose:
            print 'Checking url (%s) %s'%(url,message),
        ok=Svnpath(url,self.options).url_exists()
        if ok:
            if self.options.verbose: print 'exists - OK'
        else:
            if self.options.verbose: print 'KO'
            raise Exception, 'Could not find %s URL %s'%(message,url)

    def check_svnpath_not_exists (self, url, message):
        if self.options.fast_checks:
            return
        if self.options.verbose:
            print 'Checking url (%s) %s'%(url,message),
        ok=not Svnpath(url,self.options).url_exists()
        if ok:
            if self.options.verbose: print 'does not exist - OK'
        else:
            if self.options.verbose: print 'KO'
            raise Exception, '%s URL %s already exists - exiting'%(message,url)

    # locate specfile, parse it, check it and show values

##############################
    def do_version (self):
        self.init_module_dir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()
        if self.options.www:
            self.html_store_title('Version for module %s (%s)' % (self.friendly_name(),self.last_tag(spec_dict)))
        for varname in self.varnames:
            if not spec_dict.has_key(varname):
                self.html_print ('Could not find %%define for %s'%varname)
                return
            else:
                self.html_print ("%-16s %s"%(varname,spec_dict[varname]))
        if self.options.show_urls:
            self.html_print ("%-16s %s"%('edge url',self.edge_url()))
            self.html_print ("%-16s %s"%('latest tag url',self.tag_url(spec_dict)))
        if self.options.verbose:
            self.html_print ("%-16s %s"%('main specfile:',self.main_specname()))
            self.html_print ("%-16s %s"%('specfiles:',self.all_specnames()))
        self.html_print_end()

##############################
    def do_list (self):
#        print 'verbose',self.options.verbose
#        print 'list_tags',self.options.list_tags
#        print 'list_branches',self.options.list_branches
#        print 'all_modules',self.options.all_modules
        
        (verbose,branches,pattern,exact) = (self.options.verbose,self.options.list_branches,
                                            self.options.list_pattern,self.options.list_exact)

        extra_command=""
        extra_message=""
        if hasattr(self,'branch'):
            pattern=self.branch
        if pattern or exact:
            if exact:
                if verbose: grep="%s/$"%exact
                else: grep="^%s$"%exact
            else:
                grep=pattern
            extra_command=" | grep %s"%grep
            extra_message=" matching %s"%grep

        if not branches:
            message="==================== tags for %s"%self.friendly_name()
            command="svn list "
            if verbose: command+="--verbose "
            command += "%s/tags"%self.mod_url()
            command += extra_command
            message += extra_message
            if verbose: print message
            self.run(command)

        else:
            message="==================== branches for %s"%self.friendly_name()
            command="svn list "
            if verbose: command+="--verbose "
            command += "%s/branches"%self.mod_url()
            command += extra_command
            message += extra_message
            if verbose: print message
            self.run(command)

##############################
    sync_warning="""*** WARNING
The module-sync function has the following limitations
* it does not handle changelogs
* it does not scan the -tags*.mk files to adopt the new tags"""

    def do_sync(self):
        if self.options.verbose:
            print Module.sync_warning
            if not prompt('Want to proceed anyway'):
                return

        self.init_module_dir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()

        edge_url=self.edge_url()
        tag_name=self.tag_name(spec_dict)
        tag_url=self.tag_url(spec_dict)
        # check the tag does not exist yet
        self.check_svnpath_not_exists(tag_url,"new tag")

        if self.options.message:
            svnopt='--message "%s"'%self.options.message
        else:
            svnopt='--editor-cmd=%s'%self.options.editor
        self.run_prompt("Create initial tag",
                        "svn copy %s %s %s"%(svnopt,edge_url,tag_url))

##############################
    def do_diff (self,compute_only=False):
        self.init_module_dir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)

        edge_url=self.edge_url()
        tag_url=self.tag_url(spec_dict)
        self.check_svnpath_exists(edge_url,"edge track")
        self.check_svnpath_exists(tag_url,"latest tag")
        command="svn diff %s %s"%(tag_url,edge_url)
        if compute_only:
            if self.options.verbose:
                print 'Getting diff with %s'%command
        diff_output = Command(command,self.options).output_of()
        # if used as a utility
        if compute_only:
            return (spec_dict,edge_url,tag_url,diff_output)
        # otherwise print the result
        if self.options.list:
            if diff_output:
                print self.name
        else:
            thename=self.friendly_name()
            do_print=False
            if self.options.www and diff_output:
                self.html_store_title("Diffs in module %s (%s) : %d chars"%(\
                        thename,self.last_tag(spec_dict),len(diff_output)))
                link=self.html_href(tag_url,tag_url)
                self.html_store_raw ('<p> &lt; (left) %s </p>'%link)
                link=self.html_href(edge_url,edge_url)
                self.html_store_raw ('<p> &gt; (right) %s </p>'%link)
                self.html_store_pre (diff_output)
            elif not self.options.www:
                print 'x'*30,'module',thename
                print 'x'*20,'<',tag_url
                print 'x'*20,'>',edge_url
                print diff_output

##############################
    # using fine_grain means replacing only those instances that currently refer to this tag
    # otherwise, <module>-SVNPATH is replaced unconditionnally
    def patch_tags_file (self, tagsfile, oldname, newname,fine_grain=True):
        newtagsfile=tagsfile+".new"
        tags=open (tagsfile)
        new=open(newtagsfile,"w")

        matches=0
        # fine-grain : replace those lines that refer to oldname
        if fine_grain:
            if self.options.verbose:
                print 'Replacing %s into %s\n\tin %s .. '%(oldname,newname,tagsfile),
            matcher=re.compile("^(.*)%s(.*)"%oldname)
            for line in tags.readlines():
                if not matcher.match(line):
                    new.write(line)
                else:
                    (begin,end)=matcher.match(line).groups()
                    new.write(begin+newname+end+"\n")
                    matches += 1
        # brute-force : change uncommented lines that define <module>-SVNPATH
        else:
            if self.options.verbose:
                print 'Searching for -SVNPATH lines referring to /%s/\n\tin %s .. '%(self.name,tagsfile),
            pattern="\A\s*(?P<make_name>[^\s]+)-SVNPATH\s*(=|:=)\s*(?P<url_main>[^\s]+)/%s/[^\s]+"\
                                          %(self.name)
            matcher_module=re.compile(pattern)
            for line in tags.readlines():
                attempt=matcher_module.match(line)
                if attempt:
                    svnpath="%s-SVNPATH"%(attempt.group('make_name'))
                    if self.options.verbose:
                        print ' '+svnpath, 
                    replacement = "%-32s:= %s/%s/tags/%s\n"%(svnpath,attempt.group('url_main'),self.name,newname)
                    new.write(replacement)
                    matches += 1
                else:
                    new.write(line)
        tags.close()
        new.close()
        os.rename(newtagsfile,tagsfile)
        if self.options.verbose: print "%d changes"%matches
        return matches

    def do_tag (self):
        self.init_module_dir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        # parse specfile
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # side effects
        edge_url=self.edge_url()
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
        self.check_svnpath_exists (edge_url,"edge track")
        self.check_svnpath_exists (old_tag_url,"previous tag")
        self.check_svnpath_not_exists (new_tag_url,"new tag")

        # checking for diffs
        diff_output=Command("svn diff %s %s"%(old_tag_url,edge_url),
                            self.options).output_of()
        if len(diff_output) == 0:
            if not prompt ("No pending difference in module %s, want to tag anyway"%self.name,False):
                return

        # side effect in trunk's specfile
        self.patch_spec_var(spec_dict)

        # prepare changelog file 
        # we use the standard subversion magic string (see svn_magic_line)
        # so we can provide useful information, such as version numbers and diff
        # in the same file
        changelog="/tmp/%s-%d.edit"%(self.name,os.getpid())
        changelog_svn="/tmp/%s-%d.svn"%(self.name,os.getpid())
        setting_tag_line=Module.setting_tag_format%new_tag_name
        file(changelog,"w").write("""
%s
%s
Please write a changelog for this new tag in the section above
"""%(Module.svn_magic_line,setting_tag_line))

        if not self.options.verbose or prompt('Want to see diffs while writing changelog',True):
            file(changelog,"a").write('DIFF=========\n' + diff_output)
        
        if self.options.debug:
            prompt('Proceed ?')

        # edit it        
        self.run("%s %s"%(self.options.editor,changelog))
        # strip magic line in second file - looks like svn has changed its magic line with 1.6
        # so we do the job ourselves
        self.stripped_magic_line_filename(changelog,changelog_svn,new_tag_name)
        # insert changelog in spec
        if self.options.changelog:
            self.insert_changelog (changelog,old_tag_name,new_tag_name)

        ## update build
        try:
            buildname=Module.config['build']
        except:
            buildname="build"
        if self.options.build_branch:
            buildname+=":"+self.options.build_branch
        build = Module(buildname,self.options)
        build.init_module_dir()
        build.init_edge_dir()
        build.revert_edge_dir()
        build.update_edge_dir()
        
        tagsfiles=glob(build.edge_dir()+"/*-tags*.mk")
        tagsdict=dict( [ (x,'todo') for x in tagsfiles ] )
        default_answer = 'y'
        tagsfiles.sort()
        while True:
            for tagsfile in tagsfiles:
                status=tagsdict[tagsfile]
                basename=os.path.basename(tagsfile)
                print ".................... Dealing with %s"%basename
                while tagsdict[tagsfile] == 'todo' :
                    choice = prompt ("insert %s in %s    "%(new_tag_name,basename),default_answer,
                                     [ ('y','es'), ('n', 'ext'), ('f','orce'), 
                                       ('d','iff'), ('r','evert'), ('c', 'at'), ('h','elp') ] ,
                                     allow_outside=True)
                    if choice == 'y':
                        self.patch_tags_file(tagsfile,old_tag_name,new_tag_name,fine_grain=True)
                    elif choice == 'n':
                        print 'Done with %s'%os.path.basename(tagsfile)
                        tagsdict[tagsfile]='done'
                    elif choice == 'f':
                        self.patch_tags_file(tagsfile,old_tag_name,new_tag_name,fine_grain=False)
                    elif choice == 'd':
                        self.run("svn diff %s"%tagsfile)
                    elif choice == 'r':
                        self.run("svn revert %s"%tagsfile)
                    elif choice == 'c':
                        self.run("cat %s"%tagsfile)
                    else:
                        name=self.name
                        print """y: change %(name)s-SVNPATH only if it currently refers to %(old_tag_name)s
f: unconditionnally change any line that assigns %(name)s-SVNPATH to using %(new_tag_name)s
d: show current diff for this tag file
r: revert that tag file
c: cat the current tag file
n: move to next file"""%locals()

            if prompt("Want to review changes on tags files",False):
                tagsdict = dict ( [ (x, 'todo') for x in tagsfiles ] )
                default_answer='d'
            else:
                break

        paths=""
        paths += self.edge_dir() + " "
        paths += build.edge_dir() + " "
        self.run_prompt("Review module and build","svn diff " + paths)
        self.run_prompt("Commit module and build","svn commit --file %s %s"%(changelog_svn,paths))
        self.run_prompt("Create tag","svn copy --file %s %s %s"%(changelog_svn,edge_url,new_tag_url))

        if self.options.debug:
            print 'Preserving',changelog,'and stripped',changelog_svn
        else:
            os.unlink(changelog)
            os.unlink(changelog_svn)
            
##############################
    def do_branch (self):

        # save self.branch if any, as a hint for the new branch 
        # do this before anything else and restore .branch to None, 
        # as this is part of the class's logic
        new_trunk_name=None
        if hasattr(self,'branch'):
            new_trunk_name=self.branch
            del self.branch
        elif self.options.new_version:
            new_trunk_name = self.options.new_version

        # compute diff - a way to initialize the whole stuff
        # do_diff already does edge_dir initialization
        # and it checks that edge_url and tag_url exist as well
        (spec_dict,edge_url,tag_url,diff_listing) = self.do_diff(compute_only=True)

        # the version name in the trunk becomes the new branch name
        branch_name = spec_dict[self.module_version_varname]

        # figure new branch name (the one for the trunk) if not provided on the command line
        if not new_trunk_name:
            # heuristic is to assume 'version' is a dot-separated name
            # we isolate the rightmost part and try incrementing it by 1
            version=spec_dict[self.module_version_varname]
            try:
                m=re.compile("\A(?P<leftpart>.+)\.(?P<rightmost>[^\.]+)\Z")
                (leftpart,rightmost)=m.match(version).groups()
                incremented = int(rightmost)+1
                new_trunk_name="%s.%d"%(leftpart,incremented)
            except:
                raise Exception, 'Cannot figure next branch name from %s - exiting'%version

        # record starting point tagname
        latest_tag_name = self.tag_name(spec_dict)

        print "**********"
        print "Using starting point %s (%s)"%(tag_url,latest_tag_name)
        print "Creating branch %s  &  moving trunk to %s"%(branch_name,new_trunk_name)
        print "**********"

        # print warning if pending diffs
        if diff_listing:
            print """*** WARNING : Module %s has pending diffs on its trunk
It is safe to proceed, but please note that branch %s
will be based on latest tag %s and *not* on the current trunk"""%(self.name,branch_name,latest_tag_name)
            while True:
                answer = prompt ('Are you sure you want to proceed with branching',True,('d','iff'))
                if answer is True:
                    break
                elif answer is False:
                    raise Exception,"User quit"
                elif answer == 'd':
                    print '<<<< %s'%tag_url
                    print '>>>> %s'%edge_url
                    print diff_listing

        branch_url = "%s/%s/branches/%s"%(Module.config['svnpath'],self.name,branch_name)
        self.check_svnpath_not_exists (branch_url,"new branch")
        
        # patching trunk
        spec_dict[self.module_version_varname]=new_trunk_name
        spec_dict[self.module_taglevel_varname]='0'
        # remember this in the trunk for easy location of the current branch
        spec_dict['module_current_branch']=branch_name
        self.patch_spec_var(spec_dict,True)
        
        # create commit log file
        tmp="/tmp/branching-%d"%os.getpid()
        f=open(tmp,"w")
        f.write("Branch %s for module %s created (as new trunk) from tag %s\n"%(new_trunk_name,self.name,latest_tag_name))
        f.close()

        # review the renumbering changes in trunk
        command="svn diff %s"%self.edge_dir()
        self.run_prompt("Review (renumbering) changes in trunk",command)
        # create branch
        command="svn copy --file %s %s %s"%(tmp,tag_url,branch_url)
        self.run_prompt("Create branch",command)
        # commit trunk
        command="svn commit --file %s %s"%(tmp,self.edge_dir())
        self.run_prompt("Commit trunk",command)
        # create initial tag for the new trunk
        new_tag_url=self.tag_url(spec_dict)
        command="svn copy --file %s %s %s"%(tmp,tag_url,new_tag_url)
        self.run_prompt("Create initial tag in trunk",command)
        os.unlink(tmp)
        # print message about SVNBRANCH
        print """You might now wish to review your tags files
Please make sure you mention as appropriate 
%s-SVNBRANCH := %s""" %(self.name,branch_name)

##############################
class Package:

    def __init__(self, package, module, svnpath, spec):
        self.package=package
        self.module=module
        self.svnrev = None
        self.svnpath=svnpath    
        if svnpath.rfind('@') > 0:
            self.svnpath, self.svnrev = svnpath.split('@')
        self.spec=spec
        self.specpath="%s/%s"%(self.svnpath,self.spec)
        if self.svnrev:
            self.specpath += "@%s" % self.svnrev
        self.basename=os.path.basename(svnpath)

    # returns a http URL to the trac path where full diff can be viewed (between self and pkg)
    # typically http://svn.planet-lab.org/changeset?old_path=Monitor%2Ftags%2FMonitor-1.0-7&new_path=Monitor%2Ftags%2FMonitor-1.0-13
    # xxx quick & dirty: rough url parsing 
    def trac_full_diff (self, pkg):
        matcher=re.compile("\A(?P<method>.*)://(?P<hostname>[^/]+)/(svn/)?(?P<path>.*)\Z")
        self_match=matcher.match(self.svnpath)
        pkg_match=matcher.match(pkg.svnpath)
        if self_match and pkg_match:
            (method,hostname,svn,path)=self_match.groups()
            self_path=path.replace("/","%2F")
            pkg_path=pkg_match.group('path').replace("/","%2F")
            return "%s://%s/changeset?old_path=%s&new_path=%s"%(method,hostname,self_path,pkg_path)
        else:
            return None

    def details (self):
        return "[%s %s] [%s (spec)]"%(self.svnpath,self.basename,self.specpath)

class Build (Module):
    
    # we cannot get build's svnpath as for other packages as we'd get something in svn+ssh
    # xxx quick & dirty
    def __init__ (self, buildtag,options):
        self.buildtag=buildtag
        # if the buildtag start with a : (to use a branch rather than a tag)
        if buildtag.find(':') == 0 : 
            module_name="build%(buildtag)s"%locals()
            self.display=buildtag[1:]
            self.svnpath="http://svn.planet-lab.org/svn/build/branches/%s"%self.display
        else : 
            module_name="build@%(buildtag)s"%locals()
            self.display=buildtag
            self.svnpath="http://svn.planet-lab.org/svn/build/tags/%s"%self.buildtag
        Module.__init__(self,module_name,options)

    @staticmethod
    def get_distro_from_distrotag (distrotag):
        # mhh: remove -tag* from distrotags to get distro
        n=distrotag.find('-tag')
        if n>0:
            return distrotag[:n]
        else:
            return None

    def get_packages (self,distrotag):
        result={}
        distro=Build.get_distro_from_distrotag(distrotag)
        if not distro:
            return result
        make_options="--no-print-directory -C %s stage1=true PLDISTRO=%s PLDISTROTAGS=%s 2> /dev/null"%(self.edge_dir(),distro,distrotag)
        command="make %s packages"%make_options
        make_packages=Command(command,self.options).output_of()
        pkg_line=re.compile("\Apackage=(?P<package>[^\s]+)\s+ref_module=(?P<module>[^\s]+)\s.*\Z")
        for line in make_packages.split("\n"):
            if not line:
                continue
            attempt=pkg_line.match(line)
            if line and not attempt:
                print "====="
                print "WARNING: line not understood from make packages"
                print "in dir %s"%self.edge_dir
                print "with options",make_options
                print 'line=',line
                print "====="
            else:
                (package,module) = (attempt.group('package'),attempt.group('module')) 
                command="make %s +%s-SVNPATH"%(make_options,module)
                svnpath=Command(command,self.options).output_of().strip()
                command="make %s +%s-SPEC"%(make_options,package)
                spec=Command(command,self.options).output_of().strip()
                result[package]=Package(package,module,svnpath,spec)
        return result

    def get_distrotags (self):
        return [os.path.basename(p) for p in glob("%s/*tags*mk"%self.edge_dir())]

class DiffCache:

    def __init__ (self):
        self._cache={}

    def key(self, frompath,topath):
        return frompath+'-to-'+topath

    def fetch (self, frompath, topath):
        key=self.key(frompath,topath)
        if not self._cache.has_key(key):
            return None
        return self._cache[key]

    def store (self, frompath, topath, diff):
        key=self.key(frompath,topath)
        self._cache[key]=diff

class Release:

    # header in diff output
    discard_matcher=re.compile("\A(\+\+\+|---).*")

    @staticmethod
    def do_changelog (buildtag_new,buildtag_old,options):
        print "----"
        print "----"
        print "----"
        (build_new,build_old) = (Build (buildtag_new,options), Build (buildtag_old,options))
        print "= build tag %s to %s = #build-%s"%(build_old.display,build_new.display,build_new.display)
        for b in (build_new,build_old):
            b.init_module_dir()
            b.init_edge_dir()
            b.update_edge_dir()
        # find out the tags files that are common, unless option was specified
        if options.distrotags:
            distrotags=options.distrotags
        else:
            distrotags_new=build_new.get_distrotags()
            distrotags_old=build_old.get_distrotags()
            distrotags = list(set(distrotags_new).intersection(set(distrotags_old)))
            distrotags.sort()
        if options.verbose: print "Found distrotags",distrotags
        first_distrotag=True
        diffcache = DiffCache()
        for distrotag in distrotags:
            distro=Build.get_distro_from_distrotag(distrotag)
            if not distro:
                continue
            if first_distrotag:
                first_distrotag=False
            else:
                print '----'
            print '== distro %s (%s to %s) == #distro-%s-%s'%(distrotag,build_old.display,build_new.display,distro,build_new.display)
            print ' * from %s/%s'%(build_old.svnpath,distrotag)
            print ' * to %s/%s'%(build_new.svnpath,distrotag)

            # parse make packages
            packages_new=build_new.get_packages(distrotag)
            pnames_new=set(packages_new.keys())
            if options.verbose: print 'got packages for ',build_new.display
            packages_old=build_old.get_packages(distrotag)
            pnames_old=set(packages_old.keys())
            if options.verbose: print 'got packages for ',build_old.display

            # get created, deprecated, and preserved package names
            pnames_created = list(pnames_new-pnames_old)
            pnames_created.sort()
            pnames_deprecated = list(pnames_old-pnames_new)
            pnames_deprecated.sort()
            pnames = list(pnames_new.intersection(pnames_old))
            pnames.sort()

            if options.verbose: print "Found new/deprecated/preserved pnames",pnames_new,pnames_deprecated,pnames

            # display created and deprecated 
            for name in pnames_created:
                print '=== %s : new package %s -- appeared in %s === #package-%s-%s-%s'%(
                    distrotag,name,build_new.display,name,distro,build_new.display)
                pobj=packages_new[name]
                print ' * %s'%pobj.details()
            for name in pnames_deprecated:
                print '=== %s : package %s -- deprecated, last occurrence in %s === #package-%s-%s-%s'%(
                    distrotag,name,build_old.display,name,distro,build_new.display)
                pobj=packages_old[name]
                if not pobj.svnpath:
                    print ' * codebase stored in CVS, specfile is %s'%pobj.spec
                else:
                    print ' * %s'%pobj.details()

            # display other packages
            for name in pnames:
                (pobj_new,pobj_old)=(packages_new[name],packages_old[name])
                if options.verbose: print "Dealing with package",name
                if pobj_old.specpath == pobj_new.specpath:
                    continue
                specdiff = diffcache.fetch(pobj_old.specpath,pobj_new.specpath)
                if specdiff is None:
                    command="svn diff %s %s"%(pobj_old.specpath,pobj_new.specpath)
                    specdiff=Command(command,options).output_of()
                    diffcache.store(pobj_old.specpath,pobj_new.specpath,specdiff)
                else:
                    if options.verbose: print 'got diff from cache'
                if not specdiff:
                    continue
                print '=== %s - %s to %s : package %s === #package-%s-%s-%s'%(
                    distrotag,build_old.display,build_new.display,name,name,distro,build_new.display)
                print ' * from %s to %s'%(pobj_old.details(),pobj_new.details())
                trac_diff_url=pobj_old.trac_full_diff(pobj_new)
                if trac_diff_url:
                    print ' * [%s View full diff]'%trac_diff_url
                print '{{{'
                for line in specdiff.split('\n'):
                    if not line:
                        continue
                    if Release.discard_matcher.match(line):
                        continue
                    if line[0] in ['@']:
                        print '----------'
                    elif line[0] in ['+','-']:
                        print_fold(line)
                print '}}}'

##############################
class Main:

    module_usage="""Usage: %prog [options] module_desc [ .. module_desc ]
Revision: $Revision$

module-tools : a set of tools to manage subversion tags and specfile
  requires the specfile to either
  * define *version* and *taglevel*
  OR alternatively 
  * define redirection variables module_version_varname / module_taglevel_varname
Trunk:
  by default, the trunk of modules is taken into account
  in this case, just mention the module name as <module_desc>
Branches:
  if you wish to work on a branch rather than on the trunk, 
  you can use something like e.g. Mom:2.1 as <module_desc>
"""
    release_usage="""Usage: %prog [options] tag1 .. tagn
  Extract release notes from the changes in specfiles between several build tags, latest first
  Examples:
      release-changelog 4.2-rc25 4.2-rc24 4.2-rc23 4.2-rc22
  You can refer to a (build) branch by prepending a colon, like in
      release-changelog :4.2 4.2-rc25
"""
    common_usage="""More help:
  see http://svn.planet-lab.org/wiki/ModuleTools"""

    modes={ 
        'list' : "displays a list of available tags or branches",
        'version' : "check latest specfile and print out details",
        'diff' : "show difference between module (trunk or branch) and latest tag",
        'tag'  : """increment taglevel in specfile, insert changelog in specfile,
                create new tag and and monitor its adoption in build/*-tags*.mk""",
        'branch' : """create a branch for this module, from the latest tag on the trunk, 
                  and change trunk's version number to reflect the new branch name;
                  you can specify the new branch name by using module:branch""",
        'sync' : """create a tag from the module
                this is a last resort option, mostly for repairs""",
        'changelog' : """extract changelog between build tags
                expected arguments are a list of tags""",
        }

    silent_modes = ['list']
    release_modes = ['changelog']

    @staticmethod
    def optparse_list (option, opt, value, parser):
        try:
            setattr(parser.values,option.dest,getattr(parser.values,option.dest)+value.split())
        except:
            setattr(parser.values,option.dest,value.split())

    def run(self):

        mode=None
        for function in Main.modes.keys():
            if sys.argv[0].find(function) >= 0:
                mode = function
                break
        if not mode:
            print "Unsupported command",sys.argv[0]
            print "Supported commands:" + Modes.modes.keys.join(" ")
            sys.exit(1)

        if mode not in Main.release_modes:
            usage = Main.module_usage
            usage += Main.common_usage
            usage += "\nmodule-%s : %s"%(mode,Main.modes[mode])
        else:
            usage = Main.release_usage
            usage += Main.common_usage

        parser=OptionParser(usage=usage,version=subversion_id)
        
        if mode == 'list':
            parser.add_option("-b","--branches",action="store_true",dest="list_branches",default=False,
                              help="list branches")
            parser.add_option("-t","--tags",action="store_false",dest="list_branches",
                              help="list tags")
            parser.add_option("-m","--match",action="store",dest="list_pattern",default=None,
                               help="grep pattern for filtering output")
            parser.add_option("-x","--exact-match",action="store",dest="list_exact",default=None,
                               help="exact grep pattern for filtering output")
        if mode == "tag" or mode == 'branch':
            parser.add_option("-s","--set-version",action="store",dest="new_version",default=None,
                              help="set new version and reset taglevel to 0")
        if mode == "tag" :
            parser.add_option("-c","--no-changelog", action="store_false", dest="changelog", default=True,
                              help="do not update changelog section in specfile when tagging")
            parser.add_option("-b","--build-branch", action="store", dest="build_branch", default=None,
                              help="specify a build branch; used for locating the *tags*.mk files where adoption is to take place")
        if mode == "tag" or mode == "sync" :
            parser.add_option("-e","--editor", action="store", dest="editor", default=default_editor(),
                              help="specify editor")
        if mode == "sync" :
            parser.add_option("-m","--message", action="store", dest="message", default=None,
                              help="specify log message")
        if mode in ["diff","version"] :
            parser.add_option("-W","--www", action="store", dest="www", default=False,
                              help="export diff in html format, e.g. -W trunk")
        if mode == "diff" :
            parser.add_option("-l","--list", action="store_true", dest="list", default=False,
                              help="just list modules that exhibit differences")

        if mode  == 'version':
            parser.add_option("-u","--url", action="store_true", dest="show_urls", default=False,
                              help="display URLs")
            
        default_modules_list=os.path.dirname(sys.argv[0])+"/modules.list"
        if mode not in Main.release_modes:
            parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                              help="run on all modules as found in %s"%default_modules_list)
            parser.add_option("-f","--file",action="store",dest="modules_list",default=None,
                              help="run on all modules found in specified file")
        else:
            parser.add_option("-n","--dry-run",action="store_true",dest="dry_run",default=False,
                              help="dry run - shell commands are only displayed")
            parser.add_option("-t","--distrotags",action="callback",callback=Main.optparse_list, dest="distrotags",
                              default=[], nargs=1,type="string",
                              help="""specify distro-tags files, e.g. onelab-tags-4.2.mk
-- can be set multiple times, or use quotes""")

        parser.add_option("-w","--workdir", action="store", dest="workdir", 
                          default="%s/%s"%(os.getenv("HOME"),"modules"),
                          help="""name for dedicated working dir - defaults to ~/modules
** THIS MUST NOT ** be your usual working directory""")
        parser.add_option("-F","--fast-checks",action="store_true",dest="fast_checks",default=False,
                          help="skip safety checks, such as svn updates -- use with care")

        # default verbosity depending on function - temp
        verbose_modes= ['tag', 'sync', 'branch']
        
        if mode not in verbose_modes:
            parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=False, 
                              help="run in verbose mode")
        else:
            parser.add_option("-q","--quiet", action="store_false", dest="verbose", default=True,
                              help="run in quiet (non-verbose) mode")
#        parser.add_option("-d","--debug", action="store_true", dest="debug", default=False, 
#                          help="debug mode - mostly more verbose")
        (options, args) = parser.parse_args()
        options.mode=mode
        if not hasattr(options,'dry_run'):
            options.dry_run=False
        if not hasattr(options,'www'):
            options.www=False
        options.debug=False

        ########## release-*
        if mode in Main.release_modes :
            ########## changelog
            if len(args) <= 1:
                parser.print_help()
                sys.exit(1)
            Module.init_homedir(options)
            for n in range(len(args)-1):
                [t_new,t_old]=args[n:n+2]
                Release.do_changelog (t_new,t_old,options)
        else:
            ########## module-*
            if len(args) == 0:
                if options.all_modules:
                    options.modules_list=default_modules_list
                if options.modules_list:
                    args=Command("grep -v '#' %s"%options.modules_list,options).output_of().split()
                else:
                    parser.print_help()
                    sys.exit(1)
            Module.init_homedir(options)

            # 2 passes for www output
            modules=[ Module(modname,options) for modname in args ]
            # hack: create a dummy Module to store errors/warnings
            error_module = Module('__errors__',options)

            # pass 1 : do it, except if options.www
            for module in modules:
                if len(args)>1 and mode not in Main.silent_modes and not options.www:
                    print '========================================',module.friendly_name()
                # call the method called do_<mode>
                method=Module.__dict__["do_%s"%mode]
                try:
                    method(module)
                except Exception,e:
                    if options.www:
                        title='<span class="error"> Skipping module %s - failure: %s </span>'%\
                            (module.friendly_name(), str(e))
                        error_module.html_store_title(title)
                    else:
                        print 'Skipping module %s: '%modname,e

            # in which case we do the actual printing in the second pass
            if options.www:
                if mode == "diff":
                    modetitle="Changes to tag in %s"%options.www
                elif mode == "version":
                    modetitle="Latest tags in %s"%options.www
                modules.append(error_module)
                error_module.html_dump_header(modetitle)
                for module in modules:
                    module.html_dump_toc()
                Module.html_dump_middle()
                for module in modules:
                    module.html_dump_body()
                Module.html_dump_footer()

####################
if __name__ == "__main__" :
    try:
        Main().run()
    except KeyboardInterrupt:
        print '\nBye'
