#!/usr/bin/python -u

import sys, os
import re
import time
from glob import glob
from optparse import OptionParser

# HARDCODED NAME CHANGES
#
# Moving to git we decided to rename some of the repositories. Here is
# a map of name changes applied in git repositories.
RENAMED_SVN_MODULES = {
    "PLEWWW": "plewww"
    }

def svn_to_git_name(module):
    if RENAMED_SVN_MODULES.has_key(module):
        return RENAMED_SVN_MODULES[module]
    return module

def git_to_svn_name(module):
    for key in RENAMED_SVN_MODULES:
        if module == RENAMED_SVN_MODULES[key]:
            return key
    return module
    

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


class SvnRepository:
    type = "svn"

    def __init__(self, path, options):
        self.path = path
        self.options = options

    def name(self):
        return os.path.basename(self.path)

    def url(self):
        out = Command("svn info %s" % self.path, self.options).output_of()
        for line in out.split('\n'):
            if line.startswith("URL:"):
                return line.split()[1].strip()

    def repo_root(self):
        out = Command("svn info %s" % self.path, self.options).output_of()
        for line in out.split('\n'):
            if line.startswith("Repository Root:"):
                root = line.split()[2].strip()
                return "%s/%s" % (root, self.name())

    @classmethod
    def checkout(cls, remote, local, options, recursive=False):
        if recursive:
            svncommand = "svn co %s %s" % (remote, local)
        else:
            svncommand = "svn co -N %s %s" % (remote, local)
        Command("rm -rf %s" % local, options).run_silent()
        Command(svncommand, options).run_fatal()

        return SvnRepository(local, options)

    @classmethod
    def remote_exists(cls, remote):
        return os.system("svn list %s &> /dev/null" % remote) == 0

    def tag_exists(self, tagname):
        url = "%s/tags/%s" % (self.repo_root(), tagname)
        return SvnRepository.remote_exists(url)

    def update(self, subdir="", recursive=True):
        path = os.path.join(self.path, subdir)
        if recursive:
            svncommand = "svn up %s" % path
        else:
            svncommand = "svn up -N %s" % path
        Command(svncommand, self.options).run_fatal()

    def commit(self, logfile):
        # add all new files to the repository
        Command("svn status %s | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\\ /g' | xargs svn add" %
                self.path, self.options).run_silent()
        Command("svn commit -F %s %s" % (logfile, self.path), self.options).run_fatal()

    def to_branch(self, branch):
        remote = "%s/branches/%s" % (self.repo_root(), branch)
        SvnRepository.checkout(remote, self.path, self.options, recursive=True)

    def to_tag(self, tag):
        remote = "%s/tags/%s" % (self.repo_root(), branch)
        SvnRepository.checkout(remote, self.path, self.options, recursive=True)

    def tag(self, tagname, logfile):
        tag_url = "%s/tags/%s" % (self.repo_root(), tagname)
        self_url = self.url()
        Command("svn copy -F %s %s %s" % (logfile, self_url, tag_url), self.options).run_fatal()

    def diff(self, f=""):
        if f:
            f = os.path.join(self.path, f)
        else:
            f = self.path
        return Command("svn diff %s" % f, self.options).output_of(True)

    def diff_with_tag(self, tagname):
        tag_url = "%s/tags/%s" % (self.repo_root(), tagname)
        return Command("svn diff %s %s" % (tag_url, self.url()),
                       self.options).output_of(True)

    def revert(self, f=""):
        if f:
            Command("svn revert %s" % os.path.join(self.path, f), self.options).run_fatal()
        else:
            # revert all
            Command("svn revert %s -R" % self.path, self.options).run_fatal()
            Command("svn status %s | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\\ /g' | xargs rm -rf " %
                    self.path, self.options).run_silent()

    def is_clean(self):
        command="svn status %s" % self.path
        return len(Command(command,self.options).output_of(True)) == 0

    def is_valid(self):
        return os.path.exists(os.path.join(self.path, ".svn"))
    

class GitRepository:
    type = "git"

    def __init__(self, path, options):
        self.path = path
        self.options = options

    def name(self):
        return os.path.basename(self.path)

    def url(self):
        self.repo_root()

    def repo_root(self):
        c = Command("git remote show origin", self.options)
        out = self.__run_in_repo(c.output_of)
        for line in out.split('\n'):
            if line.strip().startswith("Fetch URL:"):
                repo = line.split()[2]

    @classmethod
    def checkout(cls, remote, local, options, depth=1):
        Command("rm -rf %s" % local, options).run_silent()
        Command("git clone --depth %d %s %s" % (depth, remote, local), options).run_fatal()
        return GitRepository(local, options)

    @classmethod
    def remote_exists(cls, remote):
        return os.system("git --no-pager ls-remote %s &> /dev/null" % remote) == 0

    def tag_exists(self, tagname):
        command = 'git tag -l | grep "^%s$"' % tagname
        c = Command(command, self.options)
        out = self.__run_in_repo(c.output_of, with_stderr=True)
        return len(out) > 0

    def __run_in_repo(self, fun, *args, **kwargs):
        cwd = os.getcwd()
        os.chdir(self.path)
        ret = fun(*args, **kwargs)
        os.chdir(cwd)
        return ret

    def __run_command_in_repo(self, command, ignore_errors=False):
        c = Command(command, self.options)
        if ignore_errors:
            return self.__run_in_repo(c.output_of)
        else:
            return self.__run_in_repo(c.run_fatal)

    def update(self, subdir=None, recursive=None):
        self.__run_command_in_repo("git pull")
        self.__run_command_in_repo("git pull --tags")

    def to_branch(self, branch, remote=True):
        if remote:
            branch = "origin/%s" % branch
        return self.__run_command_in_repo("git checkout %s" % branch)

    def to_tag(self, tag):
        return self.__run_command_in_repo("git checkout %s" % tag)

    def tag(self, tagname, logfile):
        self.__run_command_in_repo("git tag %s -F %s" % (tagname, logfile))
        self.commit(logfile)

    def diff(self, f=""):
        c = Command("git diff %s" % f, self.options)
        return self.__run_in_repo(c.output_of, with_stderr=True)

    def diff_with_tag(self, tagname):
        c = Command("git diff %s" % tagname, self.options)
        return self.__run_in_repo(c.output_of, with_stderr=True)

    def commit(self, logfile):
        self.__run_command_in_repo("git add -A", ignore_errors=True)
        self.__run_command_in_repo("git commit -F  %s" % logfile, ignore_errors=True)
        self.__run_command_in_repo("git push")
        self.__run_command_in_repo("git push --tags")

    def revert(self, f=""):
        if f:
            self.__run_command_in_repo("git checkout %s" % f)
        else:
            # revert all
            self.__run_command_in_repo("git --no-pager reset --hard")
            self.__run_command_in_repo("git --no-pager clean -f")

    def is_clean(self):
        def check_commit():
            command="git status"
            s="nothing to commit (working directory clean)"
            return Command(command, self.options).output_of(True).find(s) >= 0
        return self.__run_in_repo(check_commit)

    def is_valid(self):
        return os.path.exists(os.path.join(self.path, ".git"))
    

class Repository:
    """ Generic repository """
    supported_repo_types = [SvnRepository, GitRepository]

    def __init__(self, path, options):
        self.path = path
        self.options = options
        for repo in self.supported_repo_types:
            self.repo = repo(self.path, self.options)
            if self.repo.is_valid():
                break

    @classmethod
    def has_moved_to_git(cls, module, svnpath):
        module = git_to_svn_name(module)
        return SvnRepository.remote_exists("%s/%s/aaaa-has-moved-to-git" % (svnpath, module))

    @classmethod
    def remote_exists(cls, remote):
        for repo in Repository.supported_repo_types:
            if repo.remote_exists(remote):
                return True
        return False

    def __getattr__(self, attr):
        return getattr(self.repo, attr)



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
                 ('gitserver', "Enter your git server's hostname", "git.onelab.eu"),
                 ('gituser', "Enter your user name (login name) on git server", os.getlogin()),
                 ("build", "Enter the name of your build module","build"),
                 ('username',"Enter your firstname and lastname for changelogs",""),
                 ("email","Enter your email address for changelogs",""),
                 ]

    @classmethod
    def prompt_config_option(cls, key, message, default):
        cls.config[key]=raw_input("%s [%s] : "%(message,default)).strip() or default

    @classmethod
    def prompt_config (cls):
        for (key,message,default) in cls.configKeys:
            cls.config[key]=""
            while not cls.config[key]:
                cls.prompt_config_option(key, message, default)


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

        # when available prefer to use git module name internally
        self.name = svn_to_git_name(self.name)

        self.options=options
        self.module_dir="%s/%s"%(options.workdir,self.name)
        self.repository = None
        self.build = None

    def run (self,command):
        return Command(command,self.options).run()
    def run_fatal (self,command):
        return Command(command,self.options).run_fatal()
    def run_prompt (self,message,fun, *args):
        fun_msg = "%s(%s)" % (fun.func_name, ",".join(args))
        if not self.options.verbose:
            while True:
                choice=prompt(message,True,('s','how'))
                if choice is True:
                    fun(*args)
                    return
                elif choice is False:
                    print 'About to run function:', fun_msg
        else:
            question=message+" - want to run function: " + fun_msg
            if prompt(question,True):
                fun(*args)

    def friendly_name (self):
        if hasattr(self,'branch'):
            return "%s:%s"%(self.name,self.branch)
        elif hasattr(self,'tagname'):
            return "%s@%s"%(self.name,self.tagname)
        else:
            return self.name

    @classmethod
    def git_remote_dir (cls, name):
        return "%s@%s:/git/%s.git" % (cls.config['gituser'], cls.config['gitserver'], name)

    @classmethod
    def svn_remote_dir (cls, name):
        name = git_to_svn_name(name)
        svn = cls.config['svnpath']
        if svn.endswith('/'):
            return "%s%s" % (svn, name)
        return "%s/%s" % (svn, name)

    def svn_selected_remote(self):
        svn_name = git_to_svn_name(self.name)
        remote = self.svn_remote_dir(svn_name)
        if hasattr(self,'branch'):
            remote = "%s/branches/%s" % (remote, self.branch)
        elif hasattr(self,'tagname'):
            remote = "%s/tags/%s" % (remote, self.tagname)
        else:
            remote = "%s/trunk" % remote
        return remote

    ####################
    @classmethod
    def init_homedir (cls, options):
        if options.verbose and options.mode not in Main.silent_modes:
            print 'Checking for', options.workdir
        storage="%s/%s"%(options.workdir, cls.config_storage)
        # sanity check. Either the topdir exists AND we have a config/storage
        # or topdir does not exist and we create it
        # to avoid people use their own daily svn repo
        if os.path.isdir(options.workdir) and not os.path.isfile(storage):
            print """The directory %s exists and has no CONFIG file
If this is your regular working directory, please provide another one as the
module-* commands need a fresh working dir. Make sure that you do not use 
that for other purposes than tagging""" % options.workdir
            sys.exit(1)

        def checkout_build():
            print "Checking out build module..."
            remote = cls.git_remote_dir(cls.config['build'])
            local = os.path.join(options.workdir, cls.config['build'])
            GitRepository.checkout(remote, local, options, depth=1)
            print "OK"

        def store_config():
            f=file(storage,"w")
            for (key,message,default) in Module.configKeys:
                f.write("%s=%s\n"%(key,Module.config[key]))
            f.close()
            if options.debug:
                print 'Stored',storage
                Command("cat %s"%storage,options).run()

        def read_config():
            # read config
            f=open(storage)
            for line in f.readlines():
                (key,value)=re.compile("^(.+)=(.+)$").match(line).groups()
                Module.config[key]=value                
            f.close()

        if not os.path.isdir (options.workdir):
            print "Cannot find",options.workdir,"let's create it"
            Command("mkdir -p %s" % options.workdir, options).run_silent()
            cls.prompt_config()
            checkout_build()
            store_config()
        else:
            read_config()
            # check missing config options
            old_layout = False
            for (key,message,default) in cls.configKeys:
                if not Module.config.has_key(key):
                    print "Configuration changed for module-tools"
                    cls.prompt_config_option(key, message, default)
                    old_layout = True
                    
            if old_layout:
                Command("rm -rf %s" % options.workdir, options).run_silent()
                Command("mkdir -p %s" % options.workdir, options).run_silent()
                checkout_build()
                store_config()

            build_dir = os.path.join(options.workdir, cls.config['build'])
            if not os.path.isdir(build_dir):
                checkout_build()
            else:
                build = Repository(build_dir, options)
                if not build.is_clean():
                    print "build module needs a revert"
                    build.revert()
                    print "OK"
                build.update()

        if options.verbose and options.mode not in Main.silent_modes:
            print '******** Using config'
            for (key,message,default) in Module.configKeys:
                print '\t',key,'=',Module.config[key]

    def init_module_dir (self):
        if self.options.verbose:
            print 'Checking for',self.module_dir

        if not os.path.isdir (self.module_dir):
            if Repository.has_moved_to_git(self.name, Module.config['svnpath']):
                self.repository = GitRepository.checkout(self.git_remote_dir(self.name),
                                                         self.module_dir,
                                                         self.options)
            else:
                remote = self.svn_selected_remote()
                self.repository = SvnRepository.checkout(remote,
                                                         self.module_dir,
                                                         self.options, recursive=False)

        self.repository = Repository(self.module_dir, self.options)
        if self.repository.type == "svn":
            # check if module has moved to git    
            if Repository.has_moved_to_git(self.name, Module.config['svnpath']):
                Command("rm -rf %s" % self.module_dir, self.options).run_silent()
                self.init_module_dir()
            # check if we have the required branch/tag
            if self.repository.url() != self.svn_selected_remote():
                Command("rm -rf %s" % self.module_dir, self.options).run_silent()
                self.init_module_dir()

        elif self.repository.type == "git":
            if hasattr(self,'branch'):
                self.repository.to_branch(self.branch)
            elif hasattr(self,'tagname'):
                self.repository.to_tag(self.tagname)

        else:
            raise Exception, 'Cannot find %s - check module name'%self.module_dir


    def revert_module_dir (self):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping revert of %s' % self.module_dir
            return
        if self.options.verbose:
            print 'Checking whether', self.module_dir, 'needs being reverted'
        
        if not self.repository.is_clean():
            self.repository.revert()

    def update_module_dir (self):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping update of %s' % self.module_dir
            return
        if self.options.verbose:
            print 'Updating', self.module_dir
        self.repository.update()

    def main_specname (self):
        attempt="%s/%s.spec"%(self.module_dir,self.name)
        if os.path.isfile (attempt):
            return attempt
        pattern1="%s/*.spec"%self.module_dir
        level1=glob(pattern1)
        if level1:
            return level1[0]
        pattern2="%s/*/*.spec"%self.module_dir
        level2=glob(pattern2)

        if level2:
            return level2[0]
        raise Exception, 'Cannot guess specfile for module %s -- patterns were %s or %s'%(self.name,pattern1,pattern2)

    def all_specnames (self):
        level1=glob("%s/*.spec" % self.module_dir)
        if level1: return level1
        level2=glob("%s/*/*.spec" % self.module_dir)
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

    def last_tag (self, spec_dict):
        try:
            return "%s-%s" % (spec_dict[self.module_version_varname],
                              spec_dict[self.module_taglevel_varname])
        except KeyError,err:
            raise Exception,'Something is wrong with module %s, cannot determine %s - exiting'%(self.name,err)

    def tag_name (self, spec_dict, old_svn_name=False):
        base_tag_name = self.name
        if old_svn_name:
            base_tag_name = git_to_svn_name(self.name)
        return "%s-%s" % (base_tag_name, self.last_tag(spec_dict))
    

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

    def check_tag(self, tagname, need_it=False, old_svn_tag_name=None):
        if self.options.verbose:
            print "Checking %s repository tag: %s - " % (self.repository.type, tagname),

        found_tagname = tagname
        found = self.repository.tag_exists(tagname)
        if not found and old_svn_tag_name:
            if self.options.verbose:
                print "KO"
                print "Checking %s repository tag: %s - " % (self.repository.type, old_svn_tag_name),
            found = self.repository.tag_exists(old_svn_tag_name)
            if found:
                found_tagname = old_svn_tag_name

        if (found and need_it) or (not found and not need_it):
            if self.options.verbose:
                print "OK",
                if found: print "- found"
                else: print "- not found"
        else:
            if self.options.verbose:
                print "KO"
            if found:
                raise Exception, "tag (%s) is already there" % tagname
            else:
                raise Exception, "can not find required tag (%s)" % tagname

        return found_tagname


##############################
    def do_tag (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        # parse specfile
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # side effects
        old_tag_name = self.tag_name(spec_dict)
        old_svn_tag_name = self.tag_name(spec_dict, old_svn_name=True)

        if (self.options.new_version):
            # new version set on command line
            spec_dict[self.module_version_varname] = self.options.new_version
            spec_dict[self.module_taglevel_varname] = 0
        else:
            # increment taglevel
            new_taglevel = str ( int (spec_dict[self.module_taglevel_varname]) + 1)
            spec_dict[self.module_taglevel_varname] = new_taglevel

        new_tag_name = self.tag_name(spec_dict)

        # sanity check
        old_tag_name = self.check_tag(old_tag_name, need_it=True, old_svn_tag_name=old_svn_tag_name)
        new_tag_name = self.check_tag(new_tag_name, need_it=False)

        # checking for diffs
        diff_output = self.repository.diff_with_tag(old_tag_name)
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
        build_path = os.path.join(self.options.workdir,
                                  Module.config['build'])
        build = Repository(build_path, self.options)
        if self.options.build_branch:
            build.to_branch(self.options.build_branch)
        if not build.is_clean():
            build.revert()

        tagsfiles=glob(build.path+"/*-tags*.mk")
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
                        print build.diff(f=tagsfile)
                    elif choice == 'r':
                        build.revert(f=tagsfile)
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

        def diff_all_changes():
            print build.diff()
            print self.repository.diff()

        def commit_all_changes(log):
            self.repository.commit(log)
            build.commit(log)

        self.run_prompt("Review module and build", diff_all_changes)
        self.run_prompt("Commit module and build", commit_all_changes, changelog_svn)
        self.run_prompt("Create tag", self.repository.tag, new_tag_name, changelog_svn)

        if self.options.debug:
            print 'Preserving',changelog,'and stripped',changelog_svn
        else:
            os.unlink(changelog)
            os.unlink(changelog_svn)


##############################
    def do_version (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        spec_dict = self.spec_dict()
        if self.options.www:
            self.html_store_title('Version for module %s (%s)' % (self.friendly_name(),
                                                                  self.last_tag(spec_dict)))
        for varname in self.varnames:
            if not spec_dict.has_key(varname):
                self.html_print ('Could not find %%define for %s'%varname)
                return
            else:
                self.html_print ("%-16s %s"%(varname,spec_dict[varname]))
        if self.options.verbose:
            self.html_print ("%-16s %s"%('main specfile:',self.main_specname()))
            self.html_print ("%-16s %s"%('specfiles:',self.all_specnames()))
        self.html_print_end()


##############################
    def do_diff (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)

        # side effects
        tag_name = self.tag_name(spec_dict)
        old_svn_tag_name = self.tag_name(spec_dict, old_svn_name=True)

        # sanity check
        tag_name = self.check_tag(tag_name, need_it=True, old_svn_tag_name=old_svn_tag_name)

        if self.options.verbose:
            print 'Getting diff'
        diff_output = self.repository.diff_with_tag(tag_name)

        if self.options.list:
            if diff_output:
                print self.name
        else:
            thename=self.friendly_name()
            do_print=False
            if self.options.www and diff_output:
                self.html_store_title("Diffs in module %s (%s) : %d chars"%(\
                        thename,self.last_tag(spec_dict),len(diff_output)))

                self.html_store_raw ('<p> &lt; (left) %s </p>' % tag_name)
                self.html_store_raw ('<p> &gt; (right) %s </p>' % thename)
                self.html_store_pre (diff_output)
            elif not self.options.www:
                print 'x'*30,'module',thename
                print 'x'*20,'<',tag_name
                print 'x'*20,'>',thename
                print diff_output

##############################
    # store and restitute html fragments
    @staticmethod 
    def html_href (url,text): return '<a href="%s">%s</a>'%(url,text)

    @staticmethod 
    def html_anchor (url,text): return '<a name="%s">%s</a>'%(url,text)

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
        nowtime=time.strftime("%H:%M (%Z)")
        print """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
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


##############################
class Main:

    module_usage="""Usage: %prog [options] module_desc [ .. module_desc ]

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
  You can refer to the build trunk by just mentioning 'trunk', e.g.
      release-changelog -t coblitz-tags.mk coblitz-2.01-rc6 trunk
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
            print "Supported commands:" + " ".join(Main.modes.keys())
            sys.exit(1)

        if mode not in Main.release_modes:
            usage = Main.module_usage
            usage += Main.common_usage
            usage += "\nmodule-%s : %s"%(mode,Main.modes[mode])
        else:
            usage = Main.release_usage
            usage += Main.common_usage

        parser=OptionParser(usage=usage)
        
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

        if mode in ["diff","version"] :
            parser.add_option("-W","--www", action="store", dest="www", default=False,
                              help="export diff in html format, e.g. -W trunk")

        if mode == "diff" :
            parser.add_option("-l","--list", action="store_true", dest="list", default=False,
                              help="just list modules that exhibit differences")
            
        default_modules_list=os.path.dirname(sys.argv[0])+"/modules.list"
        parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                          help="run on all modules as found in %s"%default_modules_list)
        parser.add_option("-f","--file",action="store",dest="modules_list",default=None,
                          help="run on all modules found in specified file")
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
        (options, args) = parser.parse_args()
        options.mode=mode
        if not hasattr(options,'dry_run'):
            options.dry_run=False
        if not hasattr(options,'www'):
            options.www=False
        options.debug=False

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
        

        modules=[ Module(modname,options) for modname in args ]
        # hack: create a dummy Module to store errors/warnings
        error_module = Module('__errors__',options)

        for module in modules:
            if len(args)>1 and mode not in Main.silent_modes:
                if not options.www:
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
                    import traceback
                    traceback.print_exc()
                    print 'Skipping module %s: '%modname,e

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
