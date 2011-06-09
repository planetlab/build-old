#!/usr/bin/env python3.2
#
# perform comparison of tags contents between planet-lab and onelab tags
#

import sys
import re
from argparse import ArgumentParser
import subprocess

class TagsFile:
    
    def __init__ (self, filename):
        self.filename=filename

    m_comment =         re.compile('^\s*#')
    m_empty =           re.compile('^\s*$')
    m_gitpath =         re.compile(\
        '^\s*(?P<module>[\w\.\-]+)-GITPATH\s*'+
        ':=\s*git://(?P<host>[\w\.\-]+)/'+
        '(?P<repo>[\w\.\-]+)(?P<tag>[@\w/:_\.\-]+)?\s*$')
    m_svnpath =         re.compile(\
        '^\s*(?P<module>[\w\-]+)-SVNPATH\s*'+
        ':=\s*http://(?P<host>[\w\.\-]+)/'+
        '(?P<svnpath>[\w/:_\.\-]+)\s*$')
    m_branch =          re.compile(\
        '^\s*(?P<module>[\w\.\-]+)-BRANCH\s*:=\s*(?P<branch>[\w]+)\s*$')

    def _parse (self,o):
        self.git={}
        self.svn={}
        self.branch={}
        with open(self.filename) as i:
            for line in i.readlines():
                line=line.strip()
                match=TagsFile.m_empty.match(line)
                if match: continue
                match=TagsFile.m_comment.match(line)
                if match: continue
                match=TagsFile.m_gitpath.match(line)
                if match:
                    (module,host,repo,tag)=match.groups()
                    if tag: tag=tag.replace('@','')
                    if module in self.git: print ('Warning: duplicate GITPATH for',module,file=o)
                    self.git[module]=tag
                    continue
                match=TagsFile.m_svnpath.match(line)
                if match:
                    (module,host,svnpath)=match.groups()
                    tag=svnpath.split('/')[-1]
                    if module in self.svn: print ('Warning: duplicate SVNPATH for',module,file=o)
                    self.svn[module]=tag
                    continue
                match=TagsFile.m_branch.match(line)
                if match:
                    (module,branch)=match.groups()
                    if module in self.branch: print ('Warning: duplicate BRANCH for',module,file=o)
                    self.branch[module]=branch
                    continue
                print ("%-020s"%"ignored",line,file=o)
        # outputs relevant info
        for n in ['branch','git','svn']:
            d=getattr(self,n)
            keys=list(d.keys())
            keys.sort()
            for key in keys: print ("%-020s %-20s %s"%(n,key,d[key]),file=o)

    def norm(self): return self.filename+'.norm'
                
    def parse(self):
        with open(self.norm(),'w') as f:
            self._parse(f)
        print ("(Over)wrote",self.norm())

# basic usage for now 
# $0 tagsfile1 tagsfile2
def main ():
    parser=ArgumentParser(description="Compare 2 tags files",
                          epilog="Create a normalized (.norm) file for each input and runs diff on them")
    parser.add_argument('tagsnames',
                        metavar='tagsfile',
                        nargs='+',
                        help="tags file names")
    parser.add_argument("-d","--diff",action="store_true",dest="run_diff",default=False,
                        help="runs diff on the normalized outputs - requires exactly 2 args")

    apres=parser.parse_args()
    for tagsname in apres.tagsnames: 
        TagsFile(tagsname).parse()
    if apres.run_diff and len(apres.tagsnames)==2:
        tf1=TagsFile(apres.tagsnames[0])
        tf2=TagsFile(apres.tagsnames[1])
        print ("%s <-- --> %s"%(tf1.norm(),tf2.norm()))
        command = "diff %s %s"%(tf1.norm(),tf2.norm())
        subprocess.Popen(command,shell=True)

if __name__ == '__main__': 
    main()
