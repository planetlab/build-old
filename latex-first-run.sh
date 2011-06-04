#!/bin/bash
echo "Running latex and pdflatex on a dummy input"
cd /tmp
cat > latex-dummy.tex <<EOF
\\documentclass{article}
\\begin{document}
a dummy text to make sure latex is properly configured, as we're seeing weird error messages like
I can't find the format file pdflatex.fmt!
\\end{document}
EOF
latex latex-dummy < /dev/null >& /dev/null
pdflatex latex-dummy < /dev/null >& /dev/null
exit 0
