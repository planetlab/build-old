#!/usr/bin/env python
# read a full log and tries to extract the interesting stuff

import sys,re
m_show_line=re.compile(".* BEG (RPM|VSERVER).*|.*'boot'.*|\* .*")
m_installing_any=re.compile('\r  (Installing:[^\]]*]) ')
m_installing_err=re.compile('\r  (Installing:[^\]]*])(..+)')
m_installing_end=re.compile('Installed:.*')
m_installing_doc=re.compile(".*such file or directory for /usr/share/info.*")

def scan_log (filename):

    try:
        if filename=="-":
            filename="stdin"
            f=sys.stdin
        else:
            f=open(filename)
        echo=False
        for line in f.xreadlines():
            if m_show_line.match(line):
                print line,
            elif m_installing_err.match(line):
                (installing,error)=m_installing_err.match(line).groups()
                print installing
                print error
                echo=True
            elif m_installing_end.match(line):
                echo=False
            elif m_installing_any.match(line):
                if echo: 
                    installing=m_installing_any.match(line).group(1)
                    print installing
                echo=False
            else:
                if echo: print line,
        f.close()
    except:
        print 'Failed to analyze',filename

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        scan_log(arg)
